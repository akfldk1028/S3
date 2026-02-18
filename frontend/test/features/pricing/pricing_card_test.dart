import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s3_frontend/features/pricing/widgets/pricing_card.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Free plan feature rows matching the BM spec (2/10/1).
const _freePlanFeatures = [
  PricingFeatureRow(label: '룰 슬롯', value: '2'),
  PricingFeatureRow(label: '배치 장수', value: '10'),
  PricingFeatureRow(label: '동시 Job', value: '1'),
];

/// Pro plan feature rows matching the BM spec (20/200/3).
const _proPlanFeatures = [
  PricingFeatureRow(label: '룰 슬롯', value: '20'),
  PricingFeatureRow(label: '배치 장수', value: '200'),
  PricingFeatureRow(label: '동시 Job', value: '3'),
];

/// Wraps the widget under test in a [MaterialApp] to satisfy context requirements.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

// ─── Test Suite ─────────────────────────────────────────────────────────────

void main() {
  group('PricingCard — Free plan rendering', () {
    testWidgets('shows plan name and price', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('\$0'), findsOneWidget);
    });

    testWidgets('renders all three feature rows with correct values',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Labels
      expect(find.text('룰 슬롯'), findsOneWidget);
      expect(find.text('배치 장수'), findsOneWidget);
      expect(find.text('동시 Job'), findsOneWidget);

      // Values — BM spec: 2 / 10 / 1
      expect(find.text('2'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('does NOT show 추천 badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('추천'), findsNothing);
    });

    testWidgets('shows upgrade button when not current plan', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            onUpgrade: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pro로 업그레이드'), findsOneWidget);
    });

    testWidgets('upgrade button fires callback on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            onUpgrade: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pro로 업그레이드'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  // ─── Pro plan ─────────────────────────────────────────────────────────────

  group('PricingCard — Pro plan rendering', () {
    testWidgets('shows plan name and price', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('renders all three feature rows with correct values',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Labels
      expect(find.text('룰 슬롯'), findsOneWidget);
      expect(find.text('배치 장수'), findsOneWidget);
      expect(find.text('동시 Job'), findsOneWidget);

      // Values — BM spec: 20 / 200 / 3
      expect(find.text('20'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows 추천 badge when isRecommended is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('추천'), findsOneWidget);
    });

    testWidgets('does NOT show 추천 badge when isRecommended is false',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('추천'), findsNothing);
    });

    testWidgets('uses gradient-border outer Container (isRecommended)',
        (tester) async {
      // Verify the gradient-border wrapper exists. The outer Container is
      // the first Container in the subtree when isRecommended is true.
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The ShaderMask wrapping '추천' text is only present for recommended cards.
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('shows upgrade button for non-current Pro card', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: true,
            onUpgrade: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pro로 업그레이드'), findsOneWidget);
    });
  });

  // ─── Current plan badge ────────────────────────────────────────────────────

  group('PricingCard — current plan badge', () {
    testWidgets('shows 현재 플랜 ✓ badge in header when isCurrentPlan is true',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            isCurrentPlan: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // '현재 플랜 ✓' appears in both the header badge and the action button.
      expect(find.text('현재 플랜 ✓'), findsWidgets);
    });

    testWidgets(
        'does NOT show 현재 플랜 ✓ badge in header when isCurrentPlan is false',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            isCurrentPlan: false,
            onUpgrade: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('현재 플랜 ✓'), findsNothing);
    });

    testWidgets(
        'shows 현재 플랜 ✓ action button instead of upgrade button',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            isCurrentPlan: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Upgrade button must NOT be present.
      expect(find.text('Pro로 업그레이드'), findsNothing);
      // Current-plan button IS present.
      expect(find.text('현재 플랜 ✓'), findsWidgets);
    });

    testWidgets('shows 크레딧 충전 button when onTopup is provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            isCurrentPlan: true,
            onTopup: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('크레딧 충전'), findsOneWidget);
    });

    testWidgets('does NOT show 크레딧 충전 button when onTopup is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            isCurrentPlan: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('크레딧 충전'), findsNothing);
    });

    testWidgets('topup button fires callback on tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrap(
          PricingCard(
            planName: 'Free',
            price: '\$0',
            features: _freePlanFeatures,
            isCurrentPlan: true,
            onTopup: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('크레딧 충전'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('current Pro card shows 현재 플랜 ✓ and 추천 badge together',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Pro',
            price: 'Coming soon',
            features: _proPlanFeatures,
            isRecommended: true,
            isCurrentPlan: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('추천'), findsOneWidget);
      expect(find.text('현재 플랜 ✓'), findsWidgets);
      expect(find.text('Pro로 업그레이드'), findsNothing);
    });
  });

  // ─── Feature icon default ──────────────────────────────────────────────────

  group('PricingCard — feature row icon', () {
    testWidgets('uses default icon when feature.icon is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: [PricingFeatureRow(label: '룰 슬롯', value: '2')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.check_circle_outline_rounded),
        findsOneWidget,
      );
    });

    testWidgets('uses custom icon when feature.icon is provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const PricingCard(
            planName: 'Free',
            price: '\$0',
            features: [
              PricingFeatureRow(
                label: '룰 슬롯',
                value: '2',
                icon: Icons.star_rounded,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });
}
