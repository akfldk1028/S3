import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../theme.dart';
import '../workspace_provider.dart';

class ProgressOverlay extends ConsumerWidget {
  const ProgressOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final job = ws.activeJob;

    return Container(
      color: WsColors.bg.withValues(alpha: 0.7),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: WsColors.surface,
              borderRadius: BorderRadius.circular(WsTheme.radiusLg),
              border: Border.all(color: WsColors.glassBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: WsColors.accent1.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: job == null ? _buildWaiting() : _buildProgress(ref, job),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: WsColors.accent1,
            backgroundColor: WsColors.glassWhite,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Starting job...',
          style: TextStyle(
            fontSize: 14,
            color: WsColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(WidgetRef ref, Job job) {
    final progress = job.progress;
    final total = progress.total;
    final done = progress.done;
    final failed = progress.failed;
    final progressValue = total > 0 ? (done + failed) / total : 0.0;
    final status = job.status;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated gradient progress ring
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: 4,
                  color: WsColors.accent1,
                  backgroundColor: WsColors.glassWhite,
                ),
              ),
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: WsColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _statusColor(status).withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _statusColor(status),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          '$done / $total items',
          style: const TextStyle(
            fontSize: 14,
            color: WsColors.textSecondary,
          ),
        ),
        if (failed > 0)
          Text(
            '$failed failed',
            style: const TextStyle(
              fontSize: 12,
              color: WsColors.error,
            ),
          ),

        const SizedBox(height: 24),

        // Cancel
        GestureDetector(
          onTap: () => ref.read(workspaceProvider.notifier).cancelJob(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: WsColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(WsTheme.radiusXl),
              border: Border.all(
                color: WsColors.error.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stop_rounded, size: 14, color: WsColors.error),
                SizedBox(width: 6),
                Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: WsColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'queued':
        return WsColors.warning;
      case 'running':
        return WsColors.accent1;
      case 'done':
        return WsColors.success;
      case 'failed':
        return WsColors.error;
      default:
        return WsColors.textMuted;
    }
  }
}
