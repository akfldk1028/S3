import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../workspace/theme.dart';

/// Animated splash screen shown on app launch.
///
/// Displays a full-screen gradient background ([WsColors.gradientPrimary])
/// with the S3 logo/text that fades in and scales up over 800 ms.
/// After a total of 2 seconds, navigates to / (camera home) if an
/// auth token is present, or to /auth otherwise.
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

  /// Navigates to '/' (camera home) or '/auth' based on current auth state.
  void _attemptNavigation() {
    if (!mounted) return;

    final authAsync = ref.read(authProvider);
    authAsync.when(
      data: (token) {
        _navPending = false;
        if (mounted) {
          context.go(token != null ? '/' : '/auth');
        }
      },
      loading: () {
        _navPending = true;
      },
      error: (error, _) {
        _navPending = false;
        if (mounted) context.go('/auth');
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
    ref.listen<AsyncValue<String?>>(authProvider, (_, next) {
      if (_navPending) {
        next.whenData((_) => _attemptNavigation());
        if (next is AsyncError) _attemptNavigation();
      }
    });

    return Scaffold(
      backgroundColor: WsColors.bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: WsColors.gradientPrimary),
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
                color: WsColors.accent1.withValues(alpha: 0.4),
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
