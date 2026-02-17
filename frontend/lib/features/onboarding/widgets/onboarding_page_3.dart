import 'package:flutter/material.dart';

// SNOW dark theme colour palette (mirrors WsColors from workspace theme).
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

/// Onboarding Page 3 – **Plan Selection** (Free vs Pro).
///
/// Features:
/// - SNOW-style dark background.
/// - Animated glass-morphism plan comparison cards (pure Flutter, no Lottie).
/// - Korean title 「플랜 선택」.
/// - Free: 2 rules / 10 images / 1 job.
/// - Pro:  20 rules / 200 images / 3 jobs.
class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              _PlanComparisonCards(
                shimmerAnim: _shimmerAnim,
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
// Plan comparison cards illustration
// ---------------------------------------------------------------------------

class _PlanComparisonCards extends StatelessWidget {
  const _PlanComparisonCards({
    required this.shimmerAnim,
    required this.fadeAnim,
  });

  final Animation<double> shimmerAnim;
  final Animation<double> fadeAnim;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: AnimatedBuilder(
        animation: shimmerAnim,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanCard(
                label: 'Free',
                icon: Icons.star_border_rounded,
                iconColor: _Colors.textSecondary,
                borderColor: _Colors.glassBorder,
                gradientColors: const [
                  Color(0x1AFFFFFF),
                  Color(0x0DFFFFFF),
                ],
                shimmer: shimmerAnim.value,
                features: const [
                  ('룰', '2개'),
                  ('이미지', '10장'),
                  ('작업', '1개'),
                ],
                isHighlighted: false,
              ),
              const SizedBox(width: 12),
              _PlanCard(
                label: 'Pro',
                icon: Icons.star_rounded,
                iconColor: _Colors.accent2,
                borderColor: _Colors.accent1,
                gradientColors: [
                  _Colors.accent1.withValues(alpha: 0.25),
                  _Colors.accent2.withValues(alpha: 0.12),
                ],
                shimmer: shimmerAnim.value,
                features: const [
                  ('룰', '20개'),
                  ('이미지', '200장'),
                  ('작업', '3개'),
                ],
                isHighlighted: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.gradientColors,
    required this.shimmer,
    required this.features,
    required this.isHighlighted,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final List<Color> gradientColors;
  final double shimmer;
  final List<(String, String)> features;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final glowOpacity = isHighlighted ? (0.2 + shimmer * 0.3) : 0.0;
    final borderWidth = isHighlighted ? (1.0 + shimmer * 0.8) : 1.0;

    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: _Colors.accent1.withValues(alpha: glowOpacity),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Plan icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Colors.glassWhite,
              shape: BoxShape.circle,
              border: Border.all(color: _Colors.glassBorder, width: 1.2),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 12),
          // Plan label
          Text(
            label,
            style: const TextStyle(
              color: _Colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          // Feature rows
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FeatureRow(name: f.$1, value: f.$2),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: _Colors.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _Colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
          '플랜 선택',
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
          'Free로 시작하고 언제든 Pro로 업그레이드하세요.\nPro는 더 많은 룰, 이미지, 동시 작업을\n지원하여 대규모 프로젝트에 최적화됩니다.',
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
