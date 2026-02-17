import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/pages/providers/auth_provider.dart';

// Gradient colors matching WsColors spec:
// accent1 = 0xFF667EEA (indigo-blue)
// accent2 = 0xFFFF6B9D (pink)
const _gradientAccent1 = Color(0xFF667EEA);
const _gradientAccent2 = Color(0xFFFF6B9D);

// Background color matching WsColors.bg
const _bgDark = Color(0xFF0F0F17);

/// Gradient definition matching WsColors.gradientPrimary
const _gradientPrimary = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_gradientAccent1, _gradientAccent2],
);

/// Animated splash screen shown on app launch.
///
/// Displays a full-screen gradient background with the S3 logo/text
/// that fades in and scales up over 800 ms. After a total of 2 seconds,
/// navigates to the workspace ('/') if an auth token is present, or to
/// the login screen ('/login') otherwise.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  Timer? _navTimer;
  bool _navPending = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start logo animation immediately.
    _controller.forward();

    // Schedule navigation after the full 2-second splash window.
    _navTimer = Timer(const Duration(seconds: 2), _attemptNavigation);
  }

  /// Navigates to '/' or '/login' based on current auth state.
  ///
  /// If the auth provider is still loading when this is called (e.g. reading
  /// from secure storage), the method sets [_navPending] and the [build]
  /// listener will call [_attemptNavigation] again once the value arrives.
  void _attemptNavigation() {
    if (!mounted) return;

    final authAsync = ref.read(authStateProvider);
    authAsync.when(
      data: (isAuthenticated) {
        _navPending = false;
        if (mounted) {
          context.go(isAuthenticated ? '/' : '/login');
        }
      },
      loading: () {
        // Auth state is not ready yet — wait for it via the build listener.
        _navPending = true;
      },
      error: (error, _) {
        _navPending = false;
        if (mounted) context.go('/login');
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state so that when it transitions from loading → data/error
    // while _navPending is true, we trigger navigation immediately.
    ref.listen<AsyncValue<bool>>(authStateProvider, (_, next) {
      if (_navPending) {
        next.whenData((_) => _attemptNavigation());
        if (next is AsyncError) _attemptNavigation();
      }
    });

    return Scaffold(
      backgroundColor: _bgDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: _gradientPrimary),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const _SplashLogo(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The S3 logo displayed during the splash screen.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container with frosted-glass style background.
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _gradientAccent1.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'S3',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2.5,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // App subtitle
        Text(
          'DOMAIN PALETTE ENGINE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}
