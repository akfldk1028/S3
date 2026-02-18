import 'package:flutter/material.dart';

import '../workspace_state.dart';

/// 선택된 이미지를 그리드 형태로 표시하는 위젯
///
/// 각 타일은 [SelectedImage.thumbnail] (200px 압축 이미지)을 표시한다.
/// full bytes는 절대 로드하지 않는다.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
  });

  final List<SelectedImage> images;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _PhotoTile(image: images[index]);
      },
    );
  }
}

/// 개별 이미지 타일 — thumbnail(200px)만 표시
///
/// [SelectedImage.thumbnail]은 non-nullable이므로 null 검사 불필요.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.image});

  final SelectedImage image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.memory(
        image.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(
            color: Color(0xFFE0E0E0),
            child: Center(
              child: Icon(Icons.broken_image, color: Color(0xFF9E9E9E)),
            ),
          );
        },
      ),
    );
  }
}
