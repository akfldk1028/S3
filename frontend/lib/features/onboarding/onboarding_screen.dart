import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_provider.dart';
import 'widgets/onboarding_page_1.dart';
import 'widgets/onboarding_page_2.dart';
import 'widgets/onboarding_page_3.dart';

// SNOW dark theme colour palette.
class _Colors {
  _Colors._();

  static const bg = Color(0xFF0F0F17);
  static const accent1 = Color(0xFF6C63FF);
  static const accent2 = Color(0xFF00D4FF);
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF8888A0);
  static const glassWhite = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
}

/// Host screen for the 3-page onboarding flow.
///
/// - Wraps a [PageView] driven by a [PageController].
/// - [PopScope] prevents hardware back navigation escaping the flow.
/// - Dots indicator reflects the current page.
/// - Skip button visible on pages 1–2, hidden on page 3.
/// - CTA: "다음" on pages 1–2, "시작하기" on page 3.
/// - [_isNavigating] guard prevents duplicate navigation calls.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isNavigating = false;

  static const int _totalPages = 3;

  static const List<Widget> _pages = [
    OnboardingPage1(),
    OnboardingPage2(),
    OnboardingPage3(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await ref.read(onboardingProvider.notifier).completeOnboarding();

    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _goToNextPage() async {
    if (_isNavigating) return;

    if (_currentPage < _totalPages - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _totalPages - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _Colors.bg,
        body: Stack(
          children: [
            // ── PageView ─────────────────────────────────────────────────────
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _pages,
            ),

            // ── Skip button (top-right, hidden on last page) ──────────────
            if (!isLastPage)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 20,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: _Colors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),

            // ── Bottom controls ───────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dots indicator
                  _DotsIndicator(
                    totalPages: _totalPages,
                    currentPage: _currentPage,
                  ),
                  const SizedBox(height: 28),

                  // CTA button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _GradientButton(
                      label: isLastPage ? '시작하기' : '다음',
                      onPressed: _goToNextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dots indicator
// ─────────────────────────────────────────────────────────────────────────────

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.totalPages,
    required this.currentPage,
  });

  final int totalPages;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive
                ? const LinearGradient(
                    colors: [_Colors.accent1, _Colors.accent2],
                  )
                : null,
            color: isActive ? null : _Colors.glassWhite,
            border: Border.all(
              color: isActive ? Colors.transparent : _Colors.glassBorder,
              width: 1,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_Colors.accent1, _Colors.accent2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x406C63FF),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: _Colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
