import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

/// Displays the grid of selected photos.
///
/// On an empty workspace, renders a full-screen photo-first empty state
/// (SNOW-style: tap anywhere to add photos).
/// Once photos are selected, shows a scrollable grid with add-more tile.
class PhotoGrid extends ConsumerWidget {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final images = ws.selectedImages;

    if (images.isEmpty) {
      return _EmptyState(
        onAdd: () {
          // Image picker integration handled in a future subtask.
          // For now this is a no-op stub.
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 3;

        return GridView.builder(
          padding: const EdgeInsets.all(6),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: images.length + 1,
          itemBuilder: (context, index) {
            if (index == images.length) {
              return _AddMoreTile(
                onTap: () {
                  // Image picker integration handled in a future subtask.
                },
              );
            }
            return _PhotoTile(
              imageBytes: images[index],
              index: index,
              onRemove: () =>
                  ref.read(workspaceProvider.notifier).removePhoto(index),
              uploading: ws.phase == WorkspacePhase.uploading,
              uploadProgress: ws.phase == WorkspacePhase.uploading
                  ? ws.uploadProgress
                  : null,
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Private widgets
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: WsColors.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    WsColors.gradientPrimary.createShader(bounds),
                child: const Text(
                  'S3',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.photo_library_rounded,
                  size: 48, color: WsColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Tap to add photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: WsColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select from gallery to start editing',
                style: TextStyle(
                  fontSize: 13,
                  color: WsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Uint8List imageBytes;
  final int index;
  final VoidCallback onRemove;
  final bool uploading;
  final double? uploadProgress;

  const _PhotoTile({
    required this.imageBytes,
    required this.index,
    required this.onRemove,
    required this.uploading,
    this.uploadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          if (uploading)
            Container(
              color: WsColors.bg.withValues(alpha: 0.6),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WsColors.accent1,
                    value: uploadProgress,
                  ),
                ),
              ),
            ),
          if (!uploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 12, color: Colors.white70),
                ),
              ),
            ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMoreTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: WsColors.glassBorder, width: 1),
          color: WsColors.glassWhite,
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                WsColors.gradientPrimary.createShader(bounds),
            child: const Icon(Icons.add_rounded,
                size: 28, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

