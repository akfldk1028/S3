import 'dart:ui';

import 'package:flutter/material.dart';

/// Data class representing a single feature row in a pricing card.
class PricingFeatureRow {
  const PricingFeatureRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
}

/// A glassmorphism pricing card widget that supports:
/// - Gradient border for recommended (Pro) plan
/// - Recommended badge ('추천') via ShaderMask gradient text
/// - Current-plan badge ('현재 플랜 ✓') with success color
/// - Feature rows with icon + label + value layout
/// - Upgrade CTA (gradient background, disabled when isCurrentPlan)
/// - Top-up button (outlined, only shown on current plan card when onTopup provided)
class PricingCard extends StatelessWidget {
  const PricingCard({
    super.key,
    required this.planName,
    required this.price,
    required this.features,
    this.isRecommended = false,
    this.isCurrentPlan = false,
    this.onUpgrade,
    this.onTopup,
  });

  final String planName;
  final String price;
  final List<PricingFeatureRow> features;
  final bool isRecommended;
  final bool isCurrentPlan;
  final VoidCallback? onUpgrade;
  final VoidCallback? onTopup;

  // ─── Color constants ───────────────────────────────────────────────────────
  static const _cardBg = Color(0xFF1A1F2E);
  static const _glassBorder = Color(0x33FFFFFF);
  static const _textPrimary = Color(0xFFE2E8F0);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _accent = Color(0xFF6366F1);
  static const _success = Color(0xFF22C55E);

  static const _gradientPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double _radius = 16;
  static const double _gradientBorderWidth = 1.5;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isRecommended) {
      return _buildGradientBorderCard();
    }
    return _buildStandardCard();
  }

  /// Pro card: outer gradient container acts as border via padding trick.
  Widget _buildGradientBorderCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: _gradientPrimary,
        borderRadius: BorderRadius.circular(_radius + _gradientBorderWidth),
      ),
      padding: const EdgeInsets.all(_gradientBorderWidth),
      child: _buildCardContent(innerRadius: _radius),
    );
  }

  /// Free card: standard glass container with subtle border.
  Widget _buildStandardCard() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _glassBorder, width: 0.5),
      ),
      child: _buildCardContent(innerRadius: _radius),
    );
  }

  /// Glassmorphism card content:
  /// ClipRRect → BackdropFilter (blur) → semi-transparent Container → column.
  Widget _buildCardContent({required double innerRadius}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(innerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(innerRadius),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildPrice(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildFeatureList(),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended) ...[
                _buildRecommendedBadge(),
                const SizedBox(height: 6),
              ],
              Text(
                planName,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        if (isCurrentPlan) ...[
          const SizedBox(width: 8),
          _buildCurrentPlanBadge(),
        ],
      ],
    );
  }

  /// '추천' badge — gradient text via ShaderMask.
  Widget _buildRecommendedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _accent.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => _gradientPrimary.createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: const Text(
          '추천',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// '현재 플랜 ✓' badge with success green.
  Widget _buildCurrentPlanBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _success.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: const Text(
        '현재 플랜 ✓',
        style: TextStyle(
          color: _success,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Price ─────────────────────────────────────────────────────────────────

  Widget _buildPrice() {
    return Text(
      price,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  // ─── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Divider(
      color: _glassBorder,
      height: 1,
      thickness: 0.5,
    );
  }

  // ─── Feature List ──────────────────────────────────────────────────────────

  Widget _buildFeatureList() {
    return Column(
      children: features.map(_buildFeatureRow).toList(),
    );
  }

  Widget _buildFeatureRow(PricingFeatureRow feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            feature.icon ?? Icons.check_circle_outline_rounded,
            color: _accent,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature.label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            feature.value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCurrentPlan) ...[
          _buildCurrentPlanButton(),
          if (onTopup != null) ...[
            const SizedBox(height: 8),
            _buildTopupButton(),
          ],
        ] else ...[
          _buildUpgradeButton(),
        ],
      ],
    );
  }

  /// Gradient upgrade button — disabled (grey) when isCurrentPlan is true.
  Widget _buildUpgradeButton() {
    final bool enabled = !isCurrentPlan && onUpgrade != null;

    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? _gradientPrimary : null,
        color: enabled ? null : _textSecondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onUpgrade : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                'Pro로 업그레이드',
                style: TextStyle(
                  color: enabled ? Colors.white : _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Static "현재 플랜 ✓" display — not tappable.
  Widget _buildCurrentPlanButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: _success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _success.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: const Center(
        child: Text(
          '현재 플랜 ✓',
          style: TextStyle(
            color: _success,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Ghost/outlined top-up button — shown only on current plan card.
  Widget _buildTopupButton() {
    return OutlinedButton(
      onPressed: onTopup,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: _glassBorder, width: 0.8),
        foregroundColor: _textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        '크레딧 충전',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
