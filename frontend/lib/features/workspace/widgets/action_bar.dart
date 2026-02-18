import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

class ActionBar extends ConsumerWidget {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: WsColors.bg.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: WsColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Summary info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _title(ws),
                        style: const TextStyle(
                          fontSize: 13,
                          color: WsColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (ws.selectedImages.isNotEmpty)
                        Text(
                          _subtitle(ws),
                          style: const TextStyle(
                            fontSize: 11,
                            color: WsColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildButton(ref, ws),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(WorkspaceState ws) {
    if (ws.selectedImages.isEmpty) return 'Ready to start';
    return '${ws.selectedImages.length} photo${ws.selectedImages.length > 1 ? 's' : ''}';
  }

  String _subtitle(WorkspaceState ws) {
    return ws.selectedPresetId ?? 'Select a domain';
  }

  Widget _buildButton(WidgetRef ref, WorkspaceState ws) {
    switch (ws.phase) {
      case WorkspacePhase.idle:
        return _GradientButton(
          label: 'Process',
          enabled: false,
          onTap: null,
        );

      case WorkspacePhase.photosSelected:
        final ready =
            ws.selectedImages.isNotEmpty && ws.selectedPresetId != null;
        return _GradientButton(
          label: 'GO',
          icon: Icons.play_arrow_rounded,
          enabled: ready,
          shimmer: ready,
          onTap: ready
              ? () => ref.read(workspaceProvider.notifier).uploadAndProcess()
              : null,
        );

      case WorkspacePhase.uploading:
        return _ProgressButton(progress: ws.uploadProgress, label: 'Uploading');

      case WorkspacePhase.processing:
        return _PillButton(
          label: 'Cancel',
          icon: Icons.stop_rounded,
          color: WsColors.error,
          onTap: () => ref.read(workspaceProvider.notifier).cancelJob(),
        );

      case WorkspacePhase.done:
        return _GradientButton(
          label: 'New Batch',
          icon: Icons.refresh_rounded,
          enabled: true,
          onTap: () => ref.read(workspaceProvider.notifier).resetToIdle(),
        );

      case WorkspacePhase.error:
        return _PillButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          color: WsColors.accent1,
          onTap: () => ref.read(workspaceProvider.notifier).resetToIdle(),
        );
    }
  }
}

/// Gradient button with optional shimmer effect.
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool shimmer;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    this.icon,
    required this.enabled,
    this.shimmer = false,
    this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.shimmer && widget.enabled) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(_GradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer && widget.enabled && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if ((!widget.shimmer || !widget.enabled) &&
        _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: widget.enabled ? WsColors.gradientPrimary : null,
              color: widget.enabled ? null : WsColors.surfaceLight,
              borderRadius: BorderRadius.circular(WsTheme.radiusXl),
              boxShadow: widget.enabled && widget.shimmer
                  ? [
                      BoxShadow(
                        color: WsColors.accent1
                            .withValues(alpha: 0.2 + _shimmerController.value * 0.2),
                        blurRadius: 16 + _shimmerController.value * 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18,
                      color: widget.enabled ? Colors.white : WsColors.textMuted),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.enabled ? Colors.white : WsColors.textMuted,
                    letterSpacing: widget.label == 'GO' ? 2.0 : 0,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressButton extends StatelessWidget {
  final double progress;
  final String label;

  const _ProgressButton({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: WsColors.surfaceLight,
        borderRadius: BorderRadius.circular(WsTheme.radiusXl),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
              color: WsColors.accent1,
              backgroundColor: WsColors.glassWhite,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WsColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(WsTheme.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
