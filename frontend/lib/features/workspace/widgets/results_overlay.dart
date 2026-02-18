import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/models/job_item.dart';
import '../theme.dart';
import '../workspace_provider.dart';

class ResultsOverlay extends ConsumerWidget {
  const ResultsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(workspaceProvider).activeJob;
    if (job == null) return const SizedBox.shrink();

    final items = job.outputsReady;

    return Container(
      color: WsColors.bg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: WsColors.glassBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: WsColors.success, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${items.length} result${items.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: WsColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  GestureDetector(
                    onTap: () => _export(items),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: WsColors.glassWhite,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.share_rounded,
                          size: 16, color: WsColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),

          // Grid
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          WsColors.gradientPrimary.createShader(bounds),
                      child: const Icon(Icons.photo_library_outlined,
                          size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No results available',
                      style: TextStyle(fontSize: 13, color: WsColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(6),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () => _showFullImage(context, item),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
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
                        errorBuilder: (_, e, st) => Container(
                          color: WsColors.surfaceLight,
                          child: const Icon(Icons.broken_image_rounded,
                              color: WsColors.textMuted, size: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // New batch
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () =>
                    ref.read(workspaceProvider.notifier).resetToIdle(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: WsColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(WsTheme.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: WsColors.accent1.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'New Batch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, JobItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: WsColors.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WsTheme.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text('Item #${item.idx}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: WsColors.textPrimary,
                          fontSize: 13)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: WsColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(WsTheme.radiusLg),
                  bottomRight: Radius.circular(WsTheme.radiusLg),
                ),
                child: Image.network(
                  item.resultUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 300,
                      color: WsColors.surfaceLight,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WsColors.accent1,
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, e, st) => Container(
                    height: 300,
                    color: WsColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          size: 48, color: WsColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(List<JobItem> items) async {
    final urls = items.map((item) => item.resultUrl).join('\n');
    await Share.share('S3 Results (${items.length} images):\n$urls');
  }
}
