// Integration widget tests for:
//   1. TopBar credits-pill navigation  → /pricing (GoRouter push)
//   2. PricingScreen × authStateProvider (loading / free-plan / logged-out / error)
//
// These tests do NOT use FlutterSecureStorage — authStateProvider is overridden
// with lightweight fakes that return fixed values without platform-channel access.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:s3_frontend/features/auth/pages/providers/auth_provider.dart';
import 'package:s3_frontend/features/pricing/pricing_screen.dart';
import 'package:s3_frontend/features/workspace/widgets/top_bar.dart';

// ─── Fake AuthState implementations ──────────────────────────────────────────

/// Resolves immediately to [isLoggedIn] — no platform-channel access.
class _FakeAuthState extends AuthState {
  _FakeAuthState(this._isLoggedIn);

  final bool _isLoggedIn;

  @override
  FutureOr<bool> build() => _isLoggedIn;
}

/// Stays loading indefinitely — used to test the loading-spinner branches.
///
/// Uses a [Completer] that is never completed instead of a timer-based delay,
/// so the test framework does not detect a pending timer after widget disposal.
class _LoadingAuthState extends AuthState {
  @override
  FutureOr<bool> build() {
    // A Completer that never completes keeps the provider in AsyncLoading state
    // without registering any timers.
    return Completer<bool>().future;
  }
}

/// Throws during build — used to test the error-state branch.
class _ErrorAuthState extends AuthState {
  @override
  FutureOr<bool> build() async => throw Exception('auth error');
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── Group 1: TopBar credits-pill navigation ──────────────────────────────

  group('TopBar — credits pill navigates to /pricing', () {
    /// Returns a [ProviderScope] that hosts a GoRouter-powered [MaterialApp.router]
    /// with [TopBar] at '/' and a stub '/pricing' destination page.
    ProviderScope buildTopBarApp({required bool isLoggedIn}) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              appBar: const TopBar(),
              body: const SizedBox.shrink(),
            ),
          ),
          GoRoute(
            path: '/pricing',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Pricing Destination')),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => _FakeAuthState(isLoggedIn)),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('credits pill is visible for a logged-in user', (tester) async {
      await tester.pumpWidget(buildTopBarApp(isLoggedIn: true));
      await tester.pumpAndSettle();

      // The credits pill shows "Free" as the plan label.
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('credits pill is NOT shown when user is not logged in',
        (tester) async {
      await tester.pumpWidget(buildTopBarApp(isLoggedIn: false));
      await tester.pumpAndSettle();

      expect(find.text('Free'), findsNothing);
    });

    testWidgets('tapping credits pill navigates to /pricing route',
        (tester) async {
      await tester.pumpWidget(buildTopBarApp(isLoggedIn: true));
      await tester.pumpAndSettle();

      // The pill text "Free" is inside the tappable GestureDetector.
      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();

      // Navigation should have completed — stub pricing page is visible.
      expect(find.text('Pricing Destination'), findsOneWidget);
    });

    testWidgets('TopBar shows CircularProgressIndicator while auth is loading',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              appBar: const TopBar(),
              body: const SizedBox.shrink(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _LoadingAuthState()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      // Single pump — do NOT call pumpAndSettle so loading state is still active.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Group 2: PricingScreen × authStateProvider integration ───────────────

  group('PricingScreen — reads authStateProvider', () {
    testWidgets('shows CircularProgressIndicator while auth is loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _LoadingAuthState()),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      // Single pump — loading state still active.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders both Free and Pro plan cards for logged-in user',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets(
        'Free card shows 현재 플랜 ✓ badge when user is on the free plan',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // '현재 플랜 ✓' appears in both the header badge and the action button.
      expect(find.text('현재 플랜 ✓'), findsWidgets);
    });

    testWidgets('Pro card shows 추천 badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('추천'), findsOneWidget);
    });

    testWidgets(
        'Pro card shows Pro로 업그레이드 button when user is on the free plan',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Current plan is 'free' → Pro card shows the upgrade CTA.
      expect(find.text('Pro로 업그레이드'), findsOneWidget);
    });

    testWidgets('Free card shows 크레딧 충전 button for current free-plan user',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('크레딧 충전'), findsOneWidget);
    });

    testWidgets(
        'no 현재 플랜 ✓ badge when user is not logged in (empty plan)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(false)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // currentPlan == '' → neither card is highlighted as current.
      expect(find.text('현재 플랜 ✓'), findsNothing);
      // Both plan name labels are still rendered.
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
    });

    testWidgets(
        'renders both cards without current-plan badge on authStateProvider error',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _ErrorAuthState()),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Error branch maps to currentPlan: '' — both cards render, none highlighted.
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('현재 플랜 ✓'), findsNothing);
    });

    testWidgets('PricingScreen displays 플랜 비교 header text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('플랜 비교'), findsOneWidget);
    });

    testWidgets('PricingScreen displays S3 플랜 AppBar title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _FakeAuthState(true)),
          ],
          child: const MaterialApp(home: PricingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('S3 플랜'), findsOneWidget);
    });
  });
}
