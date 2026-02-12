/**
 * User Route — GET /me
 *
 * TODO: Auto-Claude 구현
 * - UserLimiterDO.getUserState() → { user_id, plan, credits, active_jobs, rule_slots: { used, max } }
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// GET /me

export default app;
