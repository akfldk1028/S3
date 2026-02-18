import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

/// Full-screen overlay shown while a job is processing (phase == processing).
///
/// Renders a progress ring and status badge.
/// When [activeJob.status == 'failed'], shows a **Retry** button that calls
/// [WorkspaceNotifier.retryJob] (NOT resetToIdle) so photos are preserved.
class ProgressOverlay extends ConsumerWidget {
  const ProgressOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    final jobFailed = ws.phase == WorkspacePhase.error;

    return Container(
      color: WsColors.bg.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress ring
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: jobFailed ? WsColors.error : WsColors.accent1,
                backgroundColor: WsColors.glassWhite,
              ),
            ),
            const SizedBox(height: 20),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: WsColors.glassWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: WsColors.glassBorder, width: 0.5),
              ),
              child: Text(
                jobFailed ? 'Processing Failed' : 'Processing…',
                style: TextStyle(
                  fontSize: 13,
                  color: jobFailed ? WsColors.error : WsColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Retry button shown when job failed; Cancel shown otherwise.
            if (jobFailed)
              _OverlayButton(
                label: 'Retry',
                color: WsColors.error,
                onTap: notifier.retryJob,
              )
            else
              _OverlayButton(
                label: 'Cancel',
                color: WsColors.textMuted,
                onTap: notifier.cancelJob,
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _OverlayButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(WsTheme.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
