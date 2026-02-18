import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/user_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../features/auth/models/user_model.dart';
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
            _PlanComparisonCard(user: user),
            const SizedBox(height: 24),

            // ── Preferences Section ────────────────────────────────────────
            const _SectionHeader(title: 'PREFERENCES'),
            const SizedBox(height: 12),
            const _PreferencesCard(),
            const SizedBox(height: 24),

            // ── Danger Zone ────────────────────────────────────────────────
            const _SectionHeader(title: 'SIGN OUT'),
            const SizedBox(height: 12),
            _LogoutTile(user: user),
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
    final maskedId = user.id.length > 8
        ? '${user.id.substring(0, 8)}...'
        : user.id;

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
                child: _PlanBadge(isPro: user.plan == 'pro'),
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
                    Icon(Icons.bolt, color: WsColors.warning, size: 16),
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
              _RuleSlotsRow(
                used: user.ruleSlots,
                max: user.plan == 'pro' ? 20 : 2,
              ),
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
  final int used;
  final int max;

  const _RuleSlotsRow({required this.used, required this.max});

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;

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
              '$used / $max',
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

/// Plan comparison card: FREE vs PRO two-column layout with CTA or success text.
///
/// FREE column uses accent1 header; PRO column uses accent2 header.
/// Shows gradient upgrade button when user.plan == 'free',
/// or a 'You are on Pro' success label when user.plan == 'pro'.
class _PlanComparisonCard extends StatelessWidget {
  final User user;

  const _PlanComparisonCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPro = user.plan == 'pro';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: WsTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Two-Column Comparison ──────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: _PlanColumn(isProColumn: false)),
                SizedBox(width: 12),
                Expanded(child: _PlanColumn(isProColumn: true)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── CTA or Pro Confirmation ────────────────────────────────────
          if (!isPro)
            const _UpgradeButton()
          else
            Center(
              child: Text(
                'You are on Pro',
                style: TextStyle(
                  color: WsColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single plan column (FREE or PRO) with header and feature list.
class _PlanColumn extends StatelessWidget {
  final bool isProColumn;

  const _PlanColumn({required this.isProColumn});

  @override
  Widget build(BuildContext context) {
    final headerColor = isProColumn ? WsColors.accent2 : WsColors.accent1;
    final title = isProColumn ? 'PRO' : 'FREE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(WsTheme.radiusSm),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Column Header ──────────────────────────────────────────────
          Text(
            title,
            style: TextStyle(
              color: headerColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          // ── Feature Rows ───────────────────────────────────────────────
          _FeatureRow(
            label: isProColumn ? '20 rule slots' : '2 rule slots',
          ),
          const SizedBox(height: 6),
          _FeatureRow(
            label: isProColumn ? '200 batch images' : '10 batch images',
          ),
          const SizedBox(height: 6),
          _FeatureRow(
            label: isProColumn ? '3 concurrent jobs' : '1 concurrent job',
          ),
        ],
      ),
    );
  }
}

/// Feature row with check icon and label text.
class _FeatureRow extends StatelessWidget {
  final String label;

  const _FeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: WsColors.textSecondary,
          size: 13,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: WsColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gradient CTA button for upgrading from FREE to PRO.
///
/// Uses WsColors.gradientPrimary (accent1 → accent2).
class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: WsColors.gradientPrimary,
        borderRadius: BorderRadius.circular(WsTheme.radius),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(WsTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(WsTheme.radius),
          onTap: () {
            // TODO: navigate to upgrade / billing page
          },
          child: const Center(
            child: Text(
              'Upgrade to Pro',
              style: TextStyle(
                color: WsColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
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
///
/// If user has active jobs, shows a confirmation AlertDialog first.
/// Uses GestureDetector so the entire tile area is tappable.
class _LogoutTile extends ConsumerWidget {
  final User user;

  const _LogoutTile({required this.user});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Always show simple logout confirmation
    {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: WsColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WsTheme.radiusLg),
            side: const BorderSide(color: WsColors.glassBorder, width: 0.5),
          ),
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              color: WsColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: const TextStyle(
              color: WsColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: WsColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Logout',
                style: TextStyle(color: WsColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: WsTheme.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WsTheme.radius),
        child: GestureDetector(
          onTap: () => _handleLogout(context, ref),
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

/// Preferences card — dark mode toggle and app version info.
///
/// Dark Mode row: tapping the Switch calls themeNotifierProvider.notifier.toggle().
/// App Version row: displays the current version string right-aligned.
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
      child: Column(
        children: [
          // ── Dark Mode Toggle ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.dark_mode,
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
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggle(),
                activeThumbColor: WsColors.accent1,
              ),
            ],
          ),

          const Divider(
            color: WsColors.glassBorder,
            height: 1,
            thickness: 0.5,
          ),

          // ── App Version ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: const [
                Icon(
                  Icons.info_outline,
                  color: WsColors.textSecondary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App Version',
                    style: TextStyle(
                      color: WsColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  'v0.1.0-beta',
                  style: TextStyle(
                    color: WsColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
