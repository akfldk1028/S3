import 'dart:math' as math;

import 'package:flutter/material.dart';

// SNOW dark theme colour palette (mirrors WsColors from workspace theme).
class _Colors {
  _Colors._();

  static const bg = Color(0xFF0F0F17);
  static const surface = Color(0xFF1A1A2E);
  static const accent1 = Color(0xFF6C63FF);
  static const accent2 = Color(0xFF00D4FF);
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF8888A0);
  static const glassWhite = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);
}

/// Onboarding Page 1 – introduces the **Domain Palette** concept.
///
/// Features:
/// - SNOW-style dark background.
/// - Animated gradient orb illustration (pure Flutter, no Lottie).
/// - Korean title 「도메인 팔레트」.
/// - Explanatory subtitle.
class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Colors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              _IllustrationCard(
                rotateAnim: _rotateAnim,
                scaleAnim: _scaleAnim,
                fadeAnim: _fadeAnim,
              ),
              const Spacer(flex: 1),
              _TitleSection(),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Illustration
// ---------------------------------------------------------------------------

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({
    required this.rotateAnim,
    required this.scaleAnim,
    required this.fadeAnim,
  });

  final Animation<double> rotateAnim;
  final Animation<double> scaleAnim;
  final Animation<double> fadeAnim;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: _Colors.glassWhite,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _Colors.glassBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(31),
          child: AnimatedBuilder(
            animation: Listenable.merge([rotateAnim, scaleAnim]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background fill
                  Container(color: _Colors.surface),
                  // Animated gradient orb
                  Transform.scale(
                    scale: scaleAnim.value,
                    child: Transform.rotate(
                      angle: rotateAnim.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              _Colors.accent1,
                              _Colors.accent2,
                              Color(0xFF00FFB2),
                              _Colors.accent1,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Frosted-glass overlay with palette icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _Colors.glassWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _Colors.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.palette_outlined,
                      color: _Colors.textPrimary,
                      size: 46,
                    ),
                  ),
                  // Decorative colour chips
                  ..._buildColorChips(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildColorChips() {
    const chips = [
      (offset: Offset(-80, -70), color: _Colors.accent1),
      (offset: Offset(80, -60), color: _Colors.accent2),
      (offset: Offset(-75, 72), color: Color(0xFF00FFB2)),
      (offset: Offset(78, 68), color: Color(0xFFFF6B6B)),
    ];

    return chips
        .map(
          (c) => Positioned(
            left: 130 + c.offset.dx,
            top: 130 + c.offset.dy,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: c.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.color.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Title + subtitle
// ---------------------------------------------------------------------------

class _TitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '도메인 팔레트',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: _Colors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          '당신만의 색상 팔레트로\n브랜드 아이덴티티를 완성하세요.\n도메인별로 맞춤 설정된 색상이\n일관된 디자인을 만들어 드립니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _Colors.textSecondary,
                height: 1.6,
              ),
        ),
      ],
    );
  }
}
