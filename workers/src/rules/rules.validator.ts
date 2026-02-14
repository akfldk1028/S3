/**
 * Rules Zod Validators
 *
 * TODO: Auto-Claude 구현
 * - CreateRuleSchema: { name, preset_id, concepts (Record<string, {action, value}>), protect (string[]) }
 * - UpdateRuleSchema: { name?, concepts?, protect? }
 */

import { z } from 'zod';

export const CreateRuleSchema = z.object({
  name: z.string().min(1).max(100),
  preset_id: z.string().min(1),
  concepts: z.record(
    z.string(),
    z.object({
      action: z.string(),
      value: z.string(),
    })
  ),
  protect: z.array(z.string()),
});

export const UpdateRuleSchema = z.object({
  // TODO: define schema
});
