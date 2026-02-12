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

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /rules
// GET /rules
// PUT /rules/:id
// DELETE /rules/:id

export default app;
