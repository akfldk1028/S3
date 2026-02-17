import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/widgets/error_boundary.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      const ErrorBoundary(
        child: ProviderScope(
          child: App(),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('Zone error: $error\n$stack');
  });
}
