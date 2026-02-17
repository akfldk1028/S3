/**
 * Rules Service — D1 CRUD queries
 */

import type { Rule } from '../_shared/types';

export async function createRule(
  db: D1Database,
  userId: string,
  data: { name: string; preset_id: string; concepts_json: string; protect_json: string | null },
): Promise<string> {
  const ruleId = crypto.randomUUID();
  await db
    .prepare(
      `INSERT INTO rules (id, user_id, name, preset_id, concepts_json, protect_json, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    )
    .bind(ruleId, userId, data.name, data.preset_id, data.concepts_json, data.protect_json, new Date().toISOString())
    .run();
  return ruleId;
}

export async function listRules(db: D1Database, userId: string): Promise<Rule[]> {
  const result = await db
    .prepare(`SELECT id, user_id, name, preset_id, concepts_json, protect_json, created_at, updated_at FROM rules WHERE user_id = ? ORDER BY created_at DESC`)
    .bind(userId)
    .all<Rule>();
  return result.results;
}

export async function getRule(db: D1Database, ruleId: string, userId: string): Promise<Rule | null> {
  const result = await db
    .prepare(`SELECT id, user_id, name, preset_id, concepts_json, protect_json, created_at, updated_at FROM rules WHERE id = ? AND user_id = ?`)
    .bind(ruleId, userId)
    .first<Rule>();
  return result ?? null;
}

export async function updateRule(
  db: D1Database,
  ruleId: string,
  userId: string,
  data: Partial<{ name: string; concepts_json: string; protect_json: string | null }>,
): Promise<boolean> {
  const fields: string[] = [];
  const values: unknown[] = [];

  if (data.name !== undefined) {
    fields.push('name = ?');
    values.push(data.name);
  }
  if (data.concepts_json !== undefined) {
    fields.push('concepts_json = ?');
    values.push(data.concepts_json);
  }
  if (data.protect_json !== undefined) {
    fields.push('protect_json = ?');
    values.push(data.protect_json);
  }

  if (fields.length === 0) return true;

  fields.push('updated_at = ?');
  values.push(new Date().toISOString());
  values.push(ruleId);
  values.push(userId);

  const result = await db
    .prepare(`UPDATE rules SET ${fields.join(', ')} WHERE id = ? AND user_id = ?`)
    .bind(...values)
    .run();
  return (result.meta.changes ?? 0) > 0;
}

export async function deleteRule(db: D1Database, ruleId: string, userId: string): Promise<boolean> {
  const result = await db
    .prepare(`DELETE FROM rules WHERE id = ? AND user_id = ?`)
    .bind(ruleId, userId)
    .run();
  return (result.meta.changes ?? 0) > 0;
}
