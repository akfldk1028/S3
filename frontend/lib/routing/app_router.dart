import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/auth/auth_provider.dart';
import '../features/auth/auth_screen.dart';
import '../features/camera/camera_home_screen.dart';
import '../features/domain_select/domain_select_screen.dart';
import '../features/jobs/job_progress_screen.dart';
import '../features/palette/palette_screen.dart';
import '../features/rules/rules_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/upload/upload_screen.dart';

part 'app_router.g.dart';

/// GoRouter with auth guard via redirect callback.
///
/// Routes:
/// - /splash : Animated splash (initial)
/// - /auth : Auto anonymous login
/// - / : Camera home (SNOW-style main screen)
/// - /domain-select : Domain/preset selection
/// - /palette : Concept chips, instance selection
/// - /upload : Image picker, R2 upload
/// - /rules : Rule editor (CRUD)
/// - /jobs/:id : Job progress with polling
///
/// Auth Guard:
/// - /splash is always allowed (no redirect)
/// - Unauthenticated → /auth
/// - Authenticated on /auth → / (camera home)
@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Always allow splash
      if (location == '/splash') return null;

      // During loading, don't redirect (let splash handle it).
      // .value is null during loading/error and also when data is null (no token).
      final token = authState.whenOrNull(data: (t) => t);
      final isAuthenticated = token != null;
      final isAuthRoute = location == '/auth';

      // Unauthenticated → /auth
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      // Authenticated on /auth → / (camera home)
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    redirectLimit: 5,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const CameraHomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/domain-select',
        builder: (context, state) => const DomainSelectScreen(),
      ),
      GoRoute(
        path: '/palette',
        builder: (context, state) {
          final presetId = state.uri.queryParameters['presetId'];
          return PaletteScreen(presetId: presetId);
        },
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) {
          final presetId = state.uri.queryParameters['presetId'];
          final conceptsJson = state.uri.queryParameters['concepts'];
          final protectJson = state.uri.queryParameters['protect'];
          return UploadScreen(
            presetId: presetId,
            conceptsJson: conceptsJson,
            protectJson: protectJson,
          );
        },
      ),
      GoRoute(
        path: '/rules',
        builder: (context, state) {
          final jobId = state.uri.queryParameters['jobId'];
          return RulesScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return JobProgressScreen(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
