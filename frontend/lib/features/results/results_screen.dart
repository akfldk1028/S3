import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../workspace/theme.dart';

/// ResultsScreen — displays results for a completed job.
///
/// Navigated to from [HistoryScreen] when the user taps a job item.
/// Route: /results/:id
class ResultsScreen extends StatelessWidget {
  final String jobId;

  const ResultsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WsColors.bg,
      appBar: AppBar(
        title: const Text(
          'Results',
          style: TextStyle(color: WsColors.textPrimary),
        ),
        backgroundColor: WsColors.surface,
        leading: BackButton(
          color: WsColors.textPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 64,
              color: WsColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Job: $jobId',
              style: const TextStyle(
                color: WsColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Results coming soon.',
              style: TextStyle(
                color: WsColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
