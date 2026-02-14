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
import { PRESETS } from './presets.data';
import { ok } from '../_shared/response';

const app = new Hono<{ Bindings: Env; Variables: { user: AuthUser } }>();

// GET /presets — 프리셋 목록 반환
app.get('/', (c) => {
  const presetList = Object.values(PRESETS).map((preset) => ({
    id: preset.id,
    name: preset.name,
    description: `${preset.name} 도메인 팔레트`,
  }));

  return c.json(ok(presetList));
});

// GET /presets/:id

export default app;
