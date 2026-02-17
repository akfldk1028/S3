import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../workspace_state.dart';

/// 작업 결과 이미지를 오버레이 형태로 표시하는 위젯
///
/// [job]의 결과 이미지 목록을 그리드로 표시하고, 각 항목을 탭하면
/// 전체 화면 다이얼로그로 원본 이미지([JobResultItem.resultUrl])를 표시한다.
///
/// [CachedNetworkImage]를 사용하여 이미지를 캐싱한다.
/// cacheKey는 stable ID(`result_{jobId}_{idx}`)를 사용하여 presigned URL
/// 만료 후에도 캐시 미스가 발생하지 않도록 한다.
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay({
    super.key,
    required this.job,
  });

  final JobResult job;

  @override
  Widget build(BuildContext context) {
    if (job.items.isEmpty) {
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
          onTap: () => _showFullImage(context, item),
        );
      },
    );
  }

  /// 전체 이미지 다이얼로그 표시
  ///
  /// [item.resultUrl]을 [CachedNetworkImage]로 표시한다.
  /// cacheKey는 `'result_full_{jobId}_{item.idx}'` 형식의 stable ID를 사용한다.
  void _showFullImage(BuildContext context, JobResultItem item) {
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

/// 개별 결과 이미지 타일 — preview URL을 CachedNetworkImage로 표시
///
/// cacheKey는 `'result_{jobId}_{item.idx}'` 형식의 stable ID를 사용하여
/// presigned URL 만료와 무관하게 안정적인 캐싱을 보장한다.
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
