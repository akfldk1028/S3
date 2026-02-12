/**
 * Rules Service — D1 CRUD queries
 *
 * TODO: Auto-Claude 구현
 * - createRule(db, userId, data) → rule_id
 * - listRules(db, userId) → Rule[]
 * - getRule(db, ruleId) → Rule | null
 * - updateRule(db, ruleId, userId, data) → boolean
 * - deleteRule(db, ruleId, userId) → boolean
 */

import type { Rule } from '../_shared/types';

export async function createRule(
  db: D1Database,
  userId: string,
  data: { name: string; preset_id: string; concepts_json: string; protect_json: string | null },
): Promise<string> {
  // TODO: implement
  throw new Error('Not implemented');
}

export async function listRules(db: D1Database, userId: string): Promise<Rule[]> {
  // TODO: implement
  throw new Error('Not implemented');
}

export async function updateRule(
  db: D1Database,
  ruleId: string,
  userId: string,
  data: Partial<{ name: string; concepts_json: string; protect_json: string | null }>,
): Promise<boolean> {
  // TODO: implement
  throw new Error('Not implemented');
}

export async function deleteRule(db: D1Database, ruleId: string, userId: string): Promise<boolean> {
  // TODO: implement
  throw new Error('Not implemented');
}
