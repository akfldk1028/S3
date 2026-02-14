import 'package:flutter/material.dart';

/// Placeholder RulesScreen - will be implemented in phase-11
class RulesScreen extends StatelessWidget {
  final String? jobId;

  const RulesScreen({super.key, this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Rules Screen - To be implemented\nJob ID: $jobId'),
      ),
    );
  }
}
