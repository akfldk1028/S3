/**
 * JobCoordinatorDO — job당 1개 Durable Object
 *
 * SQLite-backed FSM + 멱등성 Ring Buffer (size 1000, TTL 24h) + Alarm D1 flush
 *
 * TODO: Auto-Claude 구현
 * - blockConcurrencyWhile → SQLite 초기화 (job_state, job_items, seen_keys 테이블)
 * - FSM transitions:
 *   - create(jobId, userId, preset, totalItems) → 'created'
 *   - markUploaded() → 'uploaded'
 *   - markQueued(conceptsJson, protectJson, ruleId?) → 'queued'
 *   - onItemResult(callback: CallbackPayload) → 멱등성 체크 → 진행률 갱신
 *   - getStatus() → JobCoordinatorState + items
 *   - cancel() → 'canceled'
 * - 상태머신:
 *   created → uploaded (confirmUpload)
 *   uploaded → queued (execute + Queue push)
 *   queued → running (첫 callback 도착)
 *   running → done (done + failed == total)
 *   running → failed (failed > threshold)
 *   any non-terminal → canceled
 * - alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * - 멱등성: RingBuffer(1000, max age 24h) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
import type { Env, JobCoordinatorState, JobItemState, JobStatus, CallbackPayload } from '../_shared/types';

export class JobCoordinatorDO extends DurableObject<Env> {
  /**
   * State Machine: Valid transitions map
   *
   * Terminal states (done, failed, canceled) have no valid transitions
   * Non-terminal states can always transition to 'canceled'
   */
  private static readonly validTransitions: Record<JobStatus, JobStatus[]> = {
    created: ['uploaded', 'canceled'],
    uploaded: ['queued', 'canceled'],
    queued: ['running', 'canceled'],
    running: ['done', 'failed', 'canceled'],
    done: [], // terminal
    failed: [], // terminal
    canceled: [], // terminal
  };

  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // CRITICAL: Use blockConcurrencyWhile for schema initialization to prevent race conditions
    this.ctx.blockConcurrencyWhile(async () => {
      // Job state table - stores FSM state and progress
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          status TEXT NOT NULL CHECK(status IN ('created', 'uploaded', 'queued', 'running', 'done', 'failed', 'canceled')),
          preset TEXT NOT NULL,
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json TEXT NOT NULL DEFAULT '[]',
          rule_id TEXT,
          total_items INTEGER NOT NULL DEFAULT 0,
          done_items INTEGER NOT NULL DEFAULT 0,
          failed_items INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          finished_at INTEGER
        );
      `);

      // Job items table - stores individual item states
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          idx INTEGER PRIMARY KEY,
          status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'done', 'failed')),
          input_key TEXT NOT NULL,
          output_key TEXT NOT NULL,
          preview_key TEXT NOT NULL,
          error TEXT
        );
      `);

      // Idempotency RingBuffer - stores last 1000 callback keys (max age 24h) to prevent duplicate processing
      await this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          timestamp INTEGER NOT NULL
        );
      `);
    });
  }

  /**
   * Transition state with validation
   *
   * @param newStatus Target status to transition to
   * @throws Error if transition is invalid (e.g., terminal state or invalid flow)
   * @returns true if transition was executed, false if already in target state
   */
  private async transitionState(newStatus: JobStatus): Promise<boolean> {
    // Get current state
    const cursor = await this.ctx.storage.sql.exec(
      'SELECT status FROM job_state LIMIT 1'
    );
    const row = cursor.toArray()[0] as { status: JobStatus } | undefined;

    if (!row) {
      throw new Error('Job state not initialized');
    }

    const currentStatus = row.status;

    // Already in target state - idempotent
    if (currentStatus === newStatus) {
      return false;
    }

    // Validate transition
    const allowedTransitions = JobCoordinatorDO.validTransitions[currentStatus];
    if (!allowedTransitions.includes(newStatus)) {
      throw new Error(
        `Invalid state transition: ${currentStatus} → ${newStatus}. ` +
        `Allowed transitions from ${currentStatus}: [${allowedTransitions.join(', ')}]`
      );
    }

    // Check if transitioning to terminal state
    const isTerminalState = newStatus === 'done' || newStatus === 'failed' || newStatus === 'canceled';

    // Execute validated transition
    if (isTerminalState) {
      // Set finished_at timestamp when transitioning to terminal state
      const now = Date.now();
      await this.ctx.storage.sql.exec(
        'UPDATE job_state SET status = ?1, finished_at = ?2',
        newStatus,
        now
      );

      // Schedule alarm to flush to D1 and release credits (1 second delay)
      await this.ctx.storage.setAlarm(Date.now() + 1000);
    } else {
      await this.ctx.storage.sql.exec(
        'UPDATE job_state SET status = ?1',
        newStatus
      );
    }

    return true;
  }

  /**
   * Mark upload complete and set total item count
   *
   * @param totalItems Number of items uploaded
   * @throws Error if not in 'created' state
   */
  async confirmUpload(totalItems: number): Promise<void> {
    // Validate and transition to 'uploaded'
    await this.transitionState('uploaded');

    // Set total_items count
    await this.ctx.storage.sql.exec(
      'UPDATE job_state SET total_items = ?1',
      totalItems
    );
  }

  /**
   * Handle callback from GPU Worker - update item status and progress
   *
   * @param payload Callback payload with item result
   * @returns true if processed, false if duplicate (idempotent)
   */
  async handleCallback(payload: CallbackPayload): Promise<boolean> {
    // Check idempotency - if we've seen this key before, skip processing
    const checkCursor = await this.ctx.storage.sql.exec(
      'SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ?1',
      payload.idempotency_key
    );

    if (checkCursor.toArray().length > 0) {
      // Duplicate callback - already processed
      return false;
    }

    // Record idempotency key with current timestamp
    const now = Date.now();
    await this.ctx.storage.sql.exec(
      'INSERT INTO seen_keys (idempotency_key, timestamp) VALUES (?1, ?2)',
      payload.idempotency_key,
      now
    );

    // Evict old keys from RingBuffer (>1000 entries OR >24 hours)
    const twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);

    // Delete entries older than 24 hours
    await this.ctx.storage.sql.exec(
      'DELETE FROM seen_keys WHERE timestamp < ?1',
      twentyFourHoursAgo
    );

    // Keep only last 1000 entries (by timestamp)
    await this.ctx.storage.sql.exec(`
      DELETE FROM seen_keys
      WHERE idempotency_key NOT IN (
        SELECT idempotency_key FROM seen_keys
        ORDER BY timestamp DESC
        LIMIT 1000
      )
    `);

    // Update item status in job_items table
    await this.ctx.storage.sql.exec(
      `UPDATE job_items
       SET status = ?1,
           output_key = ?2,
           preview_key = ?3,
           error = ?4
       WHERE idx = ?5`,
      payload.status,
      payload.output_key || '',
      payload.preview_key || '',
      payload.error || null,
      payload.idx
    );

    // Increment done_items or failed_items counter
    if (payload.status === 'done') {
      await this.ctx.storage.sql.exec(
        'UPDATE job_state SET done_items = done_items + 1'
      );
    } else if (payload.status === 'failed') {
      await this.ctx.storage.sql.exec(
        'UPDATE job_state SET failed_items = failed_items + 1'
      );
    }

    // Auto-transition to 'running' on first callback if in 'queued' state
    const stateCursor = await this.ctx.storage.sql.exec(
      'SELECT status FROM job_state LIMIT 1'
    );
    const stateRow = stateCursor.toArray()[0] as { status: JobStatus } | undefined;

    if (stateRow?.status === 'queued') {
      await this.transitionState('running');
    }

    // Check if all items are complete
    const progressCursor = await this.ctx.storage.sql.exec(
      'SELECT total_items, done_items, failed_items FROM job_state LIMIT 1'
    );
    const progressRow = progressCursor.toArray()[0] as
      | { total_items: number; done_items: number; failed_items: number }
      | undefined;

    if (progressRow) {
      const { total_items, done_items, failed_items } = progressRow;

      // Auto-transition to 'done' when all items are processed
      if (done_items + failed_items === total_items && total_items > 0) {
        await this.transitionState('done');
      }
    }

    return true;
  }

  /**
   * Alarm handler - flush to D1 and release credits on job completion
   *
   * Triggered when job reaches terminal state (done/failed/canceled)
   *
   * Steps:
   * 1. Read all job state from DO SQLite
   * 2. Read all job items from DO SQLite
   * 3. Batch INSERT to D1 (jobs_log + job_items_log)
   * 4. Call UserLimiterDO.release() to refund unprocessed items
   */
  async alarm(): Promise<void> {
    // Read job state
    const stateCursor = await this.ctx.storage.sql.exec(
      `SELECT job_id, user_id, status, preset, concepts_json, protect_json, rule_id,
              total_items, done_items, failed_items, created_at, finished_at
       FROM job_state LIMIT 1`
    );

    const stateRow = stateCursor.toArray()[0];
    if (!stateRow) {
      throw new Error('Job state not found during alarm flush');
    }

    const jobState = {
      jobId: stateRow[0] as string,
      userId: stateRow[1] as string,
      status: stateRow[2] as JobStatus,
      preset: stateRow[3] as string,
      conceptsJson: stateRow[4] as string,
      protectJson: stateRow[5] as string,
      ruleId: stateRow[6] as string | null,
      totalItems: stateRow[7] as number,
      doneItems: stateRow[8] as number,
      failedItems: stateRow[9] as number,
      createdAt: stateRow[10] as number,
      finishedAt: stateRow[11] as number | null,
    };

    // Read all job items
    const itemsCursor = await this.ctx.storage.sql.exec(
      `SELECT idx, status, input_key, output_key, preview_key, error
       FROM job_items
       ORDER BY idx`
    );

    const items = itemsCursor.toArray().map((row) => ({
      idx: row[0] as number,
      status: row[1] as string,
      inputKey: row[2] as string,
      outputKey: row[3] as string,
      previewKey: row[4] as string,
      error: row[5] as string | null,
    }));

    // Prepare D1 batch statements
    const batchStatements: D1PreparedStatement[] = [];

    // 1. INSERT into jobs_log
    batchStatements.push(
      this.env.DB.prepare(
        `INSERT OR REPLACE INTO jobs_log
         (job_id, user_id, created_at, finished_at, status, preset, rule_id,
          concepts_json, protect_json, params_json, cost_estimate, error)
         VALUES (?, ?, datetime(?, 'unixepoch', 'subsec'), datetime(?, 'unixepoch', 'subsec'),
                 ?, ?, ?, ?, ?, NULL, ?, NULL)`
      ).bind(
        jobState.jobId,
        jobState.userId,
        jobState.createdAt / 1000, // Convert ms to seconds for SQLite datetime
        jobState.finishedAt ? jobState.finishedAt / 1000 : null,
        jobState.status,
        jobState.preset,
        jobState.ruleId,
        jobState.conceptsJson,
        jobState.protectJson,
        jobState.totalItems // cost_estimate = total_items
      )
    );

    // 2. INSERT into job_items_log for each item
    for (const item of items) {
      batchStatements.push(
        this.env.DB.prepare(
          `INSERT OR REPLACE INTO job_items_log
           (job_id, idx, status, input_key, output_key, error)
           VALUES (?, ?, ?, ?, ?, ?)`
        ).bind(
          jobState.jobId,
          item.idx,
          item.status,
          item.inputKey,
          item.outputKey,
          item.error
        )
      );
    }

    // Execute D1 batch
    await this.env.DB.batch(batchStatements);

    // 3. Call UserLimiterDO.release() to refund unprocessed items
    const userLimiterId = this.env.USER_LIMITER.idFromName(jobState.userId);
    const userLimiterStub = this.env.USER_LIMITER.get(userLimiterId);

    await userLimiterStub.fetch('http://internal/release', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        jobId: jobState.jobId,
        doneItems: jobState.doneItems,
        totalItems: jobState.totalItems,
      }),
    });
  }

  /**
   * Create a new job with initial state
   *
   * @param jobId Unique job identifier
   * @param userId User who owns this job
   * @param preset Preset type (interior/seller)
   * @param totalItems Number of items to process
   */
  async create(jobId: string, userId: string, preset: string, totalItems: number): Promise<void> {
    // Check if job already exists (idempotent)
    const existingCursor = await this.ctx.storage.sql.exec(
      'SELECT job_id FROM job_state LIMIT 1'
    );

    if (existingCursor.toArray().length > 0) {
      // Job already created - idempotent
      return;
    }

    const now = Date.now();

    // Initialize job state
    await this.ctx.storage.sql.exec(
      `INSERT INTO job_state
       (job_id, user_id, status, preset, total_items, created_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6)`,
      jobId,
      userId,
      'created',
      preset,
      totalItems,
      now
    );

    // Initialize job items (all pending)
    for (let idx = 0; idx < totalItems; idx++) {
      await this.ctx.storage.sql.exec(
        `INSERT INTO job_items
         (idx, status, input_key, output_key, preview_key)
         VALUES (?1, ?2, ?3, ?4, ?5)`,
        idx,
        'pending',
        `jobs/${jobId}/input/${idx}`,
        `jobs/${jobId}/output/${idx}`,
        `jobs/${jobId}/preview/${idx}`
      );
    }
  }

  /**
   * Mark job as queued and store execution parameters
   *
   * @param conceptsJson JSON string of concepts
   * @param protectJson JSON string of protected elements
   * @param ruleId Optional custom rule ID
   * @throws Error if not in 'uploaded' state
   */
  async markQueued(conceptsJson: string, protectJson: string, ruleId?: string): Promise<void> {
    // Validate and transition to 'queued'
    await this.transitionState('queued');

    // Store execution parameters
    await this.ctx.storage.sql.exec(
      `UPDATE job_state
       SET concepts_json = ?1, protect_json = ?2, rule_id = ?3`,
      conceptsJson,
      protectJson,
      ruleId || null
    );
  }

  /**
   * Get current job state
   *
   * @returns Current job state and all items
   */
  async getState(): Promise<JobCoordinatorState & { items: JobItemState[] }> {
    // Read job state
    const stateCursor = await this.ctx.storage.sql.exec(
      `SELECT job_id, user_id, status, preset, concepts_json, protect_json, rule_id,
              total_items, done_items, failed_items
       FROM job_state LIMIT 1`
    );

    const stateRow = stateCursor.toArray()[0];
    if (!stateRow) {
      throw new Error('Job state not found');
    }

    const state: JobCoordinatorState = {
      jobId: stateRow[0] as string,
      userId: stateRow[1] as string,
      status: stateRow[2] as JobStatus,
      preset: stateRow[3] as string,
      conceptsJson: stateRow[4] as string,
      protectJson: stateRow[5] as string,
      ruleId: stateRow[6] as string | null,
      totalItems: stateRow[7] as number,
      doneItems: stateRow[8] as number,
      failedItems: stateRow[9] as number,
    };

    // Read all job items
    const itemsCursor = await this.ctx.storage.sql.exec(
      `SELECT idx, status, input_key, output_key, preview_key, error
       FROM job_items
       ORDER BY idx`
    );

    const items: JobItemState[] = itemsCursor.toArray().map((row) => ({
      idx: row[0] as number,
      status: row[1] as 'pending' | 'done' | 'failed',
      inputKey: row[2] as string,
      outputKey: row[3] as string,
      previewKey: row[4] as string,
      error: row[5] as string | undefined,
    }));

    return { ...state, items };
  }

  /**
   * Cancel the job and refund all credits
   *
   * @throws Error if job is already in terminal state
   */
  async cancel(): Promise<void> {
    // Validate and transition to 'canceled'
    await this.transitionState('canceled');
  }

  /**
   * Fetch handler - RPC router for DO method calls
   *
   * Routes incoming requests to appropriate internal methods
   */
  async fetch(request: Request): Promise<Response> {
    try {
      const url = new URL(request.url);
      const path = url.pathname;

      // Route: POST /create
      if (path === '/create' && request.method === 'POST') {
        const body = await request.json<{
          jobId: string;
          userId: string;
          preset: string;
          totalItems: number;
        }>();
        await this.create(body.jobId, body.userId, body.preset, body.totalItems);
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Route: POST /confirm-upload
      if (path === '/confirm-upload' && request.method === 'POST') {
        const body = await request.json<{ totalItems: number }>();
        await this.confirmUpload(body.totalItems);
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Route: POST /mark-queued
      if (path === '/mark-queued' && request.method === 'POST') {
        const body = await request.json<{
          conceptsJson: string;
          protectJson: string;
          ruleId?: string;
        }>();
        await this.markQueued(body.conceptsJson, body.protectJson, body.ruleId);
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Route: GET /state
      if (path === '/state' && request.method === 'GET') {
        const state = await this.getState();
        return new Response(JSON.stringify(state), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Route: POST /callback
      if (path === '/callback' && request.method === 'POST') {
        const payload = await request.json<CallbackPayload>();
        const processed = await this.handleCallback(payload);
        return new Response(JSON.stringify({ processed }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Route: POST /cancel
      if (path === '/cancel' && request.method === 'POST') {
        await this.cancel();
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Route: POST /release (called by alarm for UserLimiterDO)
      if (path === '/release' && request.method === 'POST') {
        // This is handled internally by alarm() - just acknowledge
        return new Response(JSON.stringify({ success: true }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Unknown route
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return new Response(JSON.stringify({ error: errorMessage }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  }
}
