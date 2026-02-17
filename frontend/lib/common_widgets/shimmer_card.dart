import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Surface colors matching WsColors spec:
// surface      = 0xFF1A1A2E (dark card background)
// surfaceLight = 0xFF252540 (shimmer highlight)
const _surface = Color(0xFF1A1A2E);
const _surfaceLight = Color(0xFF252540);

// Matches WsTheme.cardDecoration borderRadius.
const double _cardRadius = 12.0;

/// A shimmer placeholder card used to indicate loading state.
///
/// Wraps a rounded [Container] in [Shimmer.fromColors] using the dark-theme
/// surface palette so the animation blends naturally with the app background.
///
/// Parameters:
/// - [width]  — card width  (default: [double.infinity])
/// - [height] — card height (default: 80)
class ShimmerCard extends StatelessWidget {
  /// Width of the placeholder card. Defaults to [double.infinity].
  final double width;

  /// Height of the placeholder card. Defaults to 80.
  final double height;

  const ShimmerCard({
    super.key,
    this.width = double.infinity,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _surface,
      highlightColor: _surfaceLight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
    );
  }
}
