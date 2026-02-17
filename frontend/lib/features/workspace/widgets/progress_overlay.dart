import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../../../shared/widgets/tap_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Status enum
// ─────────────────────────────────────────────────────────────────────────────

/// Current state of the workspace job driving [ProgressOverlay].
enum OverlayStatus {
  /// Upload or server-side queuing is in progress — no explicit percentage yet.
  waiting,

  /// Processing is actively running — use [ProgressOverlay.progressValue].
  running,

  /// Processing finished successfully.
  done,

  /// Processing failed with an error.
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen modal overlay displayed while a workspace job is in progress.
///
/// Renders one of two sub-views:
/// - **Waiting** ([OverlayStatus.waiting]) — indeterminate ring at progress 0,
///   "Please wait…" label, and an optional Cancel button.
/// - **Running** ([OverlayStatus.running]) — determinate [_SweepRingPainter]
///   ring driven by [progressValue], a percentage label, and a status pill.
///
/// Both ring variants use [_SweepRingPainter] instead of the stock
/// [CircularProgressIndicator] for a gradient accent1→accent2 sweep.
class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({
    super.key,
    required this.status,
    this.progressValue = 0.0,
    this.onCancel,
  });

  /// Current job phase controlling which sub-view is shown.
  final OverlayStatus status;

  /// Fractional progress in range [0.0, 1.0].
  ///
  /// Only meaningful when [status] is [OverlayStatus.running].
  final double progressValue;

  /// Called when the user taps the Cancel button (waiting state).
  ///
  /// If null the Cancel button is hidden.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WsColors.bgDark.withValues(alpha: 0.88),
      child: Center(
        child: status == OverlayStatus.waiting
            ? _buildWaiting()
            : _buildProgress(),
      ),
    );
  }

  // ── Waiting sub-view (L45 – L79) ────────────────────────────────────────

  /// Waiting / upload phase — indeterminate ring (progress=0) + Cancel button.
  Widget _buildWaiting() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Sweep ring — indeterminate (progress = 0.0) ──────────────────
        SizedBox(
          width: 64,
          height: 64,
          child: CustomPaint(
            painter: _SweepRingPainter(0.0),
          ),
        ),

        const SizedBox(height: WsTheme.spacingXl),

        // "Please wait…" label.
        const Text(
          'Please wait…',
          style: TextStyle(
            color: WsColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: WsTheme.spacingLg),

        // Optional Cancel button.
        if (onCancel != null)
          TapScale(
            onTap: () {
              HapticFeedback.lightImpact();
              onCancel!();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: WsTheme.spacingXl,
                vertical: WsTheme.spacingLg,
              ),
              decoration: BoxDecoration(
                color: WsColors.glassWhite,
                borderRadius: BorderRadius.circular(WsTheme.borderRadiusPill),
                border: Border.all(color: WsColors.glassBorder, width: 1.0),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: WsColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Progress sub-view (L80 – L140) ──────────────────────────────────────

  /// Running phase — determinate sweep ring with percentage + status pill.
  Widget _buildProgress() {
    final pct = (progressValue * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Sweep ring with percentage label centred inside ──────────────
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gradient arc driven by progressValue.
              CustomPaint(
                size: const Size(96, 96),
                painter: _SweepRingPainter(progressValue),
              ),

              // Percentage text inside the ring.
              Text(
                '$pct%',
                style: const TextStyle(
                  color: WsColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: WsTheme.spacingXl),

        // ── Static status pill ───────────────────────────────────────────
        // NOTE: This pill is replaced by the AnimatedSwitcher message
        // carousel in subtask-3-2.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WsTheme.spacingLg,
            vertical: WsTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: WsColors.statusRunning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(WsTheme.borderRadiusPill),
            border: Border.all(
              color: WsColors.statusRunning.withValues(alpha: 0.40),
              width: 1.0,
            ),
          ),
          child: const Text(
            'RUNNING',
            style: TextStyle(
              color: WsColors.statusRunning,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: WsTheme.spacingLg),

        // Sub-label under the pill.
        const Text(
          'Processing your workspace…',
          style: TextStyle(
            color: WsColors.textTertiary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SweepRingPainter
// ─────────────────────────────────────────────────────────────────────────────

/// [CustomPainter] that draws a two-layer progress ring:
///
/// 1. **Track** — full circle in [WsColors.glassWhite], strokeWidth = 4.
/// 2. **Arc**   — sweep arc from –π/2 using a [SweepGradient] from
///    [WsColors.accent1] to [WsColors.accent2], strokeWidth = 4.
///
/// [progress] is clamped to [0.0, 1.0].
class _SweepRingPainter extends CustomPainter {
  const _SweepRingPainter(this.progress);

  /// Fractional fill level of the arc — 0.0 means no arc, 1.0 means full circle.
  final double progress;

  static const double _strokeWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track (full circle) ────────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = WsColors.glassWhite
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // ── Sweep arc ──────────────────────────────────────────────────────────
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress == 0.0) return; // nothing to draw

    final sweepAngle = 2 * math.pi * clampedProgress;

    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        colors: [WsColors.accent1, WsColors.accent2],
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
      ).createShader(rect)
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,      // start at 12 o'clock
      sweepAngle,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_SweepRingPainter old) => old.progress != progress;
}
