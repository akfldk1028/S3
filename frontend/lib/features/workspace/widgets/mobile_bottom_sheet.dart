import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

/// Modal bottom sheet shown on mobile to access palette and settings.
///
/// Triggered by the FAB in [WorkspaceScreen] on viewports < 600 px.
/// On desktop, the same controls are visible in [SidePanel] inline.
class MobileBottomSheet extends ConsumerWidget {
  const MobileBottomSheet({super.key});

  /// Shows the mobile bottom sheet as a modal over [context].
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MobileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: WsColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(WsTheme.radiusLg),
        ),
        border: const Border(
          top: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WsColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: WsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Configure palette and rules here.',
            style: TextStyle(
              fontSize: 14,
              color: WsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
