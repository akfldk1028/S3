/**
 * Auth Route — POST /auth/anon
 *
 * TODO: Auto-Claude 구현
 * - device_hash (optional) 받음
 * - auth.service.ts → D1 user 생성 + JWT 발급
 * - Response: { user_id, token }
 *
 * Bug 3 verified: No duplicate GET /me handler present.
 * The canonical GET /me handler lives in user.route.ts (mounted at /me in index.ts).
 * No ERR import exists — no unused imports.
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// POST /auth/anon

export default app;
