import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../../../shared/widgets/tap_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

enum ActionBarState {
  /// User can start processing — shows the gradient GO button.
  idle,

  /// Upload is in progress — shows an indeterminate upload progress indicator.
  uploading,

  /// Processing is running — shows a Cancel pill button.
  running,

  /// Processing finished — shows a Retry pill button.
  done,

  /// An error occurred — shows a Retry pill button.
  error,
}

/// Workspace bottom action bar.
///
/// Renders one of three layouts depending on [state]:
/// - [ActionBarState.idle]      → [_GradientButton] "GO"
/// - [ActionBarState.uploading] → [_ProgressButton] upload indicator
/// - [ActionBarState.running]   → [_PillButton] "Cancel"
/// - [ActionBarState.done]      → [_PillButton] "Retry"
/// - [ActionBarState.error]     → [_PillButton] "Retry"
class WorkspaceActionBar extends StatelessWidget {
  const WorkspaceActionBar({
    super.key,
    required this.state,
    this.uploadProgress = 0.0,
    this.onGo,
    this.onCancel,
    this.onRetry,
  });

  final ActionBarState state;

  /// Upload progress in range [0.0, 1.0]. Only relevant when
  /// [state] is [ActionBarState.uploading].
  final double uploadProgress;

  /// Called when the user taps the GO button. If null, the button is disabled.
  final VoidCallback? onGo;

  /// Called when the user taps the Cancel button.
  final VoidCallback? onCancel;

  /// Called when the user taps the Retry button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WsTheme.actionBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: WsTheme.actionBarPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: WsColors.glassWhite,
        border: Border(
          top: BorderSide(
            color: WsColors.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case ActionBarState.idle:
        return _GradientButton(
          label: 'GO',
          icon: Icons.auto_awesome_rounded,
          onTap: onGo,
          enabled: onGo != null,
        );

      case ActionBarState.uploading:
        return _ProgressButton(progress: uploadProgress);

      case ActionBarState.running:
        return _PillButton(
          label: 'Cancel',
          icon: Icons.close_rounded,
          onTap: onCancel,
        );

      case ActionBarState.done:
      case ActionBarState.error:
        return _PillButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onTap: onRetry,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GradientButton  (L129 – L229)
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  // Shimmer sweep animation — runs continuously when button is enabled.
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    if (widget.enabled) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void didUpdateWidget(_GradientButton old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) {
      _shimmerCtrl.repeat();
    } else if (!widget.enabled && old.enabled) {
      _shimmerCtrl.stop();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── onTap handler ─────────────────────────────────────────────────────────
  // HapticFeedback fires FIRST; then the caller's callback.
  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = widget.enabled ? _handleTap : null;

    // TapScale wraps the visible button child so both the scale animation
    // and the haptic fire on press. The outer GestureDetector is provided
    // by TapScale itself.
    return TapScale(
      onTap: effectiveOnTap,
      child: AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (context, child) {
          return Container(
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: widget.enabled
                  ? WsColors.gradientPrimary
                  : const LinearGradient(
                      colors: [Color(0x66667EEA), Color(0x66FF6B9D)],
                    ),
              borderRadius: BorderRadius.circular(WsTheme.borderRadiusPill),
            ),
            child: Stack(
              children: [
                // Shimmer overlay
                if (widget.enabled)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(WsTheme.borderRadiusPill),
                      child: AnimatedBuilder(
                        animation: _shimmerAnim,
                        builder: (ctx, _) => FractionallySizedBox(
                          alignment: Alignment(_shimmerAnim.value, 0),
                          widthFactor: 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Label row
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        color: WsColors.textPrimary,
                        size: WsTheme.iconSize,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: WsColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressButton  — upload progress indicator (NOT tappable, no TapScale)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressButton extends StatelessWidget {
  const _ProgressButton({required this.progress});

  /// Upload progress in range [0.0, 1.0].
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(WsTheme.borderRadiusPill),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      ),
      child: Stack(
        children: [
          // Progress fill
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: WsColors.gradientPrimary,
                borderRadius:
                    BorderRadius.circular(WsTheme.borderRadiusPill),
              ),
            ),
          ),
          // Label
          Center(
            child: Text(
              'Uploading $pct%',
              style: const TextStyle(
                color: WsColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PillButton  (L274 – L316)
// ─────────────────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  // ── onTap handler ─────────────────────────────────────────────────────────
  // HapticFeedback fires FIRST; then the caller's callback.
  void _handleTap() {
    HapticFeedback.lightImpact();
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // TapScale wraps the pill's visible Container; the GestureDetector inside
    // TapScale handles both the tap callback and the scale animation.
    return TapScale(
      onTap: onTap != null ? _handleTap : null,
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: WsColors.glassWhite,
          borderRadius: BorderRadius.circular(WsTheme.borderRadiusPill),
          border: Border.all(color: WsColors.glassBorder, width: 0.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: WsColors.textSecondary,
                size: WsTheme.iconSize,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: WsColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
