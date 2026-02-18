/**
 * Rules Zod Validators
 */

import { z } from 'zod';

const ConceptEntrySchema = z.object({
  action: z.string(),
  value: z.string(),
});

export const CreateRuleSchema = z.object({
  name: z.string().min(1),
  preset_id: z.string().min(1),
  concepts: z.record(z.string(), ConceptEntrySchema),
  protect: z.array(z.string()).optional().default([]),
});

export const UpdateRuleSchema = z.object({
  name: z.string().min(1).optional(),
  concepts: z.record(z.string(), ConceptEntrySchema).optional(),
  protect: z.array(z.string()).optional(),
});
