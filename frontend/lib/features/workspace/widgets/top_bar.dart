import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/user_provider.dart';
import '../theme.dart';

/// Glassmorphism top bar for the workspace screen.
///
/// Shows the app title on the left and a tappable credits pill on the right.
/// Tapping the credits pill navigates to `/settings`.
///
/// Uses [BackdropFilter] + [ClipRect] for the blur background, consistent
/// with the SNOW/B612 glassmorphism design system.
class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height,
          decoration: const BoxDecoration(
            color: WsColors.surface,
            border: Border(
              bottom: BorderSide(color: WsColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // ── App Title ─────────────────────────────────────────────
                  const Text(
                    'S3',
                    style: TextStyle(
                      color: WsColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),

                  // ── Credits Pill ──────────────────────────────────────────
                  userAsync.when(
                    loading: () => const _CreditsPillSkeleton(),
                    error: (e, _) => const _CreditsPillError(),
                    data: (user) => MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.push('/settings'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: WsColors.bg.withValues(alpha: 0.85),
                            borderRadius:
                                BorderRadius.circular(WsTheme.radius),
                            border: Border.all(
                              color: WsColors.glassBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Credits bolt + count
                              const Icon(
                                Icons.bolt,
                                color: WsColors.warning,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.credits}',
                                style: const TextStyle(
                                  color: WsColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Plan badge pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (user.isPro
                                          ? WsColors.accent1
                                          : WsColors.textMuted)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                      WsTheme.radiusSm),
                                  border: Border.all(
                                    color: user.isPro
                                        ? WsColors.accent1
                                        : WsColors.textMuted,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  user.isPro ? 'PRO' : 'FREE',
                                  style: TextStyle(
                                    color: user.isPro
                                        ? WsColors.accent1
                                        : WsColors.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder shown while [userProvider] is loading.
class _CreditsPillSkeleton extends StatelessWidget {
  const _CreditsPillSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 30,
      decoration: BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(WsTheme.radius),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      ),
    );
  }
}

/// Minimal fallback shown when [userProvider] returns an error.
class _CreditsPillError extends StatelessWidget {
  const _CreditsPillError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WsColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WsTheme.radius),
        border: Border.all(
          color: WsColors.error.withValues(alpha: 0.40),
          width: 0.5,
        ),
      ),
      child: const Icon(
        Icons.person_outline,
        color: WsColors.error,
        size: 16,
      ),
    );
  }
}
