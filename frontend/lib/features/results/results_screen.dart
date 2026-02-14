import 'package:flutter/material.dart';

/// Placeholder ResultsScreen - will be implemented in phase-13
class ResultsScreen extends StatelessWidget {
  final String jobId;

  const ResultsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Results Screen - To be implemented\nJob ID: $jobId'),
      ),
    );
  }
}
