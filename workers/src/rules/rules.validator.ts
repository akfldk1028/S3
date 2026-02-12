/**
 * Rules Zod Validators
 *
 * TODO: Auto-Claude 구현
 * - CreateRuleSchema: { name, preset_id, concepts (Record<string, {action, value}>), protect (string[]) }
 * - UpdateRuleSchema: { name?, concepts?, protect? }
 */

import { z } from 'zod';

export const CreateRuleSchema = z.object({
  // TODO: define schema
});

export const UpdateRuleSchema = z.object({
  // TODO: define schema
});
