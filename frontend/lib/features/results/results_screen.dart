import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../workspace/workspace_state.dart';

/// 작업 결과 이미지를 전체 화면으로 표시하는 스크린
///
/// [job]의 결과 이미지 목록을 그리드로 표시하고, 각 항목을 탭하면
/// 전체 화면 다이얼로그로 원본 이미지([JobResultItem.resultUrl])를 표시한다.
///
/// [CachedNetworkImage]를 사용하여 이미지를 캐싱한다.
/// cacheKey는 stable ID(`result_{jobId}_{idx}`)를 사용하여 presigned URL
/// 만료 후에도 캐시 미스가 발생하지 않도록 한다.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.jobId,
    required this.job,
  });

  final String jobId;
  final JobResult job;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  /// 전체 이미지 다이얼로그 표시
  ///
  /// [item.resultUrl]을 [CachedNetworkImage]로 표시한다.
  /// cacheKey는 `'result_full_{jobId}_{item.idx}'` 형식의 stable ID를 사용한다.
  void _showFullImage(JobResultItem item) {
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
                cacheKey: 'result_full_${widget.jobId}_${item.idx}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.job.presetName ?? '결과'),
      ),
      body: widget.job.items.isEmpty
          ? const Center(
              child: Text('결과 이미지가 없습니다.'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: widget.job.items.length,
              itemBuilder: (context, index) {
                final item = widget.job.items[index];
                return GestureDetector(
                  onTap: () => _showFullImage(item),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: item.previewUrl,
                      cacheKey: 'result_${widget.jobId}_${item.idx}',
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
                          child: Icon(
                            Icons.broken_image,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
