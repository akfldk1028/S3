import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'workspace_state.freezed.dart';

// ─────────────────────────────────────────────
// SelectedImage — plain Dart class (NOT Freezed)
// ─────────────────────────────────────────────

/// 선택된 이미지 — XFile 참조 + 200px 썸네일만 보유
///
/// - [thumbnail]: 그리드 표시용 200px 압축 이미지 (즉시 생성)
/// - [readBytesForUpload]: 업로드 시점에만 전체 bytes 로드 (지연 로딩)
///
/// full Uint8List bytes는 이 클래스에 절대 저장하지 않는다.
/// 원본은 업로드 루프 내에서만 [readBytesForUpload]로 on-demand 로드한다.
class SelectedImage {
  final XFile file;
  final Uint8List thumbnail; // 200px 썸네일만 즉시 보유
  final String name;

  const SelectedImage({
    required this.file,
    required this.thumbnail,
    required this.name,
  });

  /// 업로드 시점에만 전체 bytes 로드 (on-demand)
  ///
  /// 이 메서드를 upload loop 외부에서 호출하지 말 것.
  /// 반환된 Uint8List는 압축 후 즉시 scope를 벗어나야 한다 (GC 허용).
  Future<Uint8List> readBytesForUpload() => file.readAsBytes();
}

// ─────────────────────────────────────────────
// WorkspacePhase — 작업 단계 상태 머신
// ─────────────────────────────────────────────

/// 워크스페이스 작업 단계
enum WorkspacePhase {
  /// 초기 상태 — 이미지 미선택
  idle,

  /// 이미지 선택 완료 — 업로드 전
  photosSelected,

  /// S3/R2 업로드 진행 중
  uploading,

  /// GPU 처리 대기/진행 중
  processing,

  /// 작업 완료 — 결과 표시 가능
  completed,

  /// 오류 발생
  error,
}

// ─────────────────────────────────────────────
// JobResultItem — 개별 결과 이미지 항목
// ─────────────────────────────────────────────

/// 작업 결과의 개별 이미지 항목
class JobResultItem {
  final int idx;
  final String previewUrl;
  final String resultUrl;

  const JobResultItem({
    required this.idx,
    required this.previewUrl,
    required this.resultUrl,
  });

  factory JobResultItem.fromJson(Map<String, dynamic> json) {
    return JobResultItem(
      idx: json['idx'] as int,
      previewUrl: json['previewUrl'] as String,
      resultUrl: json['resultUrl'] as String,
    );
  }
}

// ─────────────────────────────────────────────
// JobResult — 완료된 작업 결과
// ─────────────────────────────────────────────

/// 완료된 작업 결과 (ID + 결과 이미지 목록)
class JobResult {
  final String id;
  final List<JobResultItem> items;
  final String? presetName;

  const JobResult({
    required this.id,
    required this.items,
    this.presetName,
  });

  factory JobResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return JobResult(
      id: json['id'] as String,
      items: rawItems
          .map((e) => JobResultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      presetName: json['presetName'] as String?,
    );
  }
}

// ─────────────────────────────────────────────
// WorkspaceState — Riverpod Freezed 상태
// ─────────────────────────────────────────────

/// 워크스페이스 Riverpod 상태 (불변 Freezed 클래스)
///
/// - [selectedImages]: 선택된 이미지 목록 (thumbnail만 보유, full bytes 없음)
/// - [phase]: 현재 작업 단계
/// - [showLargeBatchWarning]: 50개 이상 선택 시 경고 표시 여부
/// - [errorMessage]: 오류 메시지 (없으면 null)
/// - [uploadProgress]: 업로드 진행률 (0.0 ~ 1.0)
/// - [activeJob]: 완료된 작업 결과 (처리 전/중에는 null)
@freezed
abstract class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    @Default([]) List<SelectedImage> selectedImages,
    @Default(WorkspacePhase.idle) WorkspacePhase phase,
    @Default(false) bool showLargeBatchWarning,
    String? errorMessage,
    @Default(0.0) double uploadProgress,
    JobResult? activeJob,
  }) = _WorkspaceState;
}
