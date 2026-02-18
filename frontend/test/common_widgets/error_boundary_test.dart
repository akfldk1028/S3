import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:s3_frontend/core/widgets/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child widget when no error occurs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ErrorBoundary(
          child: MaterialApp(
            home: Scaffold(
              body: Text('Hello'),
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets(
        'shows error recovery screen when FlutterError is reported',
        (WidgetTester tester) async {
      // Pump the ErrorBoundary — its initState installs a FlutterError.onError
      // handler that calls setState when an error is detected.
      await tester.pumpWidget(
        const ErrorBoundary(
          child: MaterialApp(
            home: Scaffold(body: Text('Normal content')),
          ),
        ),
      );

      // Normal content visible initially.
      expect(find.text('Normal content'), findsOneWidget);

      // Simulate a Flutter framework error by calling FlutterError.reportError
      // directly. ErrorBoundary.initState has already replaced FlutterError.onError
      // with its own handler that calls setState — no exception propagates into
      // the test zone, so the test runner does not record a pending exception.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: Exception('test error'),
          library: 'error_boundary_test',
          context: ErrorDescription('simulated error for test'),
        ),
      );
      await tester.pump();

      // The error recovery screen must be visible.
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Restart App'), findsOneWidget);
    });

    testWidgets('Restart App button clears the error and shows child again',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ErrorBoundary(
          child: MaterialApp(
            home: Scaffold(body: Text('Normal content')),
          ),
        ),
      );

      // Trigger the error.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: Exception('another error'),
          library: 'error_boundary_test',
          context: ErrorDescription('restart test'),
        ),
      );
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);

      // Tap "Restart App" to clear the error.
      await tester.tap(find.text('Restart App'));
      await tester.pump();

      // Child content is visible again.
      expect(find.text('Normal content'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
