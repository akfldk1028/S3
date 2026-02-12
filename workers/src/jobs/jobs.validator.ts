/**
 * Jobs Zod Validators
 *
 * TODO: Auto-Claude 구현
 * - CreateJobSchema: { preset: string, item_count: number }
 * - ExecuteJobSchema: { concepts, protect, rule_id?, output_template? }
 * - CallbackSchema: { idx, status, output_key?, preview_key?, error?, idempotency_key }
 */

import { z } from 'zod';

export const CreateJobSchema = z.object({
  // TODO: define schema
});

export const ExecuteJobSchema = z.object({
  // TODO: define schema
});

export const CallbackSchema = z.object({
  // TODO: define schema
});
