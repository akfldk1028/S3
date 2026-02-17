/**
 * Rules Route — CRUD 4 endpoints
 *
 * - POST /rules → 룰 저장 (UserLimiterDO.checkRuleSlot → D1 INSERT → incrementRuleSlot)
 * - GET /rules → 내 룰 목록 (D1 SELECT)
 * - GET /rules/:id → 단건 조회 (D1 SELECT)
 * - PUT /rules/:id → 룰 수정 (D1 UPDATE)
 * - DELETE /rules/:id → 룰 삭제 (D1 DELETE → decrementRuleSlot)
 * - 패턴: Route → Zod validate → DO guard → Service(D1) → DO side-effect
 *
 * Response shape:
 * - GET /rules        → ok({ rules }) → data.rules (배열)
 * - GET /rules/:id    → ok({ rule })  → data.rule  (단건 객체)
 * - POST /rules       → ok({ rule })  → data.rule  (생성된 객체)
 * - PUT /rules/:id    → ok({ rule })  → data.rule  (수정된 객체)
 * - DELETE /rules/:id → ok({ id, deleted }) → data.id + data.deleted
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';
import { ok, error } from '../_shared/response';
import { ERR } from '../_shared/errors';
import type { UserLimiterDO } from '../do/UserLimiterDO';
import { createRule, listRules, getRule, updateRule, deleteRule } from './rules.service';
import { CreateRuleSchema, UpdateRuleSchema } from './rules.validator';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// ─── POST /rules ──────────────────────────────────────────────────────────────
// 룰 생성: 슬롯 확인 → D1 INSERT → 슬롯 증가

app.post('/', async (c) => {
  const user = c.get('user');

  const body = await c.req.json();
  const parsed = CreateRuleSchema.safeParse(body);
  if (!parsed.success) {
    return c.json(error(ERR.VALIDATION_FAILED, 'Invalid request body'), 400);
  }

  const { name, preset_id, concepts, protect } = parsed.data;

  try {
    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));

    const hasSlot = await limiterStub.checkRuleSlot();
    if (!hasSlot) {
      return c.json(error(ERR.RULE_SLOT_LIMIT, 'Rule slot limit reached for current plan'), 403);
    }

    const concepts_json = JSON.stringify(concepts);
    const protect_json = protect.length > 0 ? JSON.stringify(protect) : null;

    const ruleId = await createRule(c.env.DB, user.userId, {
      name,
      preset_id,
      concepts_json,
      protect_json,
    });

    await limiterStub.incrementRuleSlot();

    return c.json(
      ok({
        rule: {
          id: ruleId,
          user_id: user.userId,
          name,
          preset_id,
          concepts_json,
          protect_json,
        },
      }),
      201,
    );
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── GET /rules ───────────────────────────────────────────────────────────────
// 내 룰 목록 조회 → data.rules (배열)

app.get('/', async (c) => {
  const user = c.get('user');

  try {
    const rules = await listRules(c.env.DB, user.userId);
    return c.json(ok({ rules }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── GET /rules/:id ───────────────────────────────────────────────────────────
// 단건 조회 → data.rule (단건 객체) — ok({ rule }) 패턴

app.get('/:id', async (c) => {
  const user = c.get('user');
  const ruleId = c.req.param('id');

  try {
    const rule = await getRule(c.env.DB, ruleId, user.userId);
    if (!rule) {
      return c.json(error(ERR.RULE_NOT_FOUND, 'Rule not found'), 404);
    }

    return c.json(ok({ rule }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── PUT /rules/:id ───────────────────────────────────────────────────────────
// 룰 수정 → data.rule (수정된 객체)

app.put('/:id', async (c) => {
  const user = c.get('user');
  const ruleId = c.req.param('id');

  const body = await c.req.json();
  const parsed = UpdateRuleSchema.safeParse(body);
  if (!parsed.success) {
    return c.json(error(ERR.VALIDATION_FAILED, 'Invalid request body'), 400);
  }

  try {
    const { name, concepts, protect } = parsed.data;
    const updateData: Partial<{ name: string; concepts_json: string; protect_json: string | null }> = {};

    if (name !== undefined) updateData.name = name;
    if (concepts !== undefined) updateData.concepts_json = JSON.stringify(concepts);
    if (protect !== undefined) updateData.protect_json = protect.length > 0 ? JSON.stringify(protect) : null;

    const updated = await updateRule(c.env.DB, ruleId, user.userId, updateData);
    if (!updated) {
      return c.json(error(ERR.RULE_NOT_FOUND, 'Rule not found or access denied'), 404);
    }

    const rule = await getRule(c.env.DB, ruleId, user.userId);
    return c.json(ok({ rule }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

// ─── DELETE /rules/:id ────────────────────────────────────────────────────────
// 룰 삭제 → D1 DELETE → decrementRuleSlot

app.delete('/:id', async (c) => {
  const user = c.get('user');
  const ruleId = c.req.param('id');

  try {
    const deleted = await deleteRule(c.env.DB, ruleId, user.userId);
    if (!deleted) {
      return c.json(error(ERR.RULE_NOT_FOUND, 'Rule not found or access denied'), 404);
    }

    const limiterNs = c.env.USER_LIMITER as unknown as DurableObjectNamespace<UserLimiterDO>;
    const limiterStub = limiterNs.get(limiterNs.idFromName(user.userId));
    await limiterStub.decrementRuleSlot();

    return c.json(ok({ id: ruleId, deleted: true }));
  } catch (e) {
    return c.json(error(ERR.INTERNAL_ERROR, String(e)), 500);
  }
});

export default app;
