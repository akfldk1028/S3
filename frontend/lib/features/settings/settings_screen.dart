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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: WsTheme.cardDecoration,
              child: const Text(
                'User info — coming in next subtask',
                style: TextStyle(
                  color: WsColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
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
