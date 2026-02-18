import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_provider.dart';
import '../theme.dart';
import 'mobile_pipeline_tabs.dart';

/// Top navigation bar shown when photos are selected.
///
/// Displays the app name and a tappable credits pill showing the user's
/// current credit balance. Tapping the pill opens [PlanComparisonSheet].
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: WsColors.surface,
        border: Border(
          bottom: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'S3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: WsColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          // Credits pill — tapping opens PlanComparisonSheet.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => PlanComparisonSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WsColors.glassWhite,
                borderRadius: BorderRadius.circular(WsTheme.radiusXl),
                border: Border.all(color: WsColors.glassBorder, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: WsTheme.iconSizeSm,
                    color: WsColors.accent1,
                  ),
                  const SizedBox(width: 4),
                  userAsync.when(
                    data: (user) => Text(
                      '${user.credits}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WsColors.textPrimary,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 32,
                      height: 13,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: WsColors.glassWhite,
                          borderRadius:
                              BorderRadius.all(Radius.circular(WsTheme.radiusSm)),
                        ),
                      ),
                    ),
                    error: (e, _) => const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: WsColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
