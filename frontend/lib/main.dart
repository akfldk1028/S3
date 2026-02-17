import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/api/s3_api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(S3ApiClient()),
      ],
      child: const App(),
    ),
  );
}
