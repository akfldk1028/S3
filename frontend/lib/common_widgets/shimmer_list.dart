import 'package:flutter/material.dart';

import 'shimmer_card.dart';

/// A list of [ShimmerCard] placeholders used to indicate a loading state
/// for list-based content.
///
/// Renders [count] shimmer cards inside a [ListView.separated], with a
/// [SizedBox] divider between each item so the layout matches the app's
/// standard list spacing.
///
/// Parameters:
/// - [count]      — number of placeholder cards to render (default: 3)
/// - [itemHeight] — height forwarded to each [ShimmerCard] (default: 80)
/// - [dividerHeight] — height of the [SizedBox] divider between items (default: 12)
class ShimmerList extends StatelessWidget {
  /// Number of [ShimmerCard] placeholders to display. Defaults to 3.
  final int count;

  /// Height of each [ShimmerCard]. Defaults to 80.
  final double itemHeight;

  /// Height of the [SizedBox] separator between items. Defaults to 12.
  final double dividerHeight;

  const ShimmerList({
    super.key,
    this.count = 3,
    this.itemHeight = 80,
    this.dividerHeight = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => SizedBox(height: dividerHeight),
      itemBuilder: (context, index) => ShimmerCard(height: itemHeight),
    );
  }
}
