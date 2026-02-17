import 'dart:ui';

import 'package:flutter/material.dart';

/// Upgrade confirmation dialog shown when the user taps "Upgrade to Pro".
///
/// The CTA is a Coming-soon stub — no real payment processing occurs.
///
/// Usage:
/// ```dart
/// PlanUpgradeFlow.show(context);
/// ```
class PlanUpgradeFlow extends StatelessWidget {
  const PlanUpgradeFlow({super.key});

  /// Shows the upgrade confirmation dialog using the static [showDialog] pattern.
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const PlanUpgradeFlow(),
    );
  }

  // ─── Color / style constants ───────────────────────────────────────────────
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

  // ─── Pro plan features summary ─────────────────────────────────────────────
  static const List<_UpgradeFeature> _features = [
    _UpgradeFeature(icon: Icons.layers_rounded, label: '룰 슬롯 20개'),
    _UpgradeFeature(icon: Icons.photo_library_rounded, label: '배치 200장'),
    _UpgradeFeature(icon: Icons.sync_rounded, label: '동시 Job 3개'),
    _UpgradeFeature(icon: Icons.widgets_rounded, label: '전체 템플릿 접근'),
  ];

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _buildGlassCard(context),
      ),
    );
  }

  /// Glassmorphism card: ClipRRect → BackdropFilter → Container.
  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _glassBorder, width: 0.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 20),
              _buildFeatureList(),
              const SizedBox(height: 20),
              _buildPricingNote(),
              const SizedBox(height: 24),
              _buildConfirmButton(context),
              const SizedBox(height: 12),
              _buildCancelButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => _gradientPrimary.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Icon(
            Icons.rocket_launch_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Pro로 업그레이드',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.close_rounded,
          color: _textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Pro 플랜으로 업그레이드하면 아래 기능을 모두 사용할 수 있습니다.',
      style: TextStyle(
        color: _textSecondary,
        fontSize: 13.5,
        height: 1.4,
      ),
    );
  }

  // ─── Feature list ──────────────────────────────────────────────────────────

  Widget _buildFeatureList() {
    return Column(
      children: _features.map(_buildFeatureRow).toList(),
    );
  }

  Widget _buildFeatureRow(_UpgradeFeature feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              feature.icon,
              color: _accent,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            feature.label,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.check_circle_rounded,
            color: _success,
            size: 16,
          ),
        ],
      ),
    );
  }

  // ─── Pricing note ──────────────────────────────────────────────────────────

  Widget _buildPricingNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _accent.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => _gradientPrimary.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '가격 및 결제 방식은 준비 중입니다.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// Gradient confirm button — tapping shows "Coming soon" snackbar.
  Widget _buildConfirmButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _gradientPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onConfirmTapped(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  '업그레이드 확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        foregroundColor: _textSecondary,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        '취소',
        style: TextStyle(fontSize: 13.5),
      ),
    );
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  void _onConfirmTapped(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon 🚀  업그레이드 기능은 준비 중입니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

/// Internal data class for a single Pro feature row in the upgrade dialog.
class _UpgradeFeature {
  const _UpgradeFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
