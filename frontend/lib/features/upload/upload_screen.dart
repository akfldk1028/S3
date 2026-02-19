import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client_provider.dart';

/// Upload screen with image picker and R2 presigned upload.
///
/// Flow:
/// 1. User clicks "Select Images" → file picker opens
/// 2. Shows image previews after selection
/// 3. POST /jobs to get presigned upload URLs
/// 4. Mock: simulate upload delay, Real: Dio PUT to presigned URL
/// 5. POST /jobs/:id/confirm-upload after all uploads
/// 6. Navigate to /rules with jobId
///
/// The screen manages local state for selected images and upload progress.
class UploadScreen extends ConsumerStatefulWidget {
  final String? presetId;
  final String? conceptsJson;
  final String? protectJson;

  const UploadScreen({
    super.key,
    this.presetId,
    this.conceptsJson,
    this.protectJson,
  });

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  List<_SelectedImage> _selectedImages = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  /// Select images using image picker
  Future<void> _selectImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isEmpty) {
        return;
      }

      // Convert XFile to _SelectedImage with preview data
      final List<_SelectedImage> selectedImages = [];
      for (final XFile image in images) {
        final bytes = await image.readAsBytes();
        selectedImages.add(_SelectedImage(
          file: image,
          bytes: bytes,
          name: image.name,
        ));
      }

      setState(() {
        _selectedImages = selectedImages;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select images: $e';
      });
    }
  }

  /// Upload images and navigate to rules screen
  Future<void> _uploadAndConfirm() async {
    if (_selectedImages.isEmpty) {
      return;
    }

    if (widget.presetId == null || widget.presetId!.isEmpty) {
      setState(() {
        _errorMessage = 'No preset selected';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. POST /jobs to get presigned URLs
      final result = await apiClient.createJob({
        'preset': widget.presetId!,
        'item_count': _selectedImages.length,
      });

      final jobId = result.jobId;
      // result.presignedUrls available for real R2 upload (Phase 2)

      // 2. Mock upload simulation (300ms delay per image)
      // In Phase 2: Use Dio PUT to presigned URL with uploadUrls
      for (int i = 0; i < _selectedImages.length; i++) {
        // Simulate upload delay
        await Future.delayed(const Duration(milliseconds: 300));

        setState(() {
          _uploadProgress = (i + 1) / _selectedImages.length;
        });
      }

      // 3. POST /jobs/:id/confirm-upload to finalize
      await apiClient.confirmUpload(jobId);

      // 4. Navigate to rules screen with jobId
      if (!mounted) return;
      context.push('/rules?jobId=$jobId&presetId=${widget.presetId}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e';
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Images'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isUploading
              ? null
              : () {
                  context.pop();
                },
        ),
      ),
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      const Text(
                        'Upload Your Images',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select images to apply your palette concepts',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Select Images button
                      if (_selectedImages.isEmpty && !_isUploading) ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _selectImages,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Select Images'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Choose multiple images from your device',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Image previews
                      if (_selectedImages.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedImages.length} image(s) selected',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!_isUploading)
                              TextButton.icon(
                                onPressed: _selectImages,
                                icon: const Icon(Icons.edit),
                                label: const Text('Change'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return _ImagePreviewCard(
                              image: _selectedImages[index],
                              isUploading: _isUploading,
                            );
                          },
                        ),
                      ],

                      // Upload progress indicator
                      if (_isUploading) ...[
                        const SizedBox(height: 32),
                        Column(
                          children: [
                            const Text(
                              'Uploading images...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_uploadProgress * 100).toInt()}% complete',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom action bar
          if (_selectedImages.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Image count
                      Text(
                        '${_selectedImages.length} image(s)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      // Confirm button
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadAndConfirm,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(_isUploading ? 'Uploading...' : 'Confirm & Continue'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Model for selected image with preview data
class _SelectedImage {
  final XFile file;
  final Uint8List bytes;
  final String name;

  _SelectedImage({
    required this.file,
    required this.bytes,
    required this.name,
  });
}

/// Image preview card widget
class _ImagePreviewCard extends StatelessWidget {
  final _SelectedImage image;
  final bool isUploading;

  const _ImagePreviewCard({
    required this.image,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image preview
          Image.memory(
            image.bytes,
            fit: BoxFit.cover,
          ),
          // Upload overlay
          if (isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          // Image name tooltip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                image.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
