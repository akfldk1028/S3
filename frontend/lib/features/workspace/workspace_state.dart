import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/job.dart';

part 'workspace_state.freezed.dart';

enum WorkspacePhase { idle, photosSelected, uploading, processing, done, error }

@freezed
abstract class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    @Default(WorkspacePhase.idle) WorkspacePhase phase,
    String? selectedPresetId,
    @Default([]) List<SelectedImage> selectedImages,
    String? activeJobId,
    @Default(0.0) double uploadProgress,
    Job? activeJob,
    String? selectedRuleId,
    String? errorMessage,
  }) = _WorkspaceState;
}

class SelectedImage {
  final XFile file;
  final Uint8List bytes;
  final String name;

  const SelectedImage({
    required this.file,
    required this.bytes,
    required this.name,
  });
}
