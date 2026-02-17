import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';

/// Workspace rules management section.
///
/// Renders a list of active rules and a "Save Rule" button.
/// When the user is on the Free plan and has used all rule slots,
/// the Save Rule button shows a PRO badge (provided by the parent).
class RulesSection extends ConsumerWidget {
  const RulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Active Rules',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: WsColors.textPrimary,
            ),
          ),
        ),
        if (ws.phase == WorkspacePhase.idle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Select photos to configure rules.',
              style: const TextStyle(
                fontSize: 13,
                color: WsColors.textMuted,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'No rules configured.',
              style: const TextStyle(
                fontSize: 13,
                color: WsColors.textMuted,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SaveRuleButton(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Internal "Save Rule" button widget.
///
/// The parent [MobilePipelineTabs] wraps this with a [ProBadge] when
/// the Free plan limit is reached.
class _SaveRuleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null, // Implemented in parent via ProBadge gate
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          gradient: WsColors.gradientPrimary,
          borderRadius: BorderRadius.circular(WsTheme.radiusXl),
        ),
        child: const Center(
          child: Text(
            'Save Rule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
