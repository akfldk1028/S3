/**
 * Rules Route — CRUD 4 endpoints
 *
 * TODO: Auto-Claude 구현
 * - POST /rules → 룰 저장 (UserLimiterDO.checkRuleSlot → D1 INSERT → incrementRuleSlot)
 * - GET /rules → 내 룰 목록 (D1 SELECT)
 * - PUT /rules/:id → 룰 수정 (D1 UPDATE)
 * - DELETE /rules/:id → 룰 삭제 (D1 DELETE → decrementRuleSlot)
 * - 패턴: Route → Zod validate → DO guard → Service(D1) → DO side-effect
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';
import { ok, error } from '../_shared/response';
import { ERR } from '../_shared/errors';
import { PLAN_LIMITS } from '../_shared/types';
import { CreateRuleSchema, UpdateRuleSchema } from './rules.validator';
import { PRESETS } from '../presets/presets.data';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /rules
app.post('/', async (c) => {
  try {
    const user = c.get('user');
    if (!user || !user.userId) {
      return c.json(error(ERR.AUTH_REQUIRED, 'Authentication required'), 401);
    }

    // Parse and validate request body
    const body = await c.req.json().catch(() => ({}));
    const parsed = CreateRuleSchema.safeParse(body);
    if (!parsed.success) {
      return c.json(
        error(ERR.VALIDATION_FAILED, parsed.error.errors.map((e) => e.message).join(', ')),
        400
      );
    }

    const { name, preset_id, concepts, protect } = parsed.data;

    // Validate preset exists
    if (!PRESETS[preset_id]) {
      return c.json(error(ERR.INVALID_PRESET, `Preset '${preset_id}' not found`), 400);
    }

    // Get user plan to check rule slot limit
    const userRow = await c.env.DB
      .prepare('SELECT plan FROM users WHERE id = ?')
      .bind(user.userId)
      .first<{ plan: 'free' | 'pro' }>();

    if (!userRow) {
      return c.json(error(ERR.NOT_FOUND, 'User not found'), 404);
    }

    // Check current rule count against plan limits
    const ruleCountResult = await c.env.DB
      .prepare('SELECT COUNT(*) as count FROM rules WHERE user_id = ?')
      .bind(user.userId)
      .first<{ count: number }>();

    const currentRuleCount = ruleCountResult?.count || 0;
    const maxRuleSlots = PLAN_LIMITS[userRow.plan].maxRuleSlots;

    if (currentRuleCount >= maxRuleSlots) {
      return c.json(
        error(ERR.RULE_SLOT_LIMIT, `Rule slot limit reached (${maxRuleSlots} for ${userRow.plan} plan)`),
        403
      );
    }

    // Create rule in D1
    const ruleId = crypto.randomUUID();
    const conceptsJson = JSON.stringify(concepts);
    const protectJson = JSON.stringify(protect);

    await c.env.DB
      .prepare(
        'INSERT INTO rules (id, user_id, name, preset_id, concepts_json, protect_json) VALUES (?, ?, ?, ?, ?, ?)'
      )
      .bind(ruleId, user.userId, name, preset_id, conceptsJson, protectJson)
      .run();

    return c.json(
      ok({
        id: ruleId,
        user_id: user.userId,
        name,
        preset_id,
        concepts_json: conceptsJson,
        protect_json: protectJson,
      })
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json(error(ERR.INTERNAL_ERROR, message), 500);
  }
});

// GET /rules
app.get('/', async (c) => {
  try {
    const user = c.get('user');
    if (!user || !user.userId) {
      return c.json(error(ERR.AUTH_REQUIRED, 'Authentication required'), 401);
    }

    // Query all rules for the user
    const result = await c.env.DB
      .prepare('SELECT id, user_id, name, preset_id, concepts_json, protect_json, created_at, updated_at FROM rules WHERE user_id = ? ORDER BY created_at DESC')
      .bind(user.userId)
      .all<{
        id: string;
        user_id: string;
        name: string;
        preset_id: string;
        concepts_json: string;
        protect_json: string | null;
        created_at: string;
        updated_at: string | null;
      }>();

    const rules = result.results || [];

    return c.json(ok({ rules }));
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json(error(ERR.INTERNAL_ERROR, message), 500);
  }
});

// GET /rules/:id
app.get('/:id', async (c) => {
  try {
    const user = c.get('user');
    if (!user || !user.userId) {
      return c.json(error(ERR.AUTH_REQUIRED, 'Authentication required'), 401);
    }

    const ruleId = c.req.param('id');

    // Query the specific rule
    const rule = await c.env.DB
      .prepare('SELECT id, user_id, name, preset_id, concepts_json, protect_json, created_at, updated_at FROM rules WHERE id = ?')
      .bind(ruleId)
      .first<{
        id: string;
        user_id: string;
        name: string;
        preset_id: string;
        concepts_json: string;
        protect_json: string | null;
        created_at: string;
        updated_at: string | null;
      }>();

    // Check if rule exists
    if (!rule) {
      return c.json(error(ERR.RULE_NOT_FOUND, 'Rule not found'), 404);
    }

    // Check if rule belongs to the user
    if (rule.user_id !== user.userId) {
      return c.json(error(ERR.RULE_FORBIDDEN, 'Access denied to this rule'), 403);
    }

    return c.json(ok(rule));
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json(error(ERR.INTERNAL_ERROR, message), 500);
  }
});

// PUT /rules/:id
app.put('/:id', async (c) => {
  try {
    const user = c.get('user');
    if (!user || !user.userId) {
      return c.json(error(ERR.AUTH_REQUIRED, 'Authentication required'), 401);
    }

    const ruleId = c.req.param('id');

    // Parse and validate request body
    const body = await c.req.json().catch(() => ({}));
    const parsed = UpdateRuleSchema.safeParse(body);
    if (!parsed.success) {
      return c.json(
        error(ERR.VALIDATION_FAILED, parsed.error.errors.map((e) => e.message).join(', ')),
        400
      );
    }

    // Query the existing rule
    const existingRule = await c.env.DB
      .prepare('SELECT id, user_id, name, preset_id, concepts_json, protect_json FROM rules WHERE id = ?')
      .bind(ruleId)
      .first<{
        id: string;
        user_id: string;
        name: string;
        preset_id: string;
        concepts_json: string;
        protect_json: string | null;
      }>();

    // Check if rule exists
    if (!existingRule) {
      return c.json(error(ERR.RULE_NOT_FOUND, 'Rule not found'), 404);
    }

    // Check if rule belongs to the user
    if (existingRule.user_id !== user.userId) {
      return c.json(error(ERR.RULE_FORBIDDEN, 'Access denied to this rule'), 403);
    }

    const { name, preset_id, concepts, protect } = parsed.data;

    // If preset_id is being updated, validate it exists
    if (preset_id && !PRESETS[preset_id]) {
      return c.json(error(ERR.INVALID_PRESET, `Preset '${preset_id}' not found`), 400);
    }

    // Build update values
    const updatedName = name ?? existingRule.name;
    const updatedPresetId = preset_id ?? existingRule.preset_id;
    const updatedConceptsJson = concepts ? JSON.stringify(concepts) : existingRule.concepts_json;
    const updatedProtectJson = protect ? JSON.stringify(protect) : existingRule.protect_json;
    const updatedAt = new Date().toISOString();

    // Update rule in D1
    await c.env.DB
      .prepare(
        'UPDATE rules SET name = ?, preset_id = ?, concepts_json = ?, protect_json = ?, updated_at = ? WHERE id = ?'
      )
      .bind(updatedName, updatedPresetId, updatedConceptsJson, updatedProtectJson, updatedAt, ruleId)
      .run();

    return c.json(
      ok({
        id: ruleId,
        user_id: user.userId,
        name: updatedName,
        preset_id: updatedPresetId,
        concepts_json: updatedConceptsJson,
        protect_json: updatedProtectJson,
        updated_at: updatedAt,
      })
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    return c.json(error(ERR.INTERNAL_ERROR, message), 500);
  }
});

// DELETE /rules/:id

export default app;
