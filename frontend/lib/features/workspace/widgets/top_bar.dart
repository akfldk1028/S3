import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/pages/providers/auth_provider.dart';

/// Top app bar widget with a tappable credits/plan badge.
///
/// The credits pill shows the current plan label and a credits indicator.
/// Tapping the pill navigates to ['/pricing'] via GoRouter push so that the
/// pricing screen can be dismissed with the system back button.
///
/// The pill is wrapped in a [MouseRegion] with [SystemMouseCursors.click] for
/// proper hover feedback on web/desktop.
class TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.title = 'S3'});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // ─── Color constants (consistent with other pricing / workspace widgets) ──
  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1A1F2E);
  static const _glassBorder = Color(0x33FFFFFF);
  static const _textPrimary = Color(0xFFE2E8F0);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _accent = Color(0xFF6366F1);

  static const _gradientPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: _buildLogo(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: authAsync.when(
            loading: _buildLoadingIndicator,
            error: (err, st) => const SizedBox.shrink(),
            data: (isLoggedIn) => isLoggedIn
                ? _buildCreditsPill(context)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ─── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return ShaderMask(
      shaderCallback: (bounds) => _gradientPrimary.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ─── Loading indicator ─────────────────────────────────────────────────────

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: _accent,
      ),
    );
  }

  // ─── Credits pill (tappable) ───────────────────────────────────────────────

  /// Credits pill: plan dot • plan label | ⚡ credits count.
  ///
  /// Wrapped in [MouseRegion] (pointer cursor on web) +
  /// [GestureDetector] (tap → push '/pricing').
  Widget _buildCreditsPill(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/pricing'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Plan dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  gradient: _gradientPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              // Plan label
              const Text(
                'Free',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: _glassBorder,
              ),
              // Bolt icon
              const Icon(
                Icons.bolt_rounded,
                size: 14,
                color: _accent,
              ),
              const SizedBox(width: 3),
              // Credits count
              const Text(
                '0',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
