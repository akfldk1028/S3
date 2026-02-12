/**
 * Presets Route — GET /presets, GET /presets/{id}
 *
 * TODO: Auto-Claude 구현
 * - GET /presets → 프리셋 목록 [{ id, name, concept_count }]
 * - GET /presets/:id → 프리셋 상세 { id, name, concepts, protect_defaults, output_templates }
 * - 데이터: presets.data.ts 에서 import
 */

import { Hono } from 'hono';
import type { Env, AuthUser } from '../_shared/types';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// GET /presets
// GET /presets/:id

export default app;
