import 'dart:io';
import 'dart:ui';

import 'package:before_after/before_after.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

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

  // ── Fullscreen gallery ─────────────────────────────────────────────────────

  /// Opens the fullscreen [PageView] gallery starting at [startIndex].
  ///
  /// Uses [PageRouteBuilder] with `opaque: false` so the SNOW gradient shows
  /// through during the transition animation.
  void _openFullscreen(
    BuildContext context,
    List<JobItem> items,
    int startIndex,
  ) {
    final selectedImages = ref.read(workspaceProvider).selectedImages;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (ctx, animation, secondaryAnimation) =>
            _FullscreenGallery(
          items: items,
          initialIndex: startIndex,
          selectedImages: selectedImages,
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Shares all result URLs as text via the OS share sheet.
  Future<void> _export(List<JobItem> items) async {
    if (items.isEmpty) return;
    final text = items.map((e) => e.resultUrl).join('\n');
    await Share.share('S3 Results:\n$text');
  }
}

// ---------------------------------------------------------------------------
// _FullscreenGallery
// ---------------------------------------------------------------------------

/// Immersive fullscreen gallery that lets the user swipe through all results.
///
/// Pushed via [PageRouteBuilder] with `opaque: false` so the SNOW gradient
/// background shows through during the entry/exit transition.
///
/// Layout:
/// ```
/// Material (black 90% bg)
///   SafeArea
///     Stack
///       ├── PageView.builder → _GalleryPage (BeforeAfter slider per image)
///       ├── Positioned (top-right) → close button (glassmorphism)
///       └── Positioned (top-center) → page counter (when items > 1)
/// ```
class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.items,
    required this.initialIndex,
    required this.selectedImages,
  });

  final List<JobItem> items;
  final int initialIndex;
  final List<SelectedImage> selectedImages;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Stack(
          children: [
            // ── PageView ──────────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) =>
                  setState(() => _currentIndex = index),
              itemBuilder: (context, index) => _GalleryPage(
                item: widget.items[index],
                selectedImages: widget.selectedImages,
              ),
            ),

            // ── Glassmorphism close button (top-right) ────────────────────
            Positioned(
              top: 12,
              right: 12,
              child: _buildCloseButton(context),
            ),

            // ── Page counter (top-center, only when multiple items) ────────
            if (widget.items.length > 1)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_currentIndex + 1} / ${widget.items.length}',
                    style: const TextStyle(
                      color: WsColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Glassmorphism close button that pops the fullscreen gallery.
  Widget _buildCloseButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WsTheme.radiusSm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: WsTheme.glassDecoration,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: WsColors.text,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GalleryPage
// ---------------------------------------------------------------------------

/// A single page within the [_FullscreenGallery] PageView.
///
/// Renders a [BeforeAfter] slider comparing:
/// - **before**: original input bytes from [SelectedImage.bytes]
/// - **after**: AI-processed result via [JobItem.resultUrl]
///
/// Falls back to showing only the "after" image when the original bytes are
/// unavailable (i.e. `selectedImages` is shorter than `item.idx`), guarding
/// against index-out-of-range crashes when `resetToIdle()` clears images.
class _GalleryPage extends StatefulWidget {
  const _GalleryPage({
    required this.item,
    required this.selectedImages,
  });

  final JobItem item;
  final List<SelectedImage> selectedImages;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  /// Slider position: 0.0 = all before, 1.0 = all after. Default at 50%.
  double _sliderValue = 0.5;

  /// Dio instance for downloading images to temp files.
  late final Dio _dio;

  /// GlobalKey for the share button — used to derive iPad share popover origin.
  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dio = Dio();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  /// Whether the original (before) bytes are available for this item.
  ///
  /// [JobItem.idx] is 1-based; guard by comparing `idx - 1` against length.
  bool get _hasOriginal =>
      widget.item.idx - 1 < widget.selectedImages.length;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Image content (before/after or after-only) ────────────────────
        Positioned.fill(
          child: _hasOriginal ? _buildBeforeAfter() : _buildAfterOnly(),
        ),

        // ── Glassmorphism action bar (bottom-centre) ──────────────────────
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(child: _buildActionBar(context)),
        ),
      ],
    );
  }

  // ── Action bar ────────────────────────────────────────────────────────────

  /// Glassmorphism action bar with Share and Download buttons.
  ///
  /// Placed at the bottom-centre of the fullscreen page so it floats over
  /// the image without obscuring the Before/After slider.
  Widget _buildActionBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WsTheme.radiusSm),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: WsTheme.glassDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: _shareKey,
                onPressed: () => _shareImage(context),
                icon: const Icon(
                  Icons.share_rounded,
                  color: WsColors.text,
                  size: 22,
                ),
                tooltip: 'Share',
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
              Container(
                width: 0.5,
                height: 24,
                color: WsColors.glassBorder,
              ),
              IconButton(
                onPressed: () => _downloadImage(context),
                icon: const Icon(
                  Icons.download_rounded,
                  color: WsColors.text,
                  size: 22,
                ),
                tooltip: 'Save to gallery',
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  /// Downloads [widget.item.resultUrl] to a temp file, then opens the OS share
  /// sheet via [Share.shareXFiles].
  ///
  /// iPad safety: derives [sharePositionOrigin] from the share button's
  /// [RenderBox] so the popover anchors correctly on iPad.
  ///
  /// The temp file is always deleted in `finally`.
  Future<void> _shareImage(BuildContext context) async {
    final tmpPath =
        '${Directory.systemTemp.path}/s3_share_${widget.item.idx}.jpg';

    // Derive iPad-safe popover origin BEFORE any await so the BuildContext
    // is accessed synchronously (avoids use_build_context_synchronously lint).
    Rect? sharePositionOrigin;
    final keyContext = _shareKey.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox?;
      if (box != null) {
        final topLeft = box.localToGlobal(Offset.zero);
        sharePositionOrigin = Rect.fromLTWH(
          topLeft.dx,
          topLeft.dy,
          box.size.width,
          box.size.height,
        );
      }
    }

    try {
      await _dio.download(widget.item.resultUrl, tmpPath);
      await Share.shareXFiles(
        [XFile(tmpPath)],
        subject: 'S3 Result',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share image')),
        );
      }
    } finally {
      final f = File(tmpPath);
      if (await f.exists()) await f.delete();
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────

  /// Downloads [widget.item.resultUrl] and saves it to the device gallery via
  /// [Gal.putImage].
  ///
  /// Shows a success [SnackBar] on completion or an error [SnackBar] when a
  /// [GalException] is raised (e.g. permission denied).
  ///
  /// The temp file is always deleted in `finally`.
  Future<void> _downloadImage(BuildContext context) async {
    final tmpPath =
        '${Directory.systemTemp.path}/s3_dl_${widget.item.idx}.jpg';
    try {
      await _dio.download(widget.item.resultUrl, tmpPath);
      await Gal.putImage(tmpPath, album: 'S3');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery')),
        );
      }
    } on GalException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.type}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed')),
        );
      }
    } finally {
      final f = File(tmpPath);
      if (await f.exists()) await f.delete();
    }
  }

  /// Full before/after comparison slider.
  ///
  /// Uses [before_after] v3.x API: `before`, `after`, `value`, `onValueChanged`.
  Widget _buildBeforeAfter() {
    final originalBytes = widget.selectedImages[widget.item.idx - 1].bytes;
    return BeforeAfter(
      value: _sliderValue,
      before: Image.memory(
        originalBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
      after: Image.network(
        widget.item.resultUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: WsColors.accent1,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: WsColors.textSecondary,
            size: 48,
          ),
        ),
      ),
      onValueChanged: (v) => setState(() => _sliderValue = v),
    );
  }

  /// Fallback: only the processed "after" image when original is unavailable.
  Widget _buildAfterOnly() {
    return Image.network(
      widget.item.resultUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: WsColors.accent1,
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: WsColors.textSecondary,
          size: 48,
        ),
      ),
    );
  }
}
