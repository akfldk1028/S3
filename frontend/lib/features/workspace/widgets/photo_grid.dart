import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../../../shared/widgets/tap_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

/// A single photo item displayed in the workspace [PhotoGrid].
class PhotoItem {
  const PhotoItem({required this.id, required this.path});

  /// Unique identifier for this photo (used as a [ValueKey] in the grid).
  final String id;

  /// File path or remote URL pointing to the image.
  final String path;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Workspace photo grid.
///
/// When [photos] is empty, renders [_PhotoFirstEmptyState] — an animated
/// empty state with a floating camera icon and a "Add Photos" CTA button.
///
/// When [photos] is non-empty, renders a 3-column [GridView] of [_PhotoTile]s
/// followed by an [_AddMoreTile] at the end.
///
/// All interactive elements fire [HapticFeedback.lightImpact()] and are
/// wrapped with [TapScale] for a press-scale (1.0 → 0.95) micro-interaction.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.photos,
    this.onAddPhotos,
    this.onRemovePhoto,
  });

  /// Current list of photos in the workspace.
  final List<PhotoItem> photos;

  /// Called when the user taps the CTA (empty state) or the add-more tile.
  final VoidCallback? onAddPhotos;

  /// Called with the removed photo's [PhotoItem.id] when the user taps the
  /// remove button on a [_PhotoTile].
  final ValueChanged<String>? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return _PhotoFirstEmptyState(onAddPhotos: onAddPhotos);
    }
    return _buildGrid();
  }

  Widget _buildGrid() {
    // Photo tiles + 1 trailing "add more" tile.
    final itemCount = photos.length + 1;

    return GridView.builder(
      padding: const EdgeInsets.all(WsTheme.spacingLg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: WsTheme.spacingSm,
        mainAxisSpacing: WsTheme.spacingSm,
        childAspectRatio: 1.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == photos.length) {
          // Trailing add-more tile.
          return _AddMoreTile(onTap: onAddPhotos);
        }
        final photo = photos[index];
        return _PhotoTile(
          key: ValueKey(photo.id),
          photo: photo,
          onRemove: onRemovePhoto == null
              ? null
              : () => onRemovePhoto!(photo.id),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhotoFirstEmptyState  (StatefulWidget, L59 – L279 reference)
// ─────────────────────────────────────────────────────────────────────────────

/// Animated empty state shown in [PhotoGrid] when there are no photos.
///
/// A looping float [AnimationController] gently bobs the camera icon up and
/// down. Two ambient gradient orbs ([accent1] at 12 % and [accent2] at 8 %)
/// are layered behind the content.
///
/// The "Add Photos" CTA button (L221 – L252) is wrapped in [TapScale] and
/// fires [HapticFeedback.lightImpact()] before calling [onAddPhotos].
class _PhotoFirstEmptyState extends StatefulWidget {
  const _PhotoFirstEmptyState({this.onAddPhotos});

  final VoidCallback? onAddPhotos;

  @override
  State<_PhotoFirstEmptyState> createState() => _PhotoFirstEmptyStateState();
}

class _PhotoFirstEmptyStateState extends State<_PhotoFirstEmptyState>
    with SingleTickerProviderStateMixin {
  // Continuous float animation — bobs the icon ±8 px over 2 s.
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Ambient gradient orbs (L96 – L116) ─────────────────────────────
        // Orb 1 — top-left quadrant, accent1 at 12 % opacity.
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  WsColors.accent1.withValues(alpha: 0.12),
                  WsColors.accent1.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Orb 2 — bottom-right quadrant, accent2 at 8 % opacity.
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  WsColors.accent2.withValues(alpha: 0.08),
                  WsColors.accent2.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // ── Main content column ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: WsTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Floating camera icon — driven by _floatAnim.
              AnimatedBuilder(
                animation: _floatAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: WsColors.gradientDiagonal,
                    boxShadow: [
                      BoxShadow(
                        color: WsColors.accent1.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: WsColors.textPrimary,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: WsTheme.spacingXl),

              // Title.
              const Text(
                'No Photos Yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WsColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: WsTheme.spacingSm),

              // Subtitle.
              const Text(
                'Add photos to get started.\n'
                'Select up to 10 images for the workspace.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: WsColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: WsTheme.spacingXl),

              // ── CTA button (L221 – L252) ──────────────────────────────────
              // TapScale wraps the visible Container; HapticFeedback fires
              // first inside the onTap callback before calling onAddPhotos.
              TapScale(
                onTap: widget.onAddPhotos == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        widget.onAddPhotos!();
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WsTheme.spacingXl,
                    vertical: WsTheme.spacingLg,
                  ),
                  decoration: BoxDecoration(
                    gradient: WsColors.gradientPrimary,
                    borderRadius:
                        BorderRadius.circular(WsTheme.borderRadiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: WsColors.accent1.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: WsColors.textPrimary,
                        size: WsTheme.iconSize,
                      ),
                      SizedBox(width: WsTheme.spacingSm),
                      Text(
                        'Add Photos',
                        style: TextStyle(
                          color: WsColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhotoTile  (L281 – L388 reference)
// ─────────────────────────────────────────────────────────────────────────────

/// Single photo tile inside the [PhotoGrid] grid view.
///
/// Renders the image from [photo.path] in a rounded container. A small ✕
/// remove button is overlaid in the top-right corner; it is wrapped in
/// [TapScale] and fires [HapticFeedback.lightImpact()] on press.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    this.onRemove,
  });

  final PhotoItem photo;

  /// Called when the user taps the remove (✕) button.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WsTheme.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo image.
          Image.network(
            photo.path,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Container(
              color: WsColors.glassWhite,
              child: const Icon(
                Icons.broken_image_rounded,
                color: WsColors.textTertiary,
                size: 32,
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: WsColors.glassWhite,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WsColors.accent1,
                  ),
                ),
              );
            },
          ),

          // Gradient scrim at the top so the remove button is legible.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Remove button (L370 – L388) ────────────────────────────────
          // Positioned in the top-right corner. Wrapped in TapScale so the
          // ✕ icon scales 1.0 → 0.95 on press. HapticFeedback fires first.
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: TapScale(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onRemove!();
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: WsColors.textPrimary,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddMoreTile  (L389 – L447 reference)
// ─────────────────────────────────────────────────────────────────────────────

/// Trailing tile in the [PhotoGrid] for adding more photos.
///
/// The entire tile is wrapped in [TapScale] so the press-scale animation
/// covers the full tap area. [HapticFeedback.lightImpact()] fires as the
/// first action inside the [onTap] callback.
class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({this.onTap});

  /// Called when the user taps this tile. If null the tile is inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // TapScale wraps the AnimatedContainer — provides both the scale animation
    // and tap routing. HapticFeedback is fired inside the onTap closure.
    return TapScale(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      child: AnimatedContainer(
        duration: WsTheme.animFast,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: WsColors.glassWhite,
          borderRadius: BorderRadius.circular(WsTheme.borderRadius),
          border: Border.all(
            color: WsColors.glassBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: WsColors.gradientDiagonal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: WsColors.textPrimary,
                size: WsTheme.iconSizeLg,
              ),
            ),
            const SizedBox(height: WsTheme.spacingSm),
            const Text(
              'Add More',
              style: TextStyle(
                color: WsColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
