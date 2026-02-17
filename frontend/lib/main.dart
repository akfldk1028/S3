import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runZonedGuarded(() {
    runApp(
      const ErrorBoundary(
        child: ProviderScope(
          child: App(),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('Zone error: $error');
  });
}
