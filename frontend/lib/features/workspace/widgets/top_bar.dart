import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_provider.dart';
import '../theme.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: WsColors.bg.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(color: WsColors.glassBorder, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Logo with gradient
              ShaderMask(
                shaderCallback: (bounds) =>
                    WsColors.gradientPrimary.createShader(bounds),
                child: const Text(
                  'S3',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Studio',
                style: TextStyle(
                  fontSize: 14,
                  color: WsColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              // Credits pill
              userAsync.when(
                data: (user) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: WsColors.glassWhite,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: WsColors.glassBorder, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: user.plan == 'pro'
                              ? WsColors.accent2
                              : WsColors.accent1,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.plan.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: WsColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: WsColors.glassBorder,
                      ),
                      const Icon(Icons.bolt, size: 13, color: WsColors.warning),
                      const SizedBox(width: 3),
                      Text(
                        '${user.credits}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: WsColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: WsColors.accent1,
                  ),
                ),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
