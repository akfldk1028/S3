import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 이미지 압축 파이프라인 + 썸네일 생성 유틸리티
///
/// - compressIfNeeded: 업로드 직전 압축 (2MB 이상만 처리)
/// - generateThumbnail: 그리드 표시용 200px 썸네일 생성
///
/// [주의] compressWithList 사용 (compressWithFile 금지 — 크로스플랫폼 불안정)
/// [주의] PNG + iOS에서는 quality 파라미터가 무시됨 (PNG lossless — 예상 동작)
class ImageService {
  ImageService._();

  static const int _compressionThresholdBytes = 2 * 1024 * 1024; // 2MB
  static const int _compressionQuality = 80;
  static const int _thumbnailSize = 200;
  static const int _maxUploadWidth = 1920;
  static const int _maxUploadHeight = 1920;

  /// 업로드 직전 압축 — 2MB 이상인 경우에만 처리
  ///
  /// [bytes] 원본 이미지 바이트
  /// [filename] 파일명 (확장자 기반 포맷 식별용)
  ///
  /// 2MB 미만이면 [bytes]를 그대로 반환하고,
  /// 2MB 이상이면 1920×1920, quality 80으로 압축 후 반환.
  static Future<Uint8List> compressIfNeeded(
    Uint8List bytes,
    String filename,
  ) async {
    if (bytes.lengthInBytes < _compressionThresholdBytes) return bytes;
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: _maxUploadWidth,
      minHeight: _maxUploadHeight,
      quality: _compressionQuality,
    );
    return compressed;
  }

  /// 200px 썸네일 생성 — 그리드 표시용
  ///
  /// [bytes] 원본 이미지 바이트
  ///
  /// minWidth/minHeight 200px으로 다운스케일. 업스케일 없음.
  static Future<Uint8List> generateThumbnail(Uint8List bytes) async {
    final thumbnail = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: _thumbnailSize,
      minHeight: _thumbnailSize,
      quality: _compressionQuality,
    );
    return thumbnail;
  }
}
