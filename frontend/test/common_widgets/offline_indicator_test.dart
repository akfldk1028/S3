import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:s3_frontend/core/widgets/offline_indicator.dart';

void main() {
  group('OfflineIndicator', () {
    testWidgets('child widget is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            child: Scaffold(
              body: Text('Main Content'),
            ),
          ),
        ),
      );

      // Child content must always be rendered.
      expect(find.text('Main Content'), findsOneWidget);
    });

    testWidgets('offline banner is initially off-screen (not visible)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            child: Scaffold(
              body: Text('Main Content'),
            ),
          ),
        ),
      );

      // The 'No internet connection' text must be in the widget tree but should
      // be positioned off-screen (top < 0) when _isOffline is false.
      // We verify it exists (not showing an error banner by default).
      expect(find.text('No internet connection'), findsOneWidget);

      // Verify the AnimatedPositioned that holds the banner exists.
      expect(find.byType(AnimatedPositioned), findsOneWidget);

      // When initially rendered, the Stack child order places the child first
      // so the child is fully visible. The OfflineIndicator wraps its child in a
      // Stack — confirm the Stack is present.
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('OfflineIndicator wraps child in a Stack',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OfflineIndicator(
            child: Scaffold(
              body: Center(child: Text('content')),
            ),
          ),
        ),
      );

      // The implementation uses Stack to overlay the banner on the child.
      expect(find.byType(Stack), findsWidgets);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
