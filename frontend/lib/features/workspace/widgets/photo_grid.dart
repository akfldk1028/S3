import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

/// 선택된 이미지를 그리드 형태로 표시하는 위젯
///
/// workspaceProvider에서 selectedImages를 읽어와 표시한다.
/// 각 타일은 [SelectedImage.thumbnail] (200px 압축 이미지)을 표시한다.
/// full bytes는 절대 로드하지 않는다.
class PhotoGrid extends ConsumerWidget {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final images = ws.selectedImages;

    if (images.isEmpty) {
      return _EmptyState(onAddPhotos: notifier.addPhotos);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == images.length) {
          return _AddMoreTile(onTap: notifier.addPhotos);
        }
        return _PhotoTile(image: images[index]);
      },
    );
  }
}

/// 빈 상태 — 이미지 추가 안내
class _EmptyState extends StatelessWidget {
  final VoidCallback onAddPhotos;

  const _EmptyState({required this.onAddPhotos});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onAddPhotos,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: WsColors.glassWhite,
            borderRadius: BorderRadius.circular(WsTheme.radiusLg),
            border: Border.all(color: WsColors.glassBorder, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 56,
                color: WsColors.accent1.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Photos',
                style: TextStyle(
                  color: WsColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select images from your gallery\nor take a photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WsColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 추가 이미지 버튼 타일
class _AddMoreTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: WsColors.glassWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: WsColors.glassBorder, width: 0.5),
        ),
        child: const Center(
          child: Icon(Icons.add, color: WsColors.textMuted, size: 32),
        ),
      ),
    );
  }
}

/// 개별 이미지 타일 — thumbnail(200px)만 표시
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
