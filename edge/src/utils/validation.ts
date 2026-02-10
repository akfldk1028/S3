/**
 * Request validation helpers.
 */

/** 허용된 이미지 MIME types */
export const ALLOWED_IMAGE_TYPES = ['image/png', 'image/jpeg', 'image/webp'];

/** 최대 파일 크기 (10MB) */
export const MAX_FILE_SIZE = 10 * 1024 * 1024;

/** 파일 유효성 검증 결과 */
export type ValidationResult =
  | { valid: true }
  | { valid: false; code: string; message: string; status: number };

/** 업로드 파일 검증 */
export function validateUploadFile(file: File | null): ValidationResult {
  if (!file) {
    return { valid: false, code: 'INVALID_REQUEST', message: 'File is required', status: 400 };
  }

  if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
    return {
      valid: false,
      code: 'INVALID_REQUEST',
      message: `Unsupported file type: ${file.type}. Allowed: ${ALLOWED_IMAGE_TYPES.join(', ')}`,
      status: 400,
    };
  }

  if (file.size > MAX_FILE_SIZE) {
    return {
      valid: false,
      code: 'FILE_TOO_LARGE',
      message: `File size ${(file.size / 1024 / 1024).toFixed(1)}MB exceeds limit of 10MB`,
      status: 413,
    };
  }

  return { valid: true };
}

/** 세그멘테이션 요청 검증 */
export function validateSegmentRequest(body: {
  image_url?: string;
  text_prompt?: string;
}): ValidationResult {
  if (!body.image_url) {
    return { valid: false, code: 'INVALID_REQUEST', message: 'image_url is required', status: 400 };
  }
  if (!body.text_prompt) {
    return {
      valid: false,
      code: 'INVALID_REQUEST',
      message: 'text_prompt is required',
      status: 400,
    };
  }
  return { valid: true };
}
