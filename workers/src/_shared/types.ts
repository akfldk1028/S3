/**
 * S3 Workers — 전체 타입 SSoT
 *
 * 모든 모듈이 이 파일에서 타입을 import한다.
 * workflow.md 섹션 3-7 기준.
 */

// ─── Cloudflare 바인딩 ───────────────────────────────────
export type Env = {
  DB: D1Database;
  R2: R2Bucket;
  USER_LIMITER: DurableObjectNamespace;
  JOB_COORDINATOR: DurableObjectNamespace;
  GPU_QUEUE: Queue<GpuQueueMessage>;
  JWT_SECRET: string;
  GPU_CALLBACK_SECRET: string;
};

// ─── Auth ────────────────────────────────────────────────
export type JwtPayload = {
  sub: string;       // user_id
  iat: number;
  exp: number;
  // plan은 JWT에 넣지 않음 — UserLimiterDO가 Source of Truth
};

export type AuthUser = {
  userId: string;
  // plan은 DO에서 조회 — JWT에 넣지 않으므로 AuthUser에도 불필요
};

// ─── Plan Limits ─────────────────────────────────────────
export const PLAN_LIMITS = {
  free: { maxConcurrency: 1, maxRuleSlots: 2, maxItems: 10, initialCredits: 10 },
  pro:  { maxConcurrency: 3, maxRuleSlots: 20, maxItems: 200, initialCredits: 200 },
} as const;

// ─── Job FSM ─────────────────────────────────────────────
export type JobStatus = 'created' | 'uploaded' | 'queued' | 'running' | 'done' | 'failed' | 'canceled';

// ─── DO States ───────────────────────────────────────────
export type UserLimiterState = {
  userId: string;
  plan: 'free' | 'pro';
  credits: number;
  activeJobs: number;
  maxConcurrency: number;
  ruleSlots: number;
  maxRuleSlots: number;
};

export type JobCoordinatorState = {
  jobId: string;
  userId: string;
  status: JobStatus;
  preset: string;
  conceptsJson: string;
  protectJson: string;
  ruleId: string | null;
  totalItems: number;
  doneItems: number;
  failedItems: number;
};

export type JobItemState = {
  idx: number;
  status: 'pending' | 'done' | 'failed';
  inputKey: string;
  outputKey: string | null;
  previewKey: string | null;
  error?: string;
};

// ─── Queue Message ───────────────────────────────────────
export type GpuQueueMessage = {
  job_id: string;
  user_id: string;
  preset: string;
  concepts: Record<string, { action: string; value: string }>;
  protect: string[];
  items: Array<{
    idx: number;
    input_key: string;
    output_key: string;
    preview_key: string;
  }>;
  callback_url: string;
  idempotency_prefix: string;
  batch_concurrency: number;
};

// ─── Callback ────────────────────────────────────────────
export type CallbackPayload = {
  idx: number;
  status: 'done' | 'failed';
  output_key?: string;
  preview_key?: string;
  error?: string;
  idempotency_key: string;
};

// ─── API Response Envelope ───────────────────────────────
export type ApiResponse<T> = {
  success: boolean;
  data: T | null;
  error: { code: string; message: string } | null;
  meta: { request_id: string; timestamp: string };
};

// ─── Preset ──────────────────────────────────────────────
export type Preset = {
  id: string;
  name: string;
  concepts: string[];
  protect_defaults: string[];
  output_templates: Array<{ id: string; name: string; description: string }>;
};

// ─── Billing ────────────────────────────────────────────
export type BillingEvent = {
  id: string;
  user_id: string;
  type: 'reserve' | 'commit' | 'rollback' | 'refund';
  amount: number;
  ref: string;           // job_id 등 참조
  created_at: string;
};

// ─── Rule ────────────────────────────────────────────────
export type Rule = {
  id: string;
  user_id: string;
  name: string;
  preset_id: string;
  concepts_json: string;
  protect_json: string | null;
  created_at: string;
  updated_at: string | null;
};
