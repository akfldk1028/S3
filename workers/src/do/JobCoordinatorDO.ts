/**
 * JobCoordinatorDO — job당 1개 Durable Object
 *
 * SQLite-backed FSM + 멱등성 Ring Buffer (size 1000, TTL 24h) + Alarm D1 flush
 *
<<<<<<< HEAD
<<<<<<< HEAD
 * - blockConcurrencyWhile → SQLite 초기화 (job_state, job_items, seen_keys 테이블)
 * - FSM transitions:
 *   - create(jobId, userId, preset, totalItems) → 'created'
 *   - markUploaded() → 'uploaded'
 *   - markQueued(conceptsJson, protectJson, ruleId?) → 'queued'
 *   - onItemResult(callback: CallbackPayload) → 멱등성 체크 → 진행률 갱신
 *   - getStatus() → JobCoordinatorState + items
 *   - cancel() → 'canceled'
 * - 상태머신:
=======
 * 상태머신:
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
 *   created → uploaded (confirmUpload)
 *   uploaded → queued (markQueued + Queue push)
 *   queued → running (첫 callback 도착)
 *   running → done (done + failed == total)
 *   running → failed (failed > threshold)
 *   any non-terminal → canceled
<<<<<<< HEAD
 * - alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * - 멱등성: RingBuffer(1000, max age 24h) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
<<<<<<< HEAD
import type { Env, JobCoordinatorState, JobItemState, JobStatus, CallbackPayload } from '../_shared/types';

export class JobCoordinatorDO extends DurableObject<Env> {
<<<<<<< HEAD
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
=======
import type { CallbackPayload, Env, JobCoordinatorState, JobItemState, JobStatus } from '../_shared/types';
import { getUserLimiterStub } from './do.helpers';

const IDEMPOTENCY_RING_SIZE = 512;

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // SQLite 테이블 초기화 — DO 첫 활성화 시 한 번만 실행
    this.ctx.blockConcurrencyWhile(async () => {
=======
 * FSM transitions:
 *   created → uploaded (confirmUpload)
 *   uploaded → queued (markQueued + Queue push)
 *   queued → running (first callback via onItemResult)
 *   running → done (done + failed == total, done > 0)
 *   running → failed (done + failed == total, done == 0)
 *   any non-terminal → canceled
 *
 * alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * 멱등성: RingBuffer(512) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
import type { Env, JobStatus, JobCoordinatorState, JobItemState, CallbackPayload } from '../_shared/types';
import type { UserLimiterDO } from './UserLimiterDO';

// ─── Constants ────────────────────────────────────────────────────────────────

const IDEMPOTENCY_RING_SIZE = 512;

const TERMINAL_STATUSES: ReadonlySet<string> = new Set(['done', 'failed', 'canceled']);

/** Valid FSM transitions: from → allowed targets */
const VALID_TRANSITIONS: Partial<Record<JobStatus, JobStatus[]>> = {
  created: ['uploaded', 'canceled'],
  uploaded: ['queued', 'canceled'],
  queued: ['running', 'canceled'],
  running: ['done', 'failed', 'canceled'],
};

// ─── Internal row shape (for TS typing outside of exec<>) ─────────────────────

interface JobStateRow {
  job_id: string;
  user_id: string;
  status: string;
  preset: string;
  concepts_json: string;
  protect_json: string;
  rule_id: string | null;
  total_items: number;
  done_items: number;
  failed_items: number;
  created_at: string;
  updated_at: string;
}

interface JobItemRow {
  idx: number;
  status: string;
  input_key: string;
  output_key: string;
  preview_key: string;
  error: string | null;
}

// ─── Durable Object ──────────────────────────────────────────────────────────

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.ctx.blockConcurrencyWhile(async () => {
      // job_state: single row per DO, holds FSM state + counters
>>>>>>> auto-claude/025-workers-cors-일관성-cors
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id        TEXT PRIMARY KEY,
          user_id       TEXT NOT NULL,
          status        TEXT NOT NULL DEFAULT 'created',
<<<<<<< HEAD
=======
 *
 * alarm() → D1 flush (jobs_log + job_items_log INSERT) + UserLimiterDO.release()
 * 멱등성: RingBuffer(512) — seen_keys 테이블에 idempotency_key 저장
 */

import { DurableObject } from 'cloudflare:workers';
import type { CallbackPayload, Env, JobCoordinatorState, JobItemState, JobStatus } from '../_shared/types';

// Maximum idempotency ring buffer size
const SEEN_KEYS_MAX = 512;

export class JobCoordinatorDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // Initialize SQLite tables synchronously inside blockConcurrencyWhile.
    // sql.exec() is a SYNCHRONOUS method — no await needed or desired.
    // Using await here would introduce unnecessary microtask suspension points
    // inside blockConcurrencyWhile, potentially violating DO's single-thread model.
    this.ctx.blockConcurrencyWhile(async () => {
      // Table 1: Single-row FSM state for this job
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_state (
          job_id        TEXT NOT NULL,
          user_id       TEXT NOT NULL,
          status        TEXT NOT NULL DEFAULT 'created'
                        CHECK(status IN ('created','uploaded','queued','running','done','failed','canceled')),
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
          preset        TEXT NOT NULL DEFAULT '',
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json  TEXT NOT NULL DEFAULT '[]',
          rule_id       TEXT,
          total_items   INTEGER NOT NULL DEFAULT 0,
          done_items    INTEGER NOT NULL DEFAULT 0,
<<<<<<< HEAD
          failed_items  INTEGER NOT NULL DEFAULT 0
        )
      `);

      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          idx         INTEGER PRIMARY KEY,
          status      TEXT    NOT NULL DEFAULT 'pending',
          input_key   TEXT    NOT NULL DEFAULT '',
          output_key  TEXT    NOT NULL DEFAULT '',
          preview_key TEXT    NOT NULL DEFAULT '',
=======
          failed_items  INTEGER NOT NULL DEFAULT 0,
          created_at    TEXT NOT NULL,
          finished_at   TEXT
        )
      `);

      // Table 2: Per-item tracking (output_key/preview_key nullable — set by callback)
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          idx         INTEGER PRIMARY KEY,
          status      TEXT NOT NULL DEFAULT 'pending'
                      CHECK(status IN ('pending','done','failed')),
          input_key   TEXT NOT NULL,
          output_key  TEXT,
          preview_key TEXT,
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
          error       TEXT
        )
      `);

<<<<<<< HEAD
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          ring_pos        INTEGER NOT NULL
        )
>>>>>>> auto-claude/019-workers-크레딧-critical-jobs
=======
      // Table 3: Idempotency ring buffer (max SEEN_KEYS_MAX=512 entries)
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          inserted_at     INTEGER NOT NULL
        )
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
=======
          preset        TEXT NOT NULL,
          concepts_json TEXT NOT NULL DEFAULT '{}',
          protect_json  TEXT NOT NULL DEFAULT '[]',
          rule_id       TEXT,
          total_items   INTEGER NOT NULL,
          done_items    INTEGER NOT NULL DEFAULT 0,
          failed_items  INTEGER NOT NULL DEFAULT 0,
          created_at    TEXT NOT NULL,
          updated_at    TEXT NOT NULL
        )
      `);
      // job_items: one row per item (idx), tracks per-item result
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS job_items (
          job_id      TEXT NOT NULL,
          idx         INTEGER NOT NULL,
          status      TEXT NOT NULL DEFAULT 'pending',
          input_key   TEXT NOT NULL DEFAULT '',
          output_key  TEXT NOT NULL DEFAULT '',
          preview_key TEXT NOT NULL DEFAULT '',
          error       TEXT,
          PRIMARY KEY (job_id, idx)
        )
      `);
      // seen_keys: idempotency ring buffer (capacity: IDEMPOTENCY_RING_SIZE)
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS seen_keys (
          idempotency_key TEXT PRIMARY KEY,
          inserted_at     TEXT NOT NULL
        )
>>>>>>> auto-claude/025-workers-cors-일관성-cors
      `);
    });
  }

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
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
=======
  // ─── FSM helper ─────────────────────────────────────────────────────────────

  /**
   * Validates and executes a state transition.
   * Returns the current status row, or throws if the transition is invalid.
   */
  private transitionState(
    from: JobStatus[],
    to: JobStatus,
    finishedAt?: string
  ): { status: JobStatus } {
    const cursor = this.ctx.storage.sql.exec(
      'SELECT status FROM job_state LIMIT 1'
    );
    const row = cursor.toArray()[0] as { status: JobStatus } | undefined;
    if (!row) throw new Error('Job not initialized');

    if (!from.includes(row.status)) {
      throw new Error(`INVALID_STATE_TRANSITION: ${row.status} → ${to}`);
    }

    if (finishedAt) {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET status = ?1, finished_at = ?2',
        to,
        finishedAt
      );
    } else {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET status = ?1',
        to
      );
    }

    return { status: to };
  }

  // ─── Public methods (called via DO fetch handler) ────────────────────────────

  /**
   * create(jobId, userId, preset, totalItems)
   * Inserts the initial job_state row and populates job_items with pending rows.
   * Transitions: (no prior state) → 'created'
   */
  async create(
    jobId: string,
    userId: string,
    preset: string,
    totalItems: number
  ): Promise<void> {
    const now = new Date().toISOString();

    // Insert single job_state row
    this.ctx.storage.sql.exec(
      `INSERT INTO job_state
         (job_id, user_id, status, preset, total_items, created_at)
       VALUES (?1, ?2, 'created', ?3, ?4, ?5)`,
=======
  // ─── Private helpers ────────────────────────────────────────────────────────

  private getJobState(): JobStateRow | null {
    // Use inline type for exec<> to satisfy Record<string, SqlStorageValue> constraint
    const rows = this.ctx.storage.sql
      .exec<{
        job_id: string;
        user_id: string;
        status: string;
        preset: string;
        concepts_json: string;
        protect_json: string;
        rule_id: string | null;
        total_items: number;
        done_items: number;
        failed_items: number;
        created_at: string;
        updated_at: string;
      }>(
        `SELECT job_id, user_id, status, preset, concepts_json, protect_json,
                rule_id, total_items, done_items, failed_items, created_at, updated_at
         FROM job_state
         LIMIT 1`,
      )
      .toArray();
    return rows.length > 0 ? (rows[0] as JobStateRow) : null;
  }

  private async transitionState(newStatus: JobStatus): Promise<boolean> {
    const row = this.getJobState();
    if (!row) {
      console.log(`[JobCoordinatorDO][transitionState] REJECTED to=${newStatus} reason=no_job_state`);
      return false;
    }

    const currentStatus = row.status as JobStatus;
    const allowed = VALID_TRANSITIONS[currentStatus];

    if (!allowed || !allowed.includes(newStatus)) {
      console.log(
        `[JobCoordinatorDO][transitionState] REJECTED from=${currentStatus} to=${newStatus} reason=invalid_transition`,
      );
      return false;
    }

    console.log(`[JobCoordinatorDO][transitionState] from=${currentStatus} to=${newStatus}`);

    this.ctx.storage.sql.exec(
      `UPDATE job_state SET status = ?, updated_at = ?`,
      newStatus,
      new Date().toISOString(),
    );

    console.log(
      `[JobCoordinatorDO][transitionState] done jobId=${row.job_id} from=${currentStatus} to=${newStatus}`,
    );
    return true;
  }

  // ─── create ─────────────────────────────────────────────────────────────────

  create(jobId: string, userId: string, preset: string, totalItems: number): void {
    console.log(
      `[JobCoordinatorDO][create] jobId=${jobId} userId=${userId} preset=${preset} totalItems=${totalItems}`,
    );

    const now = new Date().toISOString();
    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO job_state
         (job_id, user_id, status, preset, total_items, created_at, updated_at)
       VALUES (?, ?, 'created', ?, ?, ?, ?)`,
>>>>>>> auto-claude/025-workers-cors-일관성-cors
      jobId,
      userId,
      preset,
      totalItems,
<<<<<<< HEAD
      now
    );

    // Populate job_items — output_key/preview_key start as NULL
    for (let idx = 0; idx < totalItems; idx++) {
      this.ctx.storage.sql.exec(
        `INSERT INTO job_items (idx, status, input_key, output_key, preview_key)
         VALUES (?1, 'pending', ?2, NULL, NULL)`,
        idx,
        `jobs/${jobId}/input/${idx}`
      );
    }
  }

  /**
   * confirmUpload()
   * Transitions: created → uploaded
   */
  async confirmUpload(): Promise<void> {
    this.transitionState(['created'], 'uploaded');
  }

  /**
   * markQueued(conceptsJson, protectJson, ruleId?)
   * Transitions: uploaded → queued
   */
  async markQueued(
    conceptsJson: string,
    protectJson: string,
    ruleId?: string | null
  ): Promise<void> {
    this.transitionState(['uploaded'], 'queued');

    this.ctx.storage.sql.exec(
      'UPDATE job_state SET concepts_json = ?1, protect_json = ?2, rule_id = ?3',
      conceptsJson,
      protectJson,
      ruleId ?? null
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
    );
  }

  /**
<<<<<<< HEAD
   * Handle callback from GPU Worker - update item status and progress
   *
   * @param payload Callback payload with item result
   * @returns true if processed, false if duplicate (idempotent)
   */
  async handleCallback(payload: CallbackPayload): Promise<boolean> {
    // Check idempotency - if we've seen this key before, skip processing
    const checkCursor = await this.ctx.storage.sql.exec(
=======
   * handleCallback(payload)
   * Processes a GPU worker callback for a single item.
   * Returns true if the callback was processed, false if discarded (duplicate/terminal).
   */
  async handleCallback(payload: CallbackPayload): Promise<boolean> {
    // GUARD: discard callbacks when job is already in a terminal state.
    // DO serializes all fetch requests, so this sequential check is sufficient
    // to prevent race conditions between /cancel and GPU callbacks.
    const statusCursor = this.ctx.storage.sql.exec(
      'SELECT status FROM job_state LIMIT 1'
    );
    const statusRow = statusCursor.toArray()[0] as { status: JobStatus } | undefined;

    if (!statusRow) {
      return false;
    }

    if (
      statusRow.status === 'canceled' ||
      statusRow.status === 'done' ||
      statusRow.status === 'failed'
    ) {
      return false;
    }

    // Idempotency check — has this key been processed before?
    const checkCursor = this.ctx.storage.sql.exec(
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
      'SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ?1',
      payload.idempotency_key
    );

    if (checkCursor.toArray().length > 0) {
<<<<<<< HEAD
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
=======
      return false;
    }

    // Record idempotency key (ring buffer eviction if over limit)
    this.ctx.storage.sql.exec(
      'INSERT INTO seen_keys (idempotency_key, inserted_at) VALUES (?1, ?2)',
      payload.idempotency_key,
      Date.now()
    );

    // Evict oldest entries if ring buffer exceeds max
    const countCursor = this.ctx.storage.sql.exec(
      'SELECT COUNT(*) as cnt FROM seen_keys'
    );
    const countRow = countCursor.toArray()[0] as { cnt: number } | undefined;
    if (countRow && countRow.cnt > SEEN_KEYS_MAX) {
      this.ctx.storage.sql.exec(
        `DELETE FROM seen_keys WHERE idempotency_key IN (
           SELECT idempotency_key FROM seen_keys
           ORDER BY inserted_at ASC
           LIMIT ?1
         )`,
        countRow.cnt - SEEN_KEYS_MAX
      );
    }

    // Update the item record — output_key/preview_key stored as null if absent
    this.ctx.storage.sql.exec(
      `UPDATE job_items
       SET status = ?1, output_key = ?2, preview_key = ?3, error = ?4
       WHERE idx = ?5`,
      payload.status,
      payload.output_key || null,
      payload.preview_key || null,
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
      payload.error || null,
      payload.idx
    );

<<<<<<< HEAD
    // Increment done_items or failed_items counter
    if (payload.status === 'done') {
      await this.ctx.storage.sql.exec(
        'UPDATE job_state SET done_items = done_items + 1'
      );
    } else if (payload.status === 'failed') {
      await this.ctx.storage.sql.exec(
=======
    // Update progress counters
    if (payload.status === 'done') {
      this.ctx.storage.sql.exec(
        'UPDATE job_state SET done_items = done_items + 1'
      );
    } else {
      this.ctx.storage.sql.exec(
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
        'UPDATE job_state SET failed_items = failed_items + 1'
      );
    }

<<<<<<< HEAD
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
=======
    // Check if all items are accounted for
    const progressCursor = this.ctx.storage.sql.exec(
      'SELECT total_items, done_items, failed_items FROM job_state LIMIT 1'
    );
    const progress = progressCursor.toArray()[0] as {
      total_items: number;
      done_items: number;
      failed_items: number;
    } | undefined;

    if (progress && progress.done_items + progress.failed_items >= progress.total_items) {
      const finalStatus: JobStatus =
        progress.failed_items > 0 ? 'failed' : 'done';
      const finishedAt = new Date().toISOString();

      this.transitionState(
        ['queued', 'running'],
        finalStatus,
        finishedAt
      );

      // Trigger alarm for D1 flush
      await this.ctx.storage.setAlarm(Date.now() + 1000);
    } else if (statusRow.status === 'queued') {
      // First callback — transition to running
      this.transitionState(['queued'], 'running');
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
    }

    return true;
  }

  /**
<<<<<<< HEAD
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
=======
  // ─── fetch 핸들러 (HTTP 라우팅) ──────────────────────────

  override async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/create' && request.method === 'POST') {
        return await this._handleCreate(request);
      }
      if (path === '/markUploaded' && request.method === 'POST') {
        return await this._handleMarkUploaded();
      }
      if (path === '/markQueued' && request.method === 'POST') {
        return await this._handleMarkQueued(request);
      }
      if (path === '/onItemResult' && request.method === 'POST') {
        return await this._handleOnItemResult(request);
      }
      if (path === '/getStatus' && request.method === 'GET') {
        return await this._handleGetStatus();
      }
      if (path === '/cancel' && request.method === 'POST') {
        return await this._handleCancel();
      }

>>>>>>> auto-claude/019-workers-크레딧-critical-jobs
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
<<<<<<< HEAD
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return new Response(JSON.stringify({ error: errorMessage }), {
=======
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Internal error';
      return new Response(JSON.stringify({ error: message }), {
>>>>>>> auto-claude/019-workers-크레딧-critical-jobs
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }
  }
<<<<<<< HEAD
=======
  // Bug 2 verified: await sql.exec() — no fix needed (file is a stub, no implementation present).
  // Scanned all sql.exec() calls in this file: none present (implementation is pending).
  // When implemented, all this.ctx.storage.sql.exec() calls MUST be called WITHOUT await —
  // ctx.storage.sql.exec() is synchronous in Cloudflare DO SQLite.
  // Planned locations that must NOT use await (per spec):
  //   constructor blockConcurrencyWhile: 3× CREATE TABLE calls
  //   transitionState(): 3× UPDATE/INSERT calls
  //   confirmUpload(): 1× UPDATE call
  //   handleCallback(): ~9× SELECT/INSERT/UPDATE calls
  //   alarm(): 2× SELECT calls
  //   create(): 3× INSERT/UPDATE calls
  //   markQueued(): 1× UPDATE call
  //   getState(): 2× SELECT calls
  // Preserve awaits on: ctx.blockConcurrencyWhile(), ctx.storage.setAlarm(),
  //   this.env.DB.*() D1 calls, and any async method calls.
  // TODO: implement FSM + idempotency + alarm
>>>>>>> auto-claude/010-workers-userlimiterdo-sql-파라미터
=======

  // ─── Alarm: D1 flush + UserLimiterDO.release() ──────────

  /**
   * alarm() — D1에 jobs_log + job_items_log를 INSERT하고,
   * [CRED-2] UserLimiterDO /release를 failedItems 포함한 새 시그니처로 호출.
   */
  override async alarm(): Promise<void> {
    const jobState = this._readJobState();
    if (!jobState) return;

    // D1 flush — jobs_log INSERT
    try {
      await this.env.DB.prepare(
        `INSERT OR IGNORE INTO jobs_log
         (job_id, user_id, status, preset, total_items, done_items, failed_items)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
      )
        .bind(
          jobState.jobId,
          jobState.userId,
          jobState.status,
          jobState.preset,
          jobState.totalItems,
          jobState.doneItems,
          jobState.failedItems,
        )
        .run();
    } catch (_err) {
      // D1 flush 실패는 치명적이지 않음 — 다음 alarm에서 재시도
    }

    // D1 flush — job_items_log INSERT
    try {
      const items = this._readJobItems();
      for (const item of items) {
        await this.env.DB.prepare(
          `INSERT OR IGNORE INTO job_items_log
           (job_id, idx, status, input_key, output_key, preview_key, error)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
        )
          .bind(
            jobState.jobId,
            item.idx,
            item.status,
            item.inputKey,
            item.outputKey,
            item.previewKey,
            item.error ?? null,
          )
          .run();
      }
    } catch (_err) {
      // D1 flush 실패는 치명적이지 않음 — 다음 alarm에서 재시도
    }

    // [CRED-2] UserLimiterDO /release — failedItems 포함하여 새 시그니처와 일치
    const limiterStub = getUserLimiterStub(this.env, jobState.userId);
    await limiterStub.fetch('http://do/release', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        doneItems: jobState.doneItems,
        failedItems: jobState.failedItems,
        totalItems: jobState.totalItems,
      }),
    });
  }

  // ─── 핸들러 구현 ─────────────────────────────────────────

  /**
   * POST /create — jobId, userId, preset, totalItems로 초기 상태 생성.
   */
  private async _handleCreate(request: Request): Promise<Response> {
    const { jobId, userId, preset, totalItems } = await request.json<{
      jobId: string;
      userId: string;
      preset: string;
      totalItems: number;
    }>();

    this.ctx.storage.sql.exec(
      `INSERT OR IGNORE INTO job_state (job_id, user_id, status, preset, total_items)
       VALUES (?, ?, 'created', ?, ?)`,
      jobId,
      userId,
      preset,
      totalItems,
    );

    return new Response(JSON.stringify({ success: true, status: 'created' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /markUploaded — 'created' → 'uploaded'.
   */
  private async _handleMarkUploaded(): Promise<Response> {
    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (state.status !== 'created') {
      return new Response(
        JSON.stringify({ error: `Invalid transition: ${state.status} → uploaded` }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      );
    }

    this.ctx.storage.sql.exec(
      `UPDATE job_state SET status = 'uploaded' WHERE job_id = ?`,
      state.jobId,
    );

    return new Response(JSON.stringify({ success: true, status: 'uploaded' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /markQueued — 'uploaded' → 'queued', conceptsJson + protectJson + ruleId? 설정.
   */
  private async _handleMarkQueued(request: Request): Promise<Response> {
    const { conceptsJson, protectJson, ruleId } = await request.json<{
      conceptsJson: string;
      protectJson: string;
      ruleId?: string;
    }>();

    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (state.status !== 'uploaded') {
      return new Response(
        JSON.stringify({ error: `Invalid transition: ${state.status} → queued` }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      );
    }

    this.ctx.storage.sql.exec(
      `UPDATE job_state
       SET status = 'queued', concepts_json = ?, protect_json = ?, rule_id = ?
       WHERE job_id = ?`,
      conceptsJson,
      protectJson,
      ruleId ?? null,
      state.jobId,
    );

    return new Response(JSON.stringify({ success: true, status: 'queued' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /onItemResult — 멱등성 체크 후 아이템 결과 반영 및 FSM 진행.
   * RingBuffer(512) 기반 중복 차단.
   */
  private async _handleOnItemResult(request: Request): Promise<Response> {
    const callback = await request.json<CallbackPayload>();
    const state = this._readJobState();

    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 멱등성 체크 — seen_keys RingBuffer
    if (this._isSeenKey(callback.idempotency_key)) {
      return new Response(JSON.stringify({ success: true, duplicate: true }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }
    this._recordSeenKey(callback.idempotency_key);

    // 아이템 상태 업데이트
    this.ctx.storage.sql.exec(
      `UPDATE job_items
       SET status = ?, output_key = ?, preview_key = ?, error = ?
       WHERE idx = ?`,
=======
      now,
      now,
    );

    for (let i = 0; i < totalItems; i++) {
      this.ctx.storage.sql.exec(
        `INSERT OR IGNORE INTO job_items (job_id, idx) VALUES (?, ?)`,
        jobId,
        i,
      );
    }

    console.log(`[JobCoordinatorDO][create] done jobId=${jobId} totalItems=${totalItems} status=created`);
  }

  // ─── confirmUpload (created → uploaded) ─────────────────────────────────────

  async confirmUpload(): Promise<{ success: boolean }> {
    const success = await this.transitionState('uploaded');
    return { success };
  }

  // ─── markQueued (uploaded → queued) ─────────────────────────────────────────

  async markQueued(
    conceptsJson: string,
    protectJson: string,
    ruleId?: string,
  ): Promise<{ success: boolean }> {
    const success = await this.transitionState('queued');
    if (success) {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET concepts_json = ?, protect_json = ?, rule_id = ?, updated_at = ?`,
        conceptsJson,
        protectJson,
        ruleId ?? null,
        new Date().toISOString(),
      );
    }
    return { success };
  }

  // ─── onItemResult / handleCallback ──────────────────────────────────────────

  async onItemResult(callback: CallbackPayload): Promise<{ success: boolean; duplicate: boolean }> {
    // 1. Idempotency check
    const existing = this.ctx.storage.sql
      .exec<{ idempotency_key: string }>(
        `SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ?`,
        callback.idempotency_key,
      )
      .toArray();

    const isDuplicate = existing.length > 0;

    console.log(
      `[JobCoordinatorDO][handleCallback] idx=${callback.idx} status=${callback.status} idempotent=${isDuplicate} key=${callback.idempotency_key}`,
    );

    if (isDuplicate) {
      console.log(
        `[JobCoordinatorDO][handleCallback] skipped duplicate idx=${callback.idx} key=${callback.idempotency_key}`,
      );
      return { success: true, duplicate: true };
    }

    // 2. Maintain idempotency ring buffer — evict oldest if at capacity
    const countRows = this.ctx.storage.sql
      .exec<{ cnt: number }>(`SELECT COUNT(*) AS cnt FROM seen_keys`)
      .toArray();
    const currentCount = countRows[0]?.cnt ?? 0;

    if (currentCount >= IDEMPOTENCY_RING_SIZE) {
      this.ctx.storage.sql.exec(
        `DELETE FROM seen_keys
         WHERE idempotency_key = (
           SELECT idempotency_key FROM seen_keys ORDER BY inserted_at ASC LIMIT 1
         )`,
      );
    }

    this.ctx.storage.sql.exec(
      `INSERT INTO seen_keys (idempotency_key, inserted_at) VALUES (?, ?)`,
      callback.idempotency_key,
      new Date().toISOString(),
    );

    // 3. Get current job state for job_id reference
    const jobRow = this.getJobState();
    if (!jobRow) {
      return { success: false, duplicate: false };
    }

    // 4. Update item record
    this.ctx.storage.sql.exec(
      `UPDATE job_items
         SET status = ?, output_key = ?, preview_key = ?, error = ?
       WHERE job_id = ? AND idx = ?`,
>>>>>>> auto-claude/025-workers-cors-일관성-cors
      callback.status,
      callback.output_key ?? '',
      callback.preview_key ?? '',
      callback.error ?? null,
<<<<<<< HEAD
      callback.idx,
    );

    // 진행률 갱신
    const column = callback.status === 'done' ? 'done_items' : 'failed_items';
    this.ctx.storage.sql.exec(
      `UPDATE job_state SET ${column} = ${column} + 1 WHERE job_id = ?`,
      state.jobId,
    );

    // FSM 전환: queued → running (첫 callback)
    if (state.status === 'queued') {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET status = 'running' WHERE job_id = ?`,
        state.jobId,
      );
    }

    // 완료 여부 체크 — 최신 상태 재조회
    const updated = this._readJobState();
    if (updated && updated.status === 'running') {
      const allProcessed = updated.doneItems + updated.failedItems >= updated.totalItems;
      if (allProcessed) {
        const newStatus: JobStatus = updated.failedItems > 0 ? 'failed' : 'done';
        this.ctx.storage.sql.exec(
          `UPDATE job_state SET status = ? WHERE job_id = ?`,
          newStatus,
          updated.jobId,
        );
        // alarm 스케줄 — D1 flush + release
        await this.ctx.storage.setAlarm(Date.now() + 1000);
      }
    }

    return new Response(JSON.stringify({ success: true, duplicate: false }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * GET /getStatus — 현재 job 상태 + 아이템 목록 반환.
   */
  private async _handleGetStatus(): Promise<Response> {
    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const items = this._readJobItems();
    return new Response(JSON.stringify({ ...state, items }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  /**
   * POST /cancel — 비종료 상태 → 'canceled'.
   */
  private async _handleCancel(): Promise<Response> {
    const state = this._readJobState();
    if (!state) {
      return new Response(JSON.stringify({ error: 'Job not initialized' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    if (this._isTerminalStatus(state.status)) {
      return new Response(
        JSON.stringify({ error: `Cannot cancel terminal status: ${state.status}` }),
        { status: 409, headers: { 'Content-Type': 'application/json' } },
      );
    }

    this.ctx.storage.sql.exec(
      `UPDATE job_state SET status = 'canceled' WHERE job_id = ?`,
      state.jobId,
    );

    return new Response(JSON.stringify({ success: true, status: 'canceled' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // ─── 내부 헬퍼 ───────────────────────────────────────────

  private _readJobState(): JobCoordinatorState | null {
    const cursor = this.ctx.storage.sql.exec<{
=======
   * cancel()
   * Transitions any non-terminal state → 'canceled'.
   * Triggers alarm for D1 flush.
   */
  async cancel(): Promise<void> {
    const nonTerminal: JobStatus[] = ['created', 'uploaded', 'queued', 'running'];
    this.transitionState(nonTerminal, 'canceled', new Date().toISOString());
    await this.ctx.storage.setAlarm(Date.now() + 1000);
  }

  /**
   * getState()
   * Returns the full JobCoordinatorState + items array.
   */
  async getState(): Promise<{ state: JobCoordinatorState; items: JobItemState[] } | null> {
    const stateCursor = this.ctx.storage.sql.exec(
      `SELECT job_id, user_id, status, preset, concepts_json, protect_json,
              rule_id, total_items, done_items, failed_items
       FROM job_state LIMIT 1`
    );
    const stateRows = stateCursor.toArray() as Array<{
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
      job_id: string;
      user_id: string;
      status: string;
      preset: string;
      concepts_json: string;
      protect_json: string;
      rule_id: string | null;
      total_items: number;
      done_items: number;
      failed_items: number;
<<<<<<< HEAD
    }>(`SELECT * FROM job_state LIMIT 1`);

    const rows = [...cursor];
    if (rows.length === 0) return null;

    const row = rows[0];
    return {
=======
      jobRow.job_id,
      callback.idx,
    );

    // 5. Increment progress counter
    if (callback.status === 'done') {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET done_items = done_items + 1, updated_at = ?`,
        new Date().toISOString(),
      );
    } else {
      this.ctx.storage.sql.exec(
        `UPDATE job_state SET failed_items = failed_items + 1, updated_at = ?`,
        new Date().toISOString(),
      );
    }

    // 6. Transition queued → running on first callback arrival
    if (jobRow.status === 'queued') {
      await this.transitionState('running');
    }

    // 7. Check for terminal condition
    const updatedRow = this.getJobState();
    if (updatedRow && updatedRow.status === 'running') {
      const { total_items, done_items, failed_items } = updatedRow;
      if (done_items + failed_items >= total_items) {
        const finalStatus: JobStatus = done_items > 0 ? 'done' : 'failed';
        await this.transitionState(finalStatus);
        // Schedule D1 flush alarm with short delay to batch any in-flight callbacks
        await this.ctx.storage.setAlarm(Date.now() + 5_000);
      }
    }

    console.log(
      `[JobCoordinatorDO][handleCallback] processed idx=${callback.idx} status=${callback.status} jobId=${jobRow.job_id}`,
    );
    return { success: true, duplicate: false };
  }

  // ─── getStatus ──────────────────────────────────────────────────────────────

  getStatus(): { state: JobCoordinatorState; items: JobItemState[] } | null {
    const row = this.getJobState();
    if (!row) return null;

    const itemRows = this.ctx.storage.sql
      .exec<{
        idx: number;
        status: string;
        input_key: string;
        output_key: string;
        preview_key: string;
        error: string | null;
      }>(
        `SELECT idx, status, input_key, output_key, preview_key, error
         FROM job_items
         ORDER BY idx`,
      )
      .toArray() as JobItemRow[];

    const state: JobCoordinatorState = {
>>>>>>> auto-claude/025-workers-cors-일관성-cors
      jobId: row.job_id,
      userId: row.user_id,
      status: row.status as JobStatus,
      preset: row.preset,
      conceptsJson: row.concepts_json,
      protectJson: row.protect_json,
      ruleId: row.rule_id,
      totalItems: row.total_items,
      doneItems: row.done_items,
      failedItems: row.failed_items,
    };
<<<<<<< HEAD
  }

  private _readJobItems(): JobItemState[] {
    const cursor = this.ctx.storage.sql.exec<{
      idx: number;
      status: string;
      input_key: string;
      output_key: string;
      preview_key: string;
      error: string | null;
    }>(`SELECT * FROM job_items ORDER BY idx ASC`);

    return [...cursor].map((row) => ({
      idx: row.idx,
      status: row.status as 'pending' | 'done' | 'failed',
      inputKey: row.input_key,
      outputKey: row.output_key,
      previewKey: row.preview_key,
      error: row.error ?? undefined,
    }));
  }

  private _isTerminalStatus(status: JobStatus): boolean {
    return status === 'done' || status === 'failed' || status === 'canceled';
  }

  private _isSeenKey(key: string): boolean {
    const cursor = this.ctx.storage.sql.exec<{ idempotency_key: string }>(
      `SELECT idempotency_key FROM seen_keys WHERE idempotency_key = ? LIMIT 1`,
      key,
    );
    return [...cursor].length > 0;
  }

  private _recordSeenKey(key: string): void {
    // RingBuffer: 총 개수 조회 후 오래된 항목 교체
    const countCursor = this.ctx.storage.sql.exec<{ cnt: number }>(
      `SELECT COUNT(*) as cnt FROM seen_keys`,
    );
    const count = [...countCursor][0]?.cnt ?? 0;
    const pos = count % IDEMPOTENCY_RING_SIZE;

    if (count >= IDEMPOTENCY_RING_SIZE) {
      // 가장 오래된 pos 위치의 항목 삭제 후 새 항목 삽입
      this.ctx.storage.sql.exec(
        `DELETE FROM seen_keys WHERE ring_pos = ?`,
        pos,
      );
    }

    this.ctx.storage.sql.exec(
      `INSERT INTO seen_keys (idempotency_key, ring_pos) VALUES (?, ?)`,
      key,
      pos,
    );
  }
>>>>>>> auto-claude/019-workers-크레딧-critical-jobs
=======
    }>;

    if (stateRows.length === 0) return null;

    const s = stateRows[0];

    const itemsCursor = this.ctx.storage.sql.exec(
      'SELECT idx, status, input_key, output_key, preview_key, error FROM job_items ORDER BY idx'
    );
    const itemRows = itemsCursor.toArray() as Array<{
      idx: number;
      status: string;
      input_key: string;
      output_key: string | null;
      preview_key: string | null;
      error: string | null;
    }>;

    const state: JobCoordinatorState = {
      jobId: s.job_id,
      userId: s.user_id,
      status: s.status as JobStatus,
      preset: s.preset,
      conceptsJson: s.concepts_json,
      protectJson: s.protect_json,
      ruleId: s.rule_id,
      totalItems: s.total_items,
      doneItems: s.done_items,
      failedItems: s.failed_items,
    };
=======
>>>>>>> auto-claude/025-workers-cors-일관성-cors

    const items: JobItemState[] = itemRows.map((r) => ({
      idx: r.idx,
      status: r.status as 'pending' | 'done' | 'failed',
      inputKey: r.input_key,
      outputKey: r.output_key,
      previewKey: r.preview_key,
<<<<<<< HEAD
      error: r.error ?? undefined,
=======
      ...(r.error !== null ? { error: r.error } : {}),
>>>>>>> auto-claude/025-workers-cors-일관성-cors
    }));

    return { state, items };
  }

<<<<<<< HEAD
  // ─── Alarm handler ───────────────────────────────────────────────────────────

  /**
   * alarm()
   * Triggered after job reaches a terminal state (done/failed/canceled).
   * Step 1: D1 batch flush — throws on failure (CF retries alarm; INSERT OR REPLACE is idempotent).
   * Step 2: UserLimiterDO.release() — retried up to 3 times with exponential backoff.
   *         On persistent failure, sends a DLQ message to GPU_QUEUE and logs the error.
   *         Does NOT throw (D1 flush already succeeded; re-throwing causes duplicate flush risk).
   */
  async alarm(): Promise<void> {
    // Step 1: Read job state
    const stateCursor = this.ctx.storage.sql.exec(
      `SELECT job_id, user_id, status, preset, concepts_json, protect_json,
              rule_id, total_items, done_items, failed_items, created_at, finished_at
       FROM job_state LIMIT 1`
    );
    const stateRows = stateCursor.toArray() as Array<{
      job_id: string;
      user_id: string;
      status: string;
      preset: string;
      concepts_json: string;
      protect_json: string;
      rule_id: string | null;
      total_items: number;
      done_items: number;
      failed_items: number;
      created_at: string;
      finished_at: string | null;
    }>;

    if (stateRows.length === 0) return;

    const jobState = stateRows[0];

    // Step 2: Read all items
    const itemsCursor = this.ctx.storage.sql.exec(
      'SELECT idx, status, input_key, output_key, preview_key, error FROM job_items ORDER BY idx'
    );
    const items = itemsCursor.toArray() as Array<{
      idx: number;
      status: string;
      input_key: string;
      output_key: string | null;
      preview_key: string | null;
      error: string | null;
    }>;

    // Step 3: D1 atomic batch flush
    const batchStatements: D1PreparedStatement[] = [];

    batchStatements.push(
      this.env.DB.prepare(
        `INSERT OR REPLACE INTO jobs_log
           (job_id, user_id, created_at, finished_at, status, preset,
            rule_id, concepts_json, protect_json)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)`
      ).bind(
        jobState.job_id,
        jobState.user_id,
        jobState.created_at,
        jobState.finished_at,
        jobState.status,
        jobState.preset,
        jobState.rule_id,
        jobState.concepts_json,
        jobState.protect_json
      )
    );

    for (const item of items) {
      batchStatements.push(
        this.env.DB.prepare(
          `INSERT OR REPLACE INTO job_items_log
             (job_id, idx, status, input_key, output_key, error)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6)`
        ).bind(
          jobState.job_id,
          item.idx,
          item.status,
          item.input_key,
          item.output_key,
          item.error
        )
      );
    }

    try {
      await this.env.DB.batch(batchStatements);
    } catch (dbError) {
      // D1 flush failed → throw so CF retries the alarm (INSERT OR REPLACE is idempotent)
      console.error('[alarm] D1 batch flush failed:', dbError);
      throw dbError;
    }

    // Step 4: UserLimiterDO.release() with retry + DLQ fallback
    const userLimiterId = this.env.USER_LIMITER.idFromName(jobState.user_id);
    const userLimiterStub = this.env.USER_LIMITER.get(userLimiterId);

    const MAX_RETRIES = 3;
    let releaseError: Error | null = null;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        const releaseResp = await userLimiterStub.fetch('http://internal/release', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            jobId: jobState.job_id,
            doneItems: jobState.done_items,
            totalItems: jobState.total_items,
          }),
        });

        if (releaseResp.ok) {
          releaseError = null;
          break;
        }

        releaseError = new Error(
          `UserLimiterDO.release() HTTP ${releaseResp.status} on attempt ${attempt}`
        );
      } catch (fetchError) {
        releaseError = fetchError instanceof Error
          ? fetchError
          : new Error(String(fetchError));
      }

      // Exponential backoff: 100ms → 200ms → 400ms
      if (attempt < MAX_RETRIES) {
        await new Promise<void>((r) => setTimeout(r, 100 * Math.pow(2, attempt - 1)));
      }
    }

    if (releaseError) {
      // 3 attempts all failed → send DLQ message to GPU_QUEUE for ops monitoring
      try {
        await this.env.GPU_QUEUE.send({
          type: 'release-failed',
          jobId: jobState.job_id,
          userId: jobState.user_id,
          doneItems: jobState.done_items,
          totalItems: jobState.total_items,
          error: releaseError.message,
          timestamp: Date.now(),
        } as any);
      } catch (dlqError) {
        console.error('[alarm] DLQ send also failed:', dlqError);
      }
      // Do NOT throw — D1 flush already succeeded; throwing would cause duplicate flush on retry
      console.error(
        `[alarm] release() failed after ${MAX_RETRIES} retries for job ${jobState.job_id}:`,
        releaseError.message
      );
    }
  }

  // ─── HTTP fetch handler ──────────────────────────────────────────────────────

  /**
   * fetch() — routes incoming HTTP requests to the appropriate method.
   * Cloudflare DO serializes all incoming fetch calls, ensuring single-threaded execution.
   */
  override async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (request.method === 'POST' && path === '/create') {
        const body = await request.json() as {
          jobId: string;
          userId: string;
          preset: string;
          totalItems: number;
        };
        await this.create(body.jobId, body.userId, body.preset, body.totalItems);
        return Response.json({ ok: true });
      }

      if (request.method === 'POST' && path === '/confirm-upload') {
        await this.confirmUpload();
        return Response.json({ ok: true });
      }

      if (request.method === 'POST' && path === '/mark-queued') {
        const body = await request.json() as {
          conceptsJson: string;
          protectJson: string;
          ruleId?: string | null;
        };
        await this.markQueued(body.conceptsJson, body.protectJson, body.ruleId);
        return Response.json({ ok: true });
      }

      if (request.method === 'POST' && path === '/callback') {
        const payload = await request.json() as CallbackPayload;
        const processed = await this.handleCallback(payload);
        return Response.json({ processed });
      }

      if (request.method === 'POST' && path === '/cancel') {
        await this.cancel();
        return Response.json({ ok: true });
      }

      if (request.method === 'GET' && path === '/state') {
        const result = await this.getState();
        return Response.json(result);
      }

      return new Response('Not Found', { status: 404 });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      const status = message.startsWith('INVALID_STATE_TRANSITION') ? 400 : 500;
      return Response.json({ error: message }, { status });
    }
  }
>>>>>>> auto-claude/024-workers-jobcoordinatordo-상태머신-alarm
=======
  // ─── cancel (any non-terminal → canceled) ───────────────────────────────────

  async cancel(): Promise<{ success: boolean }> {
    const row = this.getJobState();
    if (!row || TERMINAL_STATUSES.has(row.status)) {
      return { success: false };
    }

    const success = await this.transitionState('canceled');
    if (success) {
      // Schedule D1 flush + release
      await this.ctx.storage.setAlarm(Date.now() + 5_000);
    }
    return { success };
  }

  // ─── alarm (D1 flush + UserLimiterDO.release) ────────────────────────────────

  async alarm(): Promise<void> {
    const row = this.getJobState();
    if (!row) {
      console.log('[JobCoordinatorDO][alarm] no job state found, skipping');
      return;
    }

    console.log(
      `[JobCoordinatorDO][alarm] flushing jobId=${row.job_id} status=${row.status} doneItems=${row.done_items} failedItems=${row.failed_items} totalItems=${row.total_items}`,
    );

    const now = new Date().toISOString();

    // ── D1 flush: jobs_log ──
    try {
      await this.env.DB.prepare(
        `INSERT OR REPLACE INTO jobs_log
           (job_id, user_id, status, preset, rule_id, concepts_json, protect_json, finished_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      )
        .bind(
          row.job_id,
          row.user_id,
          row.status,
          row.preset,
          row.rule_id,
          row.concepts_json,
          row.protect_json,
          now,
        )
        .run();

      console.log(`[JobCoordinatorDO][alarm] jobs_log flush done jobId=${row.job_id}`);
    } catch (e) {
      console.log(
        `[JobCoordinatorDO][alarm] jobs_log flush error jobId=${row.job_id} error=${String(e)}`,
      );
    }

    // ── D1 flush: job_items_log ──
    try {
      const itemRows = this.ctx.storage.sql
        .exec<{
          idx: number;
          status: string;
          input_key: string;
          output_key: string;
          preview_key: string;
          error: string | null;
        }>(
          `SELECT idx, status, input_key, output_key, preview_key, error
           FROM job_items
           ORDER BY idx`,
        )
        .toArray() as JobItemRow[];

      for (const item of itemRows) {
        await this.env.DB.prepare(
          `INSERT OR REPLACE INTO job_items_log
             (job_id, idx, status, input_key, output_key, error)
           VALUES (?, ?, ?, ?, ?, ?)`,
        )
          .bind(row.job_id, item.idx, item.status, item.input_key, item.output_key, item.error)
          .run();
      }

      console.log(
        `[JobCoordinatorDO][alarm] job_items_log flush done jobId=${row.job_id} itemCount=${itemRows.length}`,
      );
    } catch (e) {
      console.log(
        `[JobCoordinatorDO][alarm] job_items_log flush error jobId=${row.job_id} error=${String(e)}`,
      );
    }

    // ── UserLimiterDO.release (only for terminal states) ──
    if (TERMINAL_STATUSES.has(row.status)) {
      try {
        const limiterNs = this.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
        const limiterStub = limiterNs.get(limiterNs.idFromName(row.user_id));
        await limiterStub.release(row.job_id);
        console.log(
          `[JobCoordinatorDO][alarm] UserLimiterDO.release done jobId=${row.job_id} userId=${row.user_id}`,
        );
      } catch (e) {
        console.log(
          `[JobCoordinatorDO][alarm] UserLimiterDO.release error jobId=${row.job_id} error=${String(e)}`,
        );
      }
    }

    console.log(`[JobCoordinatorDO][alarm] complete jobId=${row.job_id} status=${row.status}`);
  }
>>>>>>> auto-claude/025-workers-cors-일관성-cors
}
