/**
 * Jobs Zod Validators
 */

import { z } from 'zod';

export const CreateJobSchema = z.object({
  preset: z.string().min(1),
  item_count: z.number().int().min(1).max(200),
});

export const ExecuteJobSchema = z.object({
  concepts: z.record(
    z.object({
      action: z.string(),
      value: z.string(),
    }),
  ),
  protect: z.array(z.string()).optional().default([]),
  rule_id: z.string().optional(),
});

export const CallbackSchema = z.object({
  idx: z.number().int().min(0),
  status: z.enum(['done', 'failed']),
  output_key: z.string().optional(),
  preview_key: z.string().optional(),
  error: z.string().optional(),
  idempotency_key: z.string().min(1),
});
