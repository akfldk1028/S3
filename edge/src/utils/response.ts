/**
 * Response envelope helpers for consistent API responses.
 *
 * 모든 API 응답은 { success, data, error, meta } 형식을 따른다.
 */

import type { ApiResponse } from '../types';

/** 성공 응답 생성 */
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

/** 에러 응답 생성 */
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
