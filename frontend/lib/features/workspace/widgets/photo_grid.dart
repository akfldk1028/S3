import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

class PhotoGrid extends ConsumerWidget {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final images = ws.selectedImages;

    if (images.isEmpty) {
      return _PhotoFirstEmptyState(
        onAdd: () => ref.read(workspaceProvider.notifier).addPhotos(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;

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
                onTap: () => ref.read(workspaceProvider.notifier).addPhotos(),
              );
            }
            return _PhotoTile(
              image: images[index],
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

/// SNOW-like full-screen empty state — photo-first experience.
/// The entire screen is a tap target. Feels like opening a camera/gallery app.
class _PhotoFirstEmptyState extends StatefulWidget {
  final VoidCallback onAdd;

  const _PhotoFirstEmptyState({required this.onAdd});

  @override
  State<_PhotoFirstEmptyState> createState() => _PhotoFirstEmptyStateState();
}

class _PhotoFirstEmptyStateState extends State<_PhotoFirstEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 768;

    return GestureDetector(
      onTap: widget.onAdd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient gradient background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  WsColors.accent1.withValues(alpha: 0.08),
                  WsColors.bg,
                  WsColors.accent2.withValues(alpha: 0.04),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo + branding (SNOW-style)
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
                        height: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Domain Palette Engine',
                    style: TextStyle(
                      fontSize: 12,
                      color: WsColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),

                  SizedBox(height: isWide ? 56 : 44),

                  // Animated camera/gallery icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: isWide ? 120 : 100,
                        height: isWide ? 120 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              WsColors.accent1.withValues(
                                  alpha: 0.12 * _pulseAnimation.value),
                              WsColors.accent2.withValues(
                                  alpha: 0.12 * _pulseAnimation.value),
                            ],
                          ),
                          border: Border.all(
                            color: WsColors.accent1.withValues(
                                alpha: 0.25 * _pulseAnimation.value),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                WsColors.gradientPrimary.createShader(bounds),
                            child: Icon(
                              Icons.photo_library_rounded,
                              size: isWide ? 44 : 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Main CTA text
                  const Text(
                    'Tap to add your photos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: WsColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Select from gallery to start editing',
                    style: TextStyle(
                      fontSize: 14,
                      color: WsColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Gradient CTA button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: WsColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(WsTheme.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: WsColors.accent1.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 20, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Add Photos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Feature pills (subtle)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [
                      _FeaturePill(
                          icon: Icons.palette_outlined, label: 'Concepts'),
                      _FeaturePill(
                          icon: Icons.shield_outlined, label: 'Protect'),
                      _FeaturePill(
                          icon: Icons.auto_fix_high_rounded, label: 'Rules'),
                      _FeaturePill(
                          icon: Icons.collections_rounded, label: 'Sets'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small subtle pill showing a feature hint.
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: WsColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: WsColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final SelectedImage image;
  final int index;
  final VoidCallback onRemove;
  final bool uploading;
  final double? uploadProgress;

  const _PhotoTile({
    required this.image,
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
          Image.memory(image.bytes, fit: BoxFit.cover),
          // Dark vignette
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          // Upload overlay
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
          // Remove button
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
          // Index badge
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
          border: Border.all(
            color: WsColors.glassBorder,
            width: 1,
          ),
          color: WsColors.glassWhite,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  WsColors.gradientPrimary.createShader(bounds),
              child:
                  const Icon(Icons.add_rounded, size: 28, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
