import 'package:flutter/material.dart';

/// Placeholder UploadScreen - will be implemented in phase-10
class UploadScreen extends StatelessWidget {
  final String? presetId;
  final String? conceptsJson;
  final String? protectJson;

  const UploadScreen({
    super.key,
    this.presetId,
    this.conceptsJson,
    this.protectJson,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Upload Screen - To be implemented'),
      ),
    );
  }
}
