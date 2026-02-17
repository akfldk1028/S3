import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

/// Desktop side panel showing palette configuration, rules, and settings.
///
/// Only shown on viewports >= 600 px wide. On mobile, settings are
/// accessible via [MobileBottomSheet].
class SidePanel extends ConsumerWidget {
  const SidePanel({super.key});

  static const double kWidth = 280.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: kWidth,
      decoration: const BoxDecoration(
        color: WsColors.surface,
        border: Border(
          right: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      child: const Center(
        child: Text(
          'Settings',
          style: TextStyle(
            color: WsColors.textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
