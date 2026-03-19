import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
            // 상단 바: 닫기 + 공유
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white70),
                    tooltip: '공유',
                    onPressed: () => _shareImage(item.resultUrl),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
            // 체커보드 배경 위에 이미지
            Flexible(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 체커보드 (투명 PNG 배경)
                  const SizedBox.expand(
                    child: CustomPaint(painter: _CheckerboardPainter()),
                  ),
                  CachedNetworkImage(
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
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// URL을 공유 시트로 전달한다.
  ///
  /// share_plus v10+: ShareParams 사용.
  void _shareImage(String url) {
    SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 체커보드 배경 (투명 PNG 대비)
                        const CustomPaint(painter: _CheckerboardPainter()),
                        CachedNetworkImage(
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 투명 PNG를 위한 체커보드 배경 페인터.
///
/// 포토샵 스타일 밝은/어두운 회색 격자를 그린다.
/// SAM3 누끼 결과(투명 PNG)가 배경과 구분되도록 한다.
class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter();

  static const _light = Color(0xFFCCCCCC);
  static const _dark = Color(0xFF999999);
  static const _size = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = _light;
    final darkPaint = Paint()..color = _dark;

    final cols = (size.width / _size).ceil();
    final rows = (size.height / _size).ceil();

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final paint = (r + c).isEven ? lightPaint : darkPaint;
        canvas.drawRect(
          Rect.fromLTWH(c * _size, r * _size, _size, _size),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerboardPainter old) => false;
}
