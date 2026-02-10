/**
 * Vast.ai Backend proxy — forwards requests to GPU inference server.
 */

import type { Env } from '../types';

export async function proxyToBackend(
  env: Env,
  path: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const url = `${env.VASTAI_BACKEND_URL}${path}`;

  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': env.API_SECRET_KEY,
    },
    body: JSON.stringify(body),
  });
}

export async function checkBackendHealth(env: Env): Promise<boolean> {
  try {
    const response = await fetch(`${env.VASTAI_BACKEND_URL}/health`);
    const data = (await response.json()) as { status: string };
    return data.status === 'ok';
  } catch {
    return false;
  }
}
