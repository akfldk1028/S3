import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:s3_frontend/common_widgets/shimmer_card.dart';
import 'package:s3_frontend/common_widgets/shimmer_list.dart';

void main() {
  group('ShimmerCard', () {
    testWidgets('renders a Shimmer widget with default dimensions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCard(),
          ),
        ),
      );

      // A Shimmer widget should be present.
      expect(find.byType(Shimmer), findsOneWidget);
      // The inner Container that acts as the placeholder card.
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders with custom width and height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCard(width: 200, height: 120),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
    });
  });

  group('ShimmerList', () {
    testWidgets('renders the default 3 ShimmerCard items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerList(),
          ),
        ),
      );

      // Default count is 3 — expect 3 Shimmer widgets.
      expect(find.byType(Shimmer), findsNWidgets(3));
    });

    testWidgets('renders N ShimmerCard items when count is provided',
        (WidgetTester tester) async {
      const n = 5;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerList(count: n),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsNWidgets(n));
    });
  });
}
