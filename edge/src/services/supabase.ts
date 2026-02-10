/**
 * Supabase REST API client for Edge Worker.
 *
 * Edge가 모든 CRUD를 담당한다 (anon key + JWT).
 * Backend는 추론 완료 시 service_role로 결과만 업데이트.
 */

import type { Env, TaskStatus } from '../types';

/** Supabase REST API 호출 헬퍼 */
async function supabaseRequest(
  env: Env,
  path: string,
  options: {
    method?: string;
    body?: unknown;
    jwt?: string;
    headers?: Record<string, string>;
  } = {},
): Promise<Response> {
  const { method = 'GET', body, jwt, headers = {} } = options;

  return fetch(`${env.SUPABASE_URL}/rest/v1/${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      apikey: env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${jwt ?? env.SUPABASE_ANON_KEY}`,
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
}

/** 유저 크레딧 조회 */
export async function getUserCredits(
  env: Env,
  userId: string,
  jwt: string,
): Promise<{ credits: number; tier: string } | null> {
  const res = await supabaseRequest(
    env,
    `users_profile?id=eq.${userId}&select=credits,tier`,
    { jwt, headers: { Accept: 'application/vnd.pgrst.object+json' } },
  );
  if (!res.ok) return null;
  return (await res.json()) as { credits: number; tier: string };
}

/** segmentation_results INSERT (status: pending) */
export async function createSegmentationResult(
  env: Env,
  jwt: string,
  data: {
    id: string;
    user_id: string;
    project_id?: string;
    source_image_url: string;
    text_prompt: string;
  },
): Promise<boolean> {
  const res = await supabaseRequest(env, 'segmentation_results', {
    method: 'POST',
    jwt,
    body: { ...data, status: 'pending' },
    headers: { Prefer: 'return=minimal' },
  });
  return res.ok;
}

/** segmentation_results 단일 조회 (by id) */
export async function getSegmentationResult(
  env: Env,
  resultId: string,
  jwt: string,
): Promise<Record<string, unknown> | null> {
  const res = await supabaseRequest(
    env,
    `segmentation_results?id=eq.${resultId}&select=*`,
    { jwt, headers: { Accept: 'application/vnd.pgrst.object+json' } },
  );
  if (!res.ok) return null;
  return (await res.json()) as Record<string, unknown>;
}

/** segmentation_results 목록 조회 (user_id 기반, pagination) */
export async function listSegmentationResults(
  env: Env,
  jwt: string,
  params: {
    userId: string;
    projectId?: string;
    page: number;
    limit: number;
  },
): Promise<{ results: Record<string, unknown>[]; total: number }> {
  const offset = (params.page - 1) * params.limit;
  let filter = `user_id=eq.${params.userId}`;
  if (params.projectId) {
    filter += `&project_id=eq.${params.projectId}`;
  }

  const res = await supabaseRequest(
    env,
    `segmentation_results?${filter}&select=*&order=created_at.desc&offset=${offset}&limit=${params.limit}`,
    {
      jwt,
      headers: {
        Prefer: 'count=exact',
      },
    },
  );

  if (!res.ok) return { results: [], total: 0 };

  const total = parseInt(res.headers.get('content-range')?.split('/')[1] ?? '0', 10);
  const results = (await res.json()) as Record<string, unknown>[];
  return { results, total };
}

/** usage_logs INSERT */
export async function logUsage(
  env: Env,
  jwt: string,
  data: {
    user_id: string;
    action: 'segmentation' | 'upload';
    credits_used: number;
    metadata?: Record<string, unknown>;
  },
): Promise<boolean> {
  const res = await supabaseRequest(env, 'usage_logs', {
    method: 'POST',
    jwt,
    body: data,
    headers: { Prefer: 'return=minimal' },
  });
  return res.ok;
}
