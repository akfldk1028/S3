import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/image_service.dart';
import 'workspace_state.dart';

part 'workspace_provider.g.dart';

/// 대용량 배치 경고 임계값 (이미지 50개 이상)
const int _largeBatchThreshold = 50;

/// 청크 업로드 크기 (이미지 10개씩 병렬 업로드)
const int _uploadChunkSize = 10;

@riverpod
class Workspace extends _$Workspace {
  @override
  WorkspaceState build() {
    return const WorkspaceState();
  }

  // ─────────────────────────────────────────────
  // 이미지 선택 — 지연 로딩 (썸네일만 즉시 생성)
  // ─────────────────────────────────────────────

  /// 이미지 선택 후 200px 썸네일만 즉시 생성 (full bytes 메모리 상주 금지)
  ///
  /// - 각 이미지에 대해 bytes를 1회만 읽고 [ImageService.generateThumbnail]로
  ///   200px 썸네일 생성 후 즉시 폐기 (GC 허용)
  /// - [SelectedImage.thumbnail]에 썸네일만 보관
  /// - 원본 bytes는 업로드 시점에 [SelectedImage.readBytesForUpload]로 on-demand 로드
  /// - 선택 총 수가 [_largeBatchThreshold](50) 이상이면
  ///   [WorkspaceState.showLargeBatchWarning]을 true로 설정
  Future<void> addPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    // 50개 이상이면 대용량 배치 경고 설정 — 경고 표시 후 계속 진행 (UI에서 dismiss 처리)
    if (images.length >= _largeBatchThreshold) {
      state = state.copyWith(showLargeBatchWarning: true);
    }

    // 썸네일만 즉시 생성 (full bytes 절대 상주 X)
    final selected = <SelectedImage>[];
    for (final img in images) {
      try {
        // bytes를 1회만 읽어 썸네일 생성 후 즉시 scope 이탈 (GC 대상)
        final bytes = await img.readAsBytes();
        final thumbnail = await ImageService.generateThumbnail(bytes);
        selected.add(SelectedImage(
          file: img,
          thumbnail: thumbnail,
          name: img.name,
        ));
      } catch (_) {
        // 썸네일 생성 실패 시 빈 Uint8List 사용 (그리드에서 placeholder 표시)
        selected.add(SelectedImage(
          file: img,
          thumbnail: Uint8List(0),
          name: img.name,
        ));
      }
    }

    // 전체 이미지 수 기준으로 대용량 배치 경고 여부 최종 결정
    final totalCount = state.selectedImages.length + selected.length;

    state = state.copyWith(
      selectedImages: [...state.selectedImages, ...selected],
      phase: WorkspacePhase.photosSelected,
      showLargeBatchWarning: totalCount >= _largeBatchThreshold,
      errorMessage: null,
    );
  }

  // ─────────────────────────────────────────────
  // 업로드 & 처리
  // ─────────────────────────────────────────────

  /// presigned URL 목록으로 이미지를 청크 단위로 업로드 후 처리 단계로 전환
  ///
  /// - [presignedUrls] : Job 생성 시 서버가 반환한 S3 presigned PUT URL 목록
  ///   (selectedImages와 동일 순서, 동일 길이여야 함)
  /// - 업로드 상태로 전환 후 [_uploadChunked] 호출
  /// - 완료 시 [WorkspacePhase.processing] 전환
  /// - 실패 시 [WorkspacePhase.error] 전환 및 errorMessage 설정
  Future<void> uploadAndProcess(List<String> presignedUrls) async {
    state = state.copyWith(
      phase: WorkspacePhase.uploading,
      uploadProgress: 0.0,
      errorMessage: null,
    );

    try {
      await _uploadChunked(presignedUrls);
    } catch (e) {
      state = state.copyWith(
        phase: WorkspacePhase.error,
        errorMessage: e.toString(),
      );
      return;
    }

    state = state.copyWith(
      phase: WorkspacePhase.processing,
      uploadProgress: 1.0,
    );
  }

  /// 10개씩 청크 분할 후 청크 내 이미지를 병렬 업로드 — 청크 완료 시 진행률 갱신
  ///
  /// - dart:math min()으로 마지막 청크 경계 안전 처리
  /// - Future.wait으로 청크 내 병렬 업로드
  /// - 각 청크 완료 후 [WorkspaceState.uploadProgress] 갱신
  Future<void> _uploadChunked(List<String> presignedUrls) async {
    final images = state.selectedImages;
    final total = images.length;

    // S3/R2 presigned URL 업로드 전용 Dio (절대 URL — baseUrl 불필요, 인증 헤더 불필요)
    final dio = Dio();

    for (var i = 0; i < total; i += _uploadChunkSize) {
      final end = math.min(i + _uploadChunkSize, total);
      final chunkImages = images.sublist(i, end);
      final chunkUrls = presignedUrls.sublist(i, end);

      await Future.wait([
        for (var j = 0; j < chunkImages.length; j++)
          _uploadOne(dio, chunkImages[j], chunkUrls[j]),
      ]);

      state = state.copyWith(uploadProgress: end / total);
    }
  }

  /// 단일 이미지 on-demand 로드 → 압축 → presigned URL로 PUT 업로드
  ///
  /// - [image.readBytesForUpload]로 전체 bytes on-demand 로드
  /// - [ImageService.compressIfNeeded]로 2MB 이상 이미지 압축
  /// - Content-Length 헤더를 압축된 bytes 크기로 명시
  /// - 반환된 bytes는 메서드 종료 시 scope 이탈 (GC 허용)
  Future<void> _uploadOne(
    Dio dio,
    SelectedImage image,
    String presignedUrl,
  ) async {
    final bytes = await image.readBytesForUpload();
    final compressed = await ImageService.compressIfNeeded(bytes, image.name);

    await dio.put<void>(
      presignedUrl,
      data: compressed,
      options: Options(
        headers: {'Content-Length': compressed.lengthInBytes},
        contentType: 'application/octet-stream',
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 상태 조작 메서드
  // ─────────────────────────────────────────────

  /// 선택된 이미지 전체 초기화 — 워크스페이스 리셋
  void clearPhotos() {
    state = state.copyWith(
      selectedImages: [],
      phase: WorkspacePhase.idle,
      showLargeBatchWarning: false,
      errorMessage: null,
      uploadProgress: 0.0,
      activeJob: null,
    );
  }

  /// 대용량 배치 경고 해제 (UI dismiss 버튼에서 호출)
  void dismissLargeBatchWarning() {
    state = state.copyWith(showLargeBatchWarning: false);
  }

  /// 오류 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
