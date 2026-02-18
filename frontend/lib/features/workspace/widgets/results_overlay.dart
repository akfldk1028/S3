import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../workspace_provider.dart';
import '../workspace_state.dart';

/// 작업 결과 이미지를 오버레이 형태로 표시하는 위젯
///
/// workspaceProvider의 activeJob에서 결과 이미지 목록을 읽어 그리드로 표시한다.
class ResultsOverlay extends ConsumerWidget {
  const ResultsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final job = ws.activeJob;

    if (job == null || job.items.isEmpty) {
      return const Center(
        child: Text('결과 이미지가 없습니다.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: job.items.length,
      itemBuilder: (context, index) {
        final item = job.items[index];
        return _ResultTile(
          item: item,
          jobId: job.id,
          onTap: () => _showFullImage(context, job, item),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, JobResult job, JobResultItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Flexible(
              child: CachedNetworkImage(
                imageUrl: item.resultUrl,
                cacheKey: 'result_full_${job.id}_${item.idx}',
                fit: BoxFit.contain,
                placeholder: (ctx, url) => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (ctx, url, e) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.item,
    required this.jobId,
    required this.onTap,
  });

  final JobResultItem item;
  final String jobId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: item.previewUrl,
          cacheKey: 'result_${jobId}_${item.idx}',
          fit: BoxFit.cover,
          placeholder: (ctx, url) => const ColoredBox(
            color: Color(0xFFE0E0E0),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (ctx, url, e) => const ColoredBox(
            color: Color(0xFFE0E0E0),
            child: Center(
              child: Icon(Icons.broken_image, color: Color(0xFF9E9E9E)),
            ),
          ),
        ),
      ),
    );
  }
}
