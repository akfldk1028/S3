import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/queries/get_me_query.dart';
import '../theme.dart';

/// Top navigation bar shown when photos are selected.
///
/// Displays the app name and user credit balance.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(getMeQueryProvider);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: WsColors.surface,
        border: Border(
          bottom: BorderSide(
            color: WsColors.textMuted.withValues(alpha: 0.2),
            width: 0.5,
          ),
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
          userAsync.when(
            data: (user) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WsColors.surfaceLight,
                borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                border: Border.all(
                  color: WsColors.textMuted.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: WsColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: WsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              width: 80,
              height: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: WsColors.surfaceLight,
                  borderRadius:
                      BorderRadius.all(Radius.circular(WsTheme.radiusSm)),
                ),
              ),
            ),
            error: (e, _) => const Icon(
              Icons.person_outline,
              color: WsColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: WsColors.textSecondary,
              size: 20,
            ),
            tooltip: 'History',
            onPressed: () => context.push('/history'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
