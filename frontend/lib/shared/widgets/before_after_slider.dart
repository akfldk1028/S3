import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../features/workspace/theme.dart';

/// A Before/After comparison slider widget.
///
/// Renders two images stacked on top of each other with a draggable vertical
/// divider that reveals the [beforeBytes] (original) on the left and the
/// [afterUrl] (processed result) on the right.
class BeforeAfterSlider extends StatefulWidget {
  /// Raw bytes of the original (before) image.
  final Uint8List beforeBytes;

  /// Network URL of the processed (after) image.
  final String afterUrl;

  /// Optional explicit width. Defaults to full available width.
  final double? width;

  /// Optional explicit height. Defaults to full available height.
  final double? height;

  const BeforeAfterSlider({
    super.key,
    required this.beforeBytes,
    required this.afterUrl,
    this.width,
    this.height,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  /// Normalized divider position: 0.0 = full After, 1.0 = full Before.
  double _sliderPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = widget.width ?? constraints.maxWidth;
        final totalHeight = widget.height ?? constraints.maxHeight;

        return SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: AFTER image — full-width base layer.
              Image.network(
                widget.afterUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: WsColors.surfaceLight,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: WsColors.accent1,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: WsColors.surfaceLight,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: WsColors.textMuted,
                    ),
                  ),
                ),
              ),

              // Layer 2: BEFORE image clipped to the left [_sliderPosition] fraction.
              ClipRect(
                clipper: _LeftFractionClipper(_sliderPosition),
                child: Image.memory(
                  widget.beforeBytes,
                  fit: BoxFit.contain,
                ),
              ),

              // Layer 3: Vertical divider line + circular drag handle.
              Positioned(
                left: totalWidth * _sliderPosition - 22,
                top: 0,
                bottom: 0,
                child: const _DividerHandle(),
              ),

              // Layer 4: "BEFORE" label — top-left.
              const Positioned(
                top: 16,
                left: 16,
                child: _SliderLabel('BEFORE'),
              ),

              // Layer 5: "AFTER" label — top-right.
              const Positioned(
                top: 16,
                right: 16,
                child: _SliderLabel('AFTER'),
              ),

              // Layer 6: Full-area gesture detector for horizontal drag.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sliderPosition =
                        (_sliderPosition + details.delta.dx / totalWidth)
                            .clamp(0.0, 1.0);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Clips a widget to the left [fraction] of its available width.
class _LeftFractionClipper extends CustomClipper<Rect> {
  final double fraction;

  const _LeftFractionClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftFractionClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}

/// A 2px vertical line with a centered circular drag handle.
class _DividerHandle extends StatelessWidget {
  const _DividerHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Vertical line centered in the 44px column.
          Positioned(
            left: 21,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          // Circular handle with gradient background.
          Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: WsColors.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: WsColors.accent1.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, size: 14, color: Colors.white),
                  Icon(Icons.chevron_right, size: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pill-shaped label badge (e.g., "BEFORE" or "AFTER").
class _SliderLabel extends StatelessWidget {
  final String text;

  const _SliderLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
