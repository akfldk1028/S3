import 'dart:async';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/models/rule.dart';
import '../palette/palette_provider.dart';
import 'workspace_state.dart';

part 'workspace_provider.g.dart';

@riverpod
class Workspace extends _$Workspace {
  Timer? _pollTimer;
  bool _isPolling = false;
  int _pollFailures = 0;
  static const _maxPollFailures = 10;

  @override
  WorkspaceState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return const WorkspaceState();
  }

  void selectPreset(String presetId) {
    state = state.copyWith(
      selectedPresetId: presetId,
      errorMessage: null,
    );
  }

  Future<void> addPhotos() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isEmpty) return;

      final selected = <SelectedImage>[];
      for (final img in images) {
        final bytes = await img.readAsBytes();
        selected.add(SelectedImage(file: img, bytes: bytes, name: img.name));
      }

      state = state.copyWith(
        selectedImages: [...state.selectedImages, ...selected],
        phase: WorkspacePhase.photosSelected,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to select images: $e');
    }
  }

  void removePhoto(int index) {
    final images = List<SelectedImage>.from(state.selectedImages);
    images.removeAt(index);
    state = state.copyWith(
      selectedImages: images,
      phase: images.isEmpty ? WorkspacePhase.idle : WorkspacePhase.photosSelected,
    );
  }

  void selectRule(String? ruleId) {
    state = state.copyWith(selectedRuleId: ruleId);
  }

  Future<void> uploadAndProcess() async {
    if (state.selectedImages.isEmpty || state.selectedPresetId == null) {
      state = state.copyWith(errorMessage: 'Select photos and a domain first');
      return;
    }

    state = state.copyWith(
      phase: WorkspacePhase.uploading,
      uploadProgress: 0.0,
      errorMessage: null,
    );

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. POST /jobs
      final jobData = await apiClient.createJob(
        preset: state.selectedPresetId!,
        itemCount: state.selectedImages.length,
      );

      final jobId = jobData['jobId'] as String;
      final uploadUrls =
          (jobData['urls'] as List<dynamic>).cast<Map<String, dynamic>>();

      state = state.copyWith(activeJobId: jobId);

      // 2. Upload each image to R2 via presigned URLs
      final uploadDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
      ));
      try {
        for (int i = 0; i < state.selectedImages.length; i++) {
          final url = uploadUrls[i]['url'] as String;
          final image = state.selectedImages[i];

          await uploadDio.put(
            url,
            data: image.bytes,
            options: Options(
              headers: {
                'Content-Type': _mimeType(image.name),
                'Content-Length': image.bytes.length,
              },
              responseType: ResponseType.plain,
            ),
          );

          state = state.copyWith(
            uploadProgress: (i + 1) / state.selectedImages.length,
          );
        }
      } finally {
        uploadDio.close();
      }

      // 3. Confirm upload
      await apiClient.confirmUpload(jobId,
          totalItems: state.selectedImages.length);

      // 4. Execute with current palette state
      final paletteState = ref.read(paletteProvider);
      final concepts = <String, ConceptAction>{};
      for (final entry in paletteState.selectedConcepts.entries) {
        concepts[entry.key] = ConceptAction(action: 'recolor');
      }

      await apiClient.executeJob(
        jobId,
        concepts: concepts,
        protect: paletteState.protectConcepts.toList(),
        ruleId: state.selectedRuleId,
      );

      // 5. Start polling
      state = state.copyWith(phase: WorkspacePhase.processing);
      _startPolling(jobId);
    } catch (e) {
      state = state.copyWith(
        phase: WorkspacePhase.error,
        errorMessage: 'Processing failed: $e',
      );
    }
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _isPolling = false;
    _pollFailures = 0;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isPolling) return; // Guard against concurrent polls
      _isPolling = true;

      try {
        final apiClient = ref.read(apiClientProvider);
        final job = await apiClient.getJob(jobId);
        _pollFailures = 0; // Reset on success

        state = state.copyWith(activeJob: job);

        if (job.status == 'done') {
          _pollTimer?.cancel();
          state = state.copyWith(phase: WorkspacePhase.done);
        } else if (['failed', 'canceled'].contains(job.status)) {
          _pollTimer?.cancel();
          state = state.copyWith(
            phase: WorkspacePhase.error,
            errorMessage: 'Job ${job.status}',
          );
        }
      } catch (e) {
        _pollFailures++;
        if (_pollFailures >= _maxPollFailures) {
          _pollTimer?.cancel();
          state = state.copyWith(
            phase: WorkspacePhase.error,
            errorMessage: 'Lost connection to server',
          );
        }
      } finally {
        _isPolling = false;
      }
    });
  }

  Future<void> cancelJob() async {
    final jobId = state.activeJobId;
    if (jobId == null) return;

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.cancelJob(jobId);
      _pollTimer?.cancel();
      state = state.copyWith(
        phase: WorkspacePhase.idle,
        activeJobId: null,
        activeJob: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Cancel failed: $e');
    }
  }

  void resetToIdle() {
    _pollTimer?.cancel();
    state = const WorkspaceState();
    ref.read(paletteProvider.notifier).reset();
  }

  /// Detect MIME type from file extension.
  static String _mimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
