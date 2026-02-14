import 'package:flutter/material.dart';

/// Placeholder JobProgressScreen - will be implemented in phase-12
class JobProgressScreen extends StatelessWidget {
  final String jobId;

  const JobProgressScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Job Progress Screen - To be implemented\nJob ID: $jobId'),
      ),
    );
  }
}
