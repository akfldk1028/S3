import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job_item.dart';
import '../theme.dart';
import '../workspace_state.dart';

// ---------------------------------------------------------------------------
// ResultsOverlay
// ---------------------------------------------------------------------------

/// Full-screen gallery overlay that displays the AI-processed results for the
/// current batch job.
///
/// Uses a SNOW-inspired dark gradient background and glassmorphism design tokens
/// from [WsColors] / [WsTheme].
///
/// Layout:
/// ```
/// Container (SNOW gradient bg)
///   Stack
///     ├── Column
///     │   ├── SizedBox (header spacer)
///     │   ├── Expanded → _buildGrid (3-col thumbnail grid)
///     │   └── _buildNewBatchCTA (gradient button)
///     └── Positioned (top) → _buildGlassHeader (glassmorphism bar)
/// ```
class ResultsOverlay extends ConsumerStatefulWidget {
  const ResultsOverlay({super.key});

  @override
  ConsumerState<ResultsOverlay> createState() => _ResultsOverlayState();
}

class _ResultsOverlayState extends ConsumerState<ResultsOverlay> {
  static const double _headerHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(workspaceProvider);
    final items = wsState.items;

    return Material(
      color: Colors.transparent,
      child: Container(
        // SNOW-style vertical gradient background (top: deep navy → bottom:
        // slightly lighter dark).  Do NOT use a flat WsColors.bg colour here.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F17), // WsColors.bg — deep dark top
              Color(0xFF1A1A2E), // WsColors.surface — slightly lighter bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main content (behind the header) ──────────────────────────
              Column(
                children: [
                  // Reserve space so the grid does not render under the header.
                  const SizedBox(height: _headerHeight),

                  // 3-column thumbnail grid.
                  Expanded(child: _buildGrid(items)),

                  // "New Batch" CTA at the bottom.
                  _buildNewBatchCTA(),
                ],
              ),

              // ── Glassmorphism header (overlaid at top) ────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildGlassHeader(items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  /// Frosted-glass header bar showing the result count and a share-all button.
  ///
  /// [BackdropFilter] requires a non-opaque ancestor — this works correctly
  /// because it is placed inside a [Stack] on top of the gradient container.
  Widget _buildGlassHeader(List<JobItem> items) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: _headerHeight,
          decoration: BoxDecoration(
            color: WsColors.glassWhite,
            border: Border(
              bottom: BorderSide(
                color: WsColors.glassBorder,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${items.length} result${items.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: WsColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _export(items),
                icon: const Icon(
                  Icons.share_rounded,
                  color: WsColors.text,
                  size: 22,
                ),
                tooltip: 'Share all results',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  /// 3-column thumbnail grid.  Each cell shows [JobItem.previewUrl] as a
  /// rounded card.  Tapping opens the fullscreen gallery at the tapped index.
  Widget _buildGrid(List<JobItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No results yet.',
          style: TextStyle(color: WsColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildGridCard(context, item, items, index);
      },
    );
  }

  /// A single rounded thumbnail card within the grid.
  Widget _buildGridCard(
    BuildContext context,
    JobItem item,
    List<JobItem> allItems,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _openFullscreen(context, allItems, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WsTheme.radiusSm),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image (previewUrl — NOT BeforeAfter slider in grid).
            Image.network(
              item.previewUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: WsColors.surface,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WsColors.accent1,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: WsColors.surface,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: WsColors.textSecondary,
                  size: 28,
                ),
              ),
            ),

            // Subtle gradient scrim at the bottom for visual depth.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── New Batch CTA ─────────────────────────────────────────────────────────

  /// Prominent gradient button that resets the workspace to idle phase.
  Widget _buildNewBatchCTA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: WsColors.gradientPrimary,
          borderRadius: BorderRadius.all(Radius.circular(WsTheme.radius)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              ref.read(workspaceProvider.notifier).resetToIdle();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(WsTheme.radius)),
              ),
            ),
            child: const Text(
              'New Batch',
              style: TextStyle(
                color: WsColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Action stubs (implemented in later subtasks) ──────────────────────────

  /// Opens the fullscreen [PageView] gallery starting at [startIndex].
  ///
  /// TODO(subtask-2-2): Replace stub with fullscreen PageView + BeforeAfter
  /// slider implementation.
  void _openFullscreen(
    BuildContext context,
    List<JobItem> items,
    int startIndex,
  ) {
    // Placeholder — fullscreen gallery implemented in subtask-2-2.
  }

  /// Shares all result URLs as text.
  ///
  /// TODO(subtask-2-3): Replace stub with Share.shareXFiles() implementation.
  void _export(List<JobItem> items) {
    // Placeholder — per-image share/download implemented in subtask-2-3.
  }
}
