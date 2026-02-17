import 'package:flutter/material.dart';

import '../../workspace/theme.dart';

/// A small colored chip that displays a job status string.
///
/// Color mapping:
///   done      → WsColors.success
///   failed    → WsColors.error
///   canceled  → WsColors.error
///   running   → WsColors.accent1
///   queued    → WsColors.accent1
///   (other)   → WsColors.textMuted
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _colorForStatus(String s) {
    switch (s) {
      case 'done':
        return WsColors.success;
      case 'failed':
      case 'canceled':
        return WsColors.error;
      case 'running':
      case 'queued':
        return WsColors.accent1;
      default:
        return WsColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
