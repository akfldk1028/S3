/**
 * TypeScript type definitions for the Edge Worker.
 */

/** Cloudflare Worker environment bindings */
export type Env = {
  // Secrets
  VASTAI_BACKEND_URL: string;
  API_SECRET_KEY: string;
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;

  // R2 Bucket binding
  R2: R2Bucket;
};

/** Auth verification result — set on Hono context via middleware */
export type AuthUser = {
  userId: string;
  tier: 'free' | 'pro' | 'enterprise';
  jwt: string; // Raw JWT token (Supabase REST API 호출 시 사용)
};

/** Standard API response envelope */
export type ApiResponse<T> = {
  success: boolean;
  data: T | null;
  error: { code: string; message: string } | null;
  meta: {
    request_id: string;
    timestamp: string;
  };
};

/** Task status */
export type TaskStatus = 'pending' | 'processing' | 'done' | 'error';

/** Supabase segmentation_results row */
export type SegmentationResultRow = {
  id: string;
  user_id: string;
  project_id: string | null;
  source_image_url: string;
  mask_image_url: string | null;
  text_prompt: string;
  status: TaskStatus;
  labels: string[] | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
};
