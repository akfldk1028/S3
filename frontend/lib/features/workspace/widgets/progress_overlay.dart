import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/models/job_item.dart';
import '../../../shared/widgets/before_after_slider.dart';
import '../theme.dart';
import '../workspace_provider.dart';

/// Overlay displayed while a job is actively processing.
///
/// Shows a progress bar, job info, a cancel button, and a horizontal
/// thumbnail strip of any items that have already finished processing.
class ProgressOverlay extends ConsumerWidget {
  const ProgressOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(workspaceProvider).activeJob;

    if (job == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: WsColors.bg,
      body: SafeArea(
        child: _buildProgress(context, ref, job),
      ),
    );
  }

  /// Builds the main progress content area.
  Widget _buildProgress(BuildContext context, WidgetRef ref, Job job) {
    final progress = job.progress;
    final fraction =
        progress.total > 0 ? progress.done / progress.total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Job header ──────────────────────────────────────────────
          Text(
            job.preset,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WsColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.done} / ${progress.total}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WsColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // ── Progress bar ─────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: WsColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(WsColors.accent1),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(fraction * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WsColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),

          // ── Cancel button ────────────────────────────────────────────
          GestureDetector(
            onTap: () =>
                ref.read(workspaceProvider.notifier).cancelJob(),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: WsColors.surfaceLight,
                borderRadius: BorderRadius.circular(WsTheme.radius),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: WsColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ── Partial-results thumbnail strip ─────────────────────────
          if (job.outputsReady.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildThumbnailStrip(context, ref, job.outputsReady),
          ],
        ],
      ),
    );
  }

  /// Builds a horizontal 64 px thumbnail strip for [items] that are ready.
  Widget _buildThumbnailStrip(
    BuildContext context,
    WidgetRef ref,
    List<JobItem> items,
  ) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (ctx, i) => const SizedBox(width: 4),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _showItemPreview(ctx, ref, item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                item.previewUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) => Container(
                  width: 64,
                  height: 64,
                  color: WsColors.surfaceLight,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: WsColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Opens a fullscreen Before/After comparison dialog for [item].
  ///
  /// Reads original image bytes from [workspaceProvider].selectedImages
  /// using [item.idx] (1-based) → selectedImages[idx - 1].bytes.
  /// Falls back to a single-image view if bytes are unavailable.
  void _showItemPreview(
    BuildContext context,
    WidgetRef ref,
    JobItem item,
  ) {
    final selectedImages = ref.read(workspaceProvider).selectedImages;

    final Uint8List? beforeBytes;
    if (item.idx >= 1 && item.idx <= selectedImages.length) {
      beforeBytes = selectedImages[item.idx - 1].bytes;
    } else {
      beforeBytes = null;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: SafeArea(
          child: Column(
            children: [
              // ── Dialog header ───────────────────────────────────────
              Container(
                height: 56,
                color: WsColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      'Preview #${item.idx}',
                      style: const TextStyle(
                        color: WsColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
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

              // ── Slider or fallback image ────────────────────────────
              Expanded(
                child: beforeBytes != null
                    ? BeforeAfterSlider(
                        beforeBytes: beforeBytes,
                        afterUrl: item.previewUrl,
                      )
                    : Image.network(
                        item.previewUrl,
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
}
