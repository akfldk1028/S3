import 'dart:ui';

import 'package:flutter/material.dart';

/// Represents a credit package option in the top-up dialog.
class _CreditPackage {
  const _CreditPackage({
    required this.credits,
    required this.label,
    required this.price,
    this.isBestValue = false,
  });

  final int credits;
  final String label;
  final String price;
  final bool isBestValue;
}

/// Modal dialog that presents credit package options and a Coming-soon CTA.
///
/// Usage:
/// ```dart
/// CreditTopupDialog.show(context);
/// ```
class CreditTopupDialog extends StatefulWidget {
  const CreditTopupDialog({super.key});

  /// Shows the dialog using the static [showDialog] pattern.
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const CreditTopupDialog(),
    );
  }

  @override
  State<CreditTopupDialog> createState() => _CreditTopupDialogState();
}

class _CreditTopupDialogState extends State<CreditTopupDialog> {
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

  // ─── Packages ──────────────────────────────────────────────────────────────
  static const List<_CreditPackage> _packages = [
    _CreditPackage(
      credits: 100,
      label: '100 크레딧',
      price: '\$0.99',
    ),
    _CreditPackage(
      credits: 500,
      label: '500 크레딧',
      price: '\$3.99',
      isBestValue: true,
    ),
    _CreditPackage(
      credits: 1000,
      label: '1,000 크레딧',
      price: '\$6.99',
    ),
  ];

  int _selectedIndex = 1; // default: best-value package

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: _buildGlassCard(),
      ),
    );
  }

  /// Glassmorphism card: ClipRRect → BackdropFilter → Container.
  Widget _buildGlassCard() {
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
              _buildHeader(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 24),
              _buildPackageList(),
              const SizedBox(height: 24),
              _buildPurchaseButton(),
              const SizedBox(height: 12),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => _gradientPrimary.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '크레딧 충전',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildCloseButton() {
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
      '사용하실 크레딧 패키지를 선택해 주세요.',
      style: TextStyle(
        color: _textSecondary,
        fontSize: 13.5,
        height: 1.4,
      ),
    );
  }

  // ─── Package List ──────────────────────────────────────────────────────────

  Widget _buildPackageList() {
    return Column(
      children: List.generate(_packages.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < _packages.length - 1 ? 10 : 0,
          ),
          child: _buildPackageTile(index),
        );
      }),
    );
  }

  Widget _buildPackageTile(int index) {
    final package = _packages[index];
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? _accent.withValues(alpha: 0.15)
              : _cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? _accent.withValues(alpha: 0.6)
                : _glassBorder,
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _accent : _glassBorder,
                  width: 1.5,
                ),
                color: isSelected ? _accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Credits icon + label
            Icon(
              Icons.bolt_rounded,
              color: isSelected ? _accent : _textSecondary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                package.label,
                style: TextStyle(
                  color: isSelected ? _textPrimary : _textSecondary,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            // Best-value badge
            if (package.isBestValue) ...[
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _success.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  '최고 가성비',
                  style: TextStyle(
                    color: _success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            // Price
            Text(
              package.price,
              style: TextStyle(
                color: isSelected ? _textPrimary : _textSecondary,
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// Gradient purchase button — tapping shows "Coming soon" snackbar.
  Widget _buildPurchaseButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _gradientPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _onPurchaseTapped,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_packages[_selectedIndex].label} 구매',
                  style: const TextStyle(
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

  Widget _buildCancelButton() {
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

  void _onPurchaseTapped() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon 🚀  결제 기능은 준비 중입니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
