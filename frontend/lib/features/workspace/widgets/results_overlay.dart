import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/job_item.dart';
import '../../../shared/widgets/before_after_slider.dart';
import '../theme.dart';
import '../workspace_provider.dart';

/// Full-screen overlay that displays a 3-column grid of processed result
/// thumbnails. Tapping a tile opens a fullscreen Before/After comparison dialog.
class ResultsOverlay extends ConsumerWidget {
  const ResultsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(workspaceProvider).activeJob;
    final items = job?.outputsReady ?? const [];

    return Scaffold(
      backgroundColor: WsColors.bg,
      appBar: AppBar(
        backgroundColor: WsColors.surface,
        elevation: 0,
        title: Text(
          '${items.length} Results',
          style: const TextStyle(
            color: WsColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: WsColors.textSecondary),
            onPressed: () => _export(items),
            tooltip: 'Share all',
          ),
        ],
        iconTheme: const IconThemeData(color: WsColors.textSecondary),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'No results yet.',
                style: TextStyle(color: WsColors.textMuted, fontSize: 14),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () => _showFullImage(context, ref, item),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail preview image.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                        child: Image.network(
                          item.previewUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: WsColors.surfaceLight,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: WsColors.accent1,
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (ctx, err, st) => Container(
                            color: WsColors.surfaceLight,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: WsColors.textMuted,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      // Index badge — bottom-left.
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: WsColors.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${item.idx}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: WsColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Opens a fullscreen Before/After comparison dialog for [item].
  ///
  /// Reads the original image bytes from [workspaceProvider].selectedImages
  /// using [item.idx] (1-based) → selectedImages[idx - 1].bytes.
  /// Shows a fallback single-image view if the bytes are unavailable.
  void _showFullImage(BuildContext context, WidgetRef ref, JobItem item) {
    final selectedImages = ref.read(workspaceProvider).selectedImages;

    final Uint8List? beforeBytes;
    if (item.idx >= 1 && item.idx <= selectedImages.length) {
      beforeBytes = selectedImages[item.idx - 1].bytes;
    } else {
      beforeBytes = null;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: SafeArea(
          child: Column(
            children: [
              // ── Dialog header ─────────────────────────────────────────
              Container(
                height: 56,
                color: WsColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      'Item #${item.idx}',
                      style: const TextStyle(
                        color: WsColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Per-item share button.
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 18,
                        color: WsColors.textSecondary,
                      ),
                      onPressed: () => Share.share(item.resultUrl),
                      tooltip: 'Share',
                    ),
                    // Close button.
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: WsColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // ── Slider or fallback image ───────────────────────────────
              Expanded(
                child: beforeBytes != null
                    ? BeforeAfterSlider(
                        beforeBytes: beforeBytes,
                        afterUrl: item.resultUrl,
                      )
                    : Image.network(
                        item.resultUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: WsColors.surfaceLight,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: WsColors.accent1,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) => Container(
                          color: WsColors.surfaceLight,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: WsColors.textMuted,
                            size: 48,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shares all result URLs as a single concatenated string.
  void _export(List<JobItem> items) {
    if (items.isEmpty) return;
    final urls = items.map((e) => e.resultUrl).join('\n');
    Share.share(urls);
  }
}
