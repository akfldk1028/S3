import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: S3App(),
    ),
  );
}

class S3App extends StatelessWidget {
  const S3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S3 - Domain Palette Engine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
