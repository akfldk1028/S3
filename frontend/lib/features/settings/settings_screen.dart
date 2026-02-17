import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/user_provider.dart';
import '../../core/models/user.dart';
import '../../core/providers/theme_provider.dart';
import '../workspace/theme.dart';

/// Settings / Profile screen.
///
/// Displays user account information, plan comparison CTA,
/// dark mode toggle, app version, and logout.
///
/// Navigation: pushed via `context.push('/settings')` from the TopBar.
/// Back navigation uses `context.pop()`.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: WsColors.bg,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(context),
      body: userAsync.when(
        loading: _buildLoading,
        error: (error, stackTrace) => _buildError(context, ref, error),
        data: (user) => _buildBody(context, ref, user),
      ),
    );
  }

  /// Glassmorphism AppBar: blurred surface background + glassBorder bottom line.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: WsColors.surface,
              border: Border(
                bottom: BorderSide(color: WsColors.glassBorder, width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: WsColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: WsColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Centered loading indicator while userProvider resolves.
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(WsColors.accent1),
      ),
    );
  }

  /// Error state with descriptive message and retry button.
  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: WsColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(
                color: WsColors.error,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WsColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(userProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: WsColors.accent1,
                foregroundColor: WsColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(WsTheme.radius),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Main scrollable body shown when user data is available.
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Info Section ──────────────────────────────────────────
            const _SectionHeader(title: 'ACCOUNT'),
            const SizedBox(height: 12),
            _UserInfoCard(user: user),
            const SizedBox(height: 24),

            // ── Plan Section ───────────────────────────────────────────────
            const _SectionHeader(title: 'PLAN'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: WsTheme.cardDecoration,
              child: const Text(
                'Plan comparison — coming in next subtask',
                style: TextStyle(
                  color: WsColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Preferences Section ────────────────────────────────────────
            const _SectionHeader(title: 'PREFERENCES'),
            const SizedBox(height: 12),
            const _PreferencesCard(),
            const SizedBox(height: 24),

            // ── Danger Zone ────────────────────────────────────────────────
            const _SectionHeader(title: 'SIGN OUT'),
            const SizedBox(height: 12),
            const _LogoutTile(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphism user info card.
///
/// Displays masked userId, plan badge pill, credits count with bolt icon,
/// and rule slots usage with a linear progress indicator.
class _UserInfoCard extends StatelessWidget {
  final User user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final maskedId = user.userId.length > 8
        ? '${user.userId.substring(0, 8)}...'
        : user.userId;

    return ClipRRect(
      borderRadius: BorderRadius.circular(WsTheme.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: WsColors.bg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(WsTheme.radius),
            border: Border.all(color: WsColors.glassBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: User ID ─────────────────────────────────────────
              _InfoRow(
                label: 'User ID',
                child: Text(
                  maskedId,
                  style: const TextStyle(
                    color: WsColors.textPrimary,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Divider(
                color: WsColors.glassBorder,
                height: 24,
                thickness: 0.5,
              ),

              // ── Row 2: Plan Badge ──────────────────────────────────────
              _InfoRow(
                label: 'Plan',
                child: _PlanBadge(isPro: user.isPro),
              ),
              const Divider(
                color: WsColors.glassBorder,
                height: 24,
                thickness: 0.5,
              ),

              // ── Row 3: Credits ─────────────────────────────────────────
              _InfoRow(
                label: 'Credits',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: WsColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${user.credits}',
                      style: const TextStyle(
                        color: WsColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: WsColors.glassBorder,
                height: 24,
                thickness: 0.5,
              ),

              // ── Row 4: Rule Slots ──────────────────────────────────────
              _RuleSlotsRow(ruleSlots: user.ruleSlots),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label + trailing widget row used inside info cards.
class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: WsColors.textSecondary,
            fontSize: 13,
          ),
        ),
        child,
      ],
    );
  }
}

/// Pill badge showing FREE or PRO with appropriate accent color.
class _PlanBadge extends StatelessWidget {
  final bool isPro;

  const _PlanBadge({required this.isPro});

  @override
  Widget build(BuildContext context) {
    final badgeColor = isPro ? WsColors.accent1 : WsColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(WsTheme.radiusSm),
        border: Border.all(color: badgeColor, width: 0.5),
      ),
      child: Text(
        isPro ? 'PRO' : 'FREE',
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Rule slots row: label + used/max text + linear progress indicator.
class _RuleSlotsRow extends StatelessWidget {
  final RuleSlots ruleSlots;

  const _RuleSlotsRow({required this.ruleSlots});

  @override
  Widget build(BuildContext context) {
    final fraction = ruleSlots.max > 0
        ? (ruleSlots.used / ruleSlots.max).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rule Slots',
              style: TextStyle(
                color: WsColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Text(
              '${ruleSlots.used} / ${ruleSlots.max}',
              style: const TextStyle(
                color: WsColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(WsTheme.radiusSm),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: WsColors.glassBorder,
            valueColor:
                const AlwaysStoppedAnimation<Color>(WsColors.accent1),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

/// Section header label — small caps, muted color.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: WsColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Logout row — tapping calls authProvider.logout() and navigates to /auth.
/// Full confirmation dialog is added in subtask-2-4.
class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: WsTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(WsTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(WsTheme.radius),
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/auth');
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.logout, color: WsColors.error, size: 20),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: WsColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Preferences card — dark mode toggle placeholder.
class _PreferencesCard extends ConsumerWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: WsTheme.cardDecoration,
      child: Row(
        children: [
          const Icon(
            Icons.dark_mode_outlined,
            color: WsColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(
                color: WsColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            activeThumbColor: WsColors.accent1,
          ),
        ],
      ),
    );
  }
}
