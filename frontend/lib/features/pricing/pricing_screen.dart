import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/pages/providers/auth_provider.dart';
import 'widgets/credit_topup_dialog.dart';
import 'widgets/plan_upgrade_flow.dart';
import 'widgets/pricing_card.dart';

/// Main pricing comparison screen showing Free vs Pro plans.
///
/// Uses [authStateProvider] to determine authentication status and defaults
/// to 'free' plan. Responsive layout via [LayoutBuilder]:
/// - Mobile (< 600 px): cards stacked in a [Column]
/// - Desktop (≥ 600 px): cards side-by-side in a [Row]
class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  // ─── Color constants (consistent with other pricing widgets) ─────────────
  static const _bg = Color(0xFF0F172A);
  static const _textPrimary = Color(0xFFE2E8F0);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _accent = Color(0xFF6366F1);

  // ─── Plan feature definitions ────────────────────────────────────────────

  static const List<PricingFeatureRow> _freeFeatures = [
    PricingFeatureRow(
      label: '룰 슬롯',
      value: '2개',
      icon: Icons.layers_rounded,
    ),
    PricingFeatureRow(
      label: '배치 이미지',
      value: '10장',
      icon: Icons.photo_library_rounded,
    ),
    PricingFeatureRow(
      label: '동시 Job',
      value: '1개',
      icon: Icons.sync_rounded,
    ),
    PricingFeatureRow(
      label: '템플릿',
      value: '기본',
      icon: Icons.widgets_rounded,
    ),
  ];

  static const List<PricingFeatureRow> _proFeatures = [
    PricingFeatureRow(
      label: '룰 슬롯',
      value: '20개',
      icon: Icons.layers_rounded,
    ),
    PricingFeatureRow(
      label: '배치 이미지',
      value: '200장',
      icon: Icons.photo_library_rounded,
    ),
    PricingFeatureRow(
      label: '동시 Job',
      value: '3개',
      icon: Icons.sync_rounded,
    ),
    PricingFeatureRow(
      label: '템플릿',
      value: '전체',
      icon: Icons.widgets_rounded,
    ),
  ];

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => _buildLoadingScaffold(context),
      error: (_, _) => _buildContentScaffold(context, currentPlan: ''),
      data: (isLoggedIn) => _buildContentScaffold(
        context,
        // No plan field on User model yet — authenticated users default to free.
        currentPlan: isLoggedIn ? 'free' : '',
      ),
    );
  }

  // ─── Loading scaffold ────────────────────────────────────────────────────

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: const Center(
        child: CircularProgressIndicator(color: _accent),
      ),
    );
  }

  // ─── Content scaffold ────────────────────────────────────────────────────

  Widget _buildContentScaffold(
    BuildContext context, {
    required String currentPlan,
  }) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 600) {
                    return _buildDesktopLayout(context, currentPlan);
                  }
                  return _buildMobileLayout(context, currentPlan);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      foregroundColor: _textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        color: _textSecondary,
        onPressed: () => context.pop(),
        tooltip: '뒤로',
      ),
      title: const Text(
        'S3 플랜',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ─── Header section ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '플랜 비교',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Free와 Pro 플랜을 비교하고 업그레이드하세요.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─── Responsive layouts ──────────────────────────────────────────────────

  /// Desktop layout: cards side-by-side with equal width.
  Widget _buildDesktopLayout(BuildContext context, String currentPlan) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildFreeCard(context, currentPlan)),
          const SizedBox(width: 16),
          Expanded(child: _buildProCard(context, currentPlan)),
        ],
      ),
    );
  }

  /// Mobile layout: cards stacked vertically.
  Widget _buildMobileLayout(BuildContext context, String currentPlan) {
    return Column(
      children: [
        _buildFreeCard(context, currentPlan),
        const SizedBox(height: 16),
        _buildProCard(context, currentPlan),
      ],
    );
  }

  // ─── Plan cards ──────────────────────────────────────────────────────────

  Widget _buildFreeCard(BuildContext context, String currentPlan) {
    final bool isCurrent = currentPlan == 'free';
    return PricingCard(
      planName: 'Free',
      price: '\$0 / 월',
      features: _freeFeatures,
      isRecommended: false,
      isCurrentPlan: isCurrent,
      onUpgrade: isCurrent ? null : () => PlanUpgradeFlow.show(context),
      onTopup: isCurrent ? () => CreditTopupDialog.show(context) : null,
    );
  }

  Widget _buildProCard(BuildContext context, String currentPlan) {
    final bool isCurrent = currentPlan == 'pro';
    return PricingCard(
      planName: 'Pro',
      price: 'Coming soon',
      features: _proFeatures,
      isRecommended: true,
      isCurrentPlan: isCurrent,
      onUpgrade: isCurrent ? null : () => PlanUpgradeFlow.show(context),
      onTopup: isCurrent ? () => CreditTopupDialog.show(context) : null,
    );
  }
}
