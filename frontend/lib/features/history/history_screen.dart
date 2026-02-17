import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../workspace/theme.dart';
import 'history_provider.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/job_history_item.dart';

/// HistoryScreen — displays a list of past jobs for the current user.
///
/// States:
///   loading  → CircularProgressIndicator
///   error    → error message + Retry button
///   data     → empty state OR scrollable list of [JobHistoryItem]
///
/// Pull-to-refresh triggers [History.refresh] on the [historyProvider].
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: WsColors.bg,
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(color: WsColors.textPrimary),
        ),
        backgroundColor: WsColors.surface,
        leading: BackButton(
          color: WsColors.textPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: historyAsync.when(
        data: (jobs) => jobs.isEmpty
            ? const HistoryEmptyState()
            : _buildJobList(context, ref, jobs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildErrorState(context, ref, err),
      ),
    );
  }

  Widget _buildJobList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> jobs,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(historyProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return JobHistoryItem(
            job: job,
            onTap: () => context.push('/results/${job.jobId}'),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error: $err',
            style: const TextStyle(
              color: WsColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(historyProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
