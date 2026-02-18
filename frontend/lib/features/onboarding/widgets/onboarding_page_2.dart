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

/// Onboarding Page 2 – introduces **Rules-based Set Production**.
///
/// Features:
/// - SNOW-style dark background.
/// - Animated rules-chain illustration (pure Flutter, no Lottie).
/// - Korean title 「룰로 세트 생산」.
/// - Explanatory subtitle about AI automatic image set production.
class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key});

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _flowAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _flowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
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
                pulseAnim: _pulseAnim,
                flowAnim: _flowAnim,
                fadeAnim: _fadeAnim,
              ),
              const Spacer(flex: 1),
              const _TitleSection(),
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
    required this.pulseAnim,
    required this.flowAnim,
    required this.fadeAnim,
  });

  final Animation<double> pulseAnim;
  final Animation<double> flowAnim;
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
            animation: Listenable.merge([pulseAnim, flowAnim]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background fill
                  Container(color: _Colors.surface),
                  // Animated radial gradient background
                  Transform.scale(
                    scale: pulseAnim.value,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _Colors.accent1.withValues(alpha: 0.4),
                            _Colors.accent2.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Central settings/rule icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _Colors.glassWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _Colors.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Transform.rotate(
                      angle: flowAnim.value * math.pi * 0.25,
                      child: const Icon(
                        Icons.tune_rounded,
                        color: _Colors.textPrimary,
                        size: 38,
                      ),
                    ),
                  ),
                  // Orbiting rule nodes
                  ..._buildRuleNodes(flowAnim.value),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRuleNodes(double progress) {
    const nodes = [
      (angle: 0.0, icon: Icons.image_outlined, color: _Colors.accent1),
      (
        angle: math.pi * 2 / 3,
        icon: Icons.auto_awesome_outlined,
        color: _Colors.accent2,
      ),
      (
        angle: math.pi * 4 / 3,
        icon: Icons.collections_outlined,
        color: Color(0xFF00FFB2),
      ),
    ];

    const orbitRadius = 88.0;
    const center = Offset(130, 130);

    return nodes.map((n) {
      final angle = n.angle + progress * math.pi * 0.4;
      final x = center.dx + orbitRadius * math.cos(angle) - 18;
      final y = center.dy + orbitRadius * math.sin(angle) - 18;

      return Positioned(
        left: x,
        top: y,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: n.color.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: n.color.withValues(alpha: 0.7), width: 1),
            boxShadow: [
              BoxShadow(
                color: n.color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(n.icon, color: n.color, size: 18),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Title + subtitle
// ---------------------------------------------------------------------------

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '룰로 세트 생산',
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
          '규칙만 설정하면 AI가 알아서\n이미지 세트를 자동으로 생산합니다.\n반복 작업 없이 일관된 품질의\n콘텐츠를 손쉽게 만들어 보세요.',
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
