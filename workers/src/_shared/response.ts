/**
 * Response envelope helpers — 모든 API 응답은 { success, data, error, meta } 형식.
 * 원본: edge/src/utils/response.ts (재사용)
 */

import type { ApiResponse } from './types';

export function ok<T>(data: T): ApiResponse<T> {
  return {
    success: true,
    data,
    error: null,
    meta: {
      request_id: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
    },
  };
}

export function error(code: string, message: string): ApiResponse<null> {
  return {
    success: false,
    data: null,
    error: { code, message },
    meta: {
      request_id: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
    },
  };
}
