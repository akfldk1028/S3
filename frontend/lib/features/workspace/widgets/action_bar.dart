import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

/// Bottom action bar for the workspace.
///
/// Renders phase-appropriate controls:
/// - [WorkspacePhase.photosSelected] → "GO" button
/// - [WorkspacePhase.uploading] → progress indicator
/// - [WorkspacePhase.error] → "Retry" button (calls [WorkspaceNotifier.retryJob])
/// - [WorkspacePhase.done] → "Reset" button
class ActionBar extends ConsumerWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: WsColors.surface,
        border: Border(
          top: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      child: _buildContent(ws, notifier),
    );
  }

  Widget _buildContent(WorkspaceState ws, Workspace notifier) {
    switch (ws.phase) {
      case WorkspacePhase.photosSelected:
        return _PillButton(
          label: 'GO',
          gradient: WsColors.gradientPrimary,
          onTap: () => notifier.uploadAndProcess([]),
        );

      case WorkspacePhase.uploading:
        return Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: ws.uploadProgress,
                backgroundColor: WsColors.glassWhite,
                valueColor: const AlwaysStoppedAnimation(WsColors.accent1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(ws.uploadProgress * 100).toInt()}%',
              style: const TextStyle(
                color: WsColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );

      case WorkspacePhase.processing:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WsColors.accent1,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Processing…',
              style: TextStyle(
                color: WsColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        );

      case WorkspacePhase.error:
        return _PillButton(
          label: 'Retry',
          gradient: LinearGradient(
            colors: [WsColors.error, WsColors.accent2],
          ),
          onTap: notifier.retryJob,
        );

      case WorkspacePhase.completed:
        return _PillButton(
          label: 'Start Over',
          gradient: WsColors.gradientPrimary,
          onTap: notifier.resetToIdle,
        );

      case WorkspacePhase.idle:
        return const SizedBox.shrink();
    }
  }
}

/// Gradient pill button reused throughout the action bar.
class _PillButton extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(WsTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: WsColors.accent1.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
