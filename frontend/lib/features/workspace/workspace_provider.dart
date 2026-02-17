import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/image_service.dart';
import 'workspace_state.dart';

part 'workspace_provider.g.dart';

/// 대용량 배치 경고 임계값 (이미지 50개 이상)
const int _largeBatchThreshold = 50;

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
