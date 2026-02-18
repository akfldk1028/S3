import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/domain_select/domain_select_screen.dart';
import '../../features/palette/palette_screen.dart';
import '../../features/upload/upload_screen.dart';
import '../../features/rules/rules_screen.dart';
import '../../features/jobs/job_progress_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/workspace/workspace_state.dart';

/// GoRouter provider with auth guard via redirect callback.
///
/// Routes:
/// - / : Redirects to /domain-select
/// - /auth : Auto anonymous login screen
/// - /domain-select : Domain/preset selection screen
/// - /palette : Concept selection and instance configuration
/// - /upload : Image picker and R2 upload
/// - /rules : Rule editor (CRUD)
/// - /jobs/:id : Job progress with 3-second polling
/// - /results/:id : Before/after gallery
///
/// Auth Guard Logic:
/// - Unauthenticated users → redirected to /auth
/// - Authenticated users on /auth → redirected to /domain-select
/// - redirectLimit: 5 to prevent infinite loops
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   routerConfig: ref.watch(routerProvider),
/// )
/// ```
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Auth state (null = unauthenticated, String = JWT token)
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      // Redirect unauthenticated users to /auth
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth';
      }

      // Redirect authenticated users away from /auth to /domain-select
      if (isAuthenticated && isAuthRoute) {
        return '/domain-select';
      }

      // Allow navigation
      return null;
    },
    redirectLimit: 5,
    routes: [
      // Root route - redirect to domain-select
      GoRoute(
        path: '/',
        redirect: (context, state) => '/domain-select',
      ),

      // Auth screen - auto anonymous login
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Domain selection - choose preset (interior/seller)
      GoRoute(
        path: '/domain-select',
        builder: (context, state) => const DomainSelectScreen(),
      ),

      // Palette - concept chips, instance selection, protect toggles
      GoRoute(
        path: '/palette',
        builder: (context, state) {
          final presetId = state.uri.queryParameters['presetId'];
          return PaletteScreen(presetId: presetId);
        },
      ),

      // Upload - image picker, presigned R2 upload
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

      // Rules - rule editor (CRUD)
      GoRoute(
        path: '/rules',
        builder: (context, state) {
          final jobId = state.uri.queryParameters['jobId'];
          return RulesScreen(jobId: jobId);
        },
      ),

      // Jobs - progress screen with 3-second polling
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return JobProgressScreen(jobId: jobId);
        },
      ),

      // Results - before/after gallery (deep-link only)
      // Note: Results are primarily shown as overlay in workspace.
      // This route is kept for backward compatibility.
      GoRoute(
        path: '/results/:id',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return ResultsScreen(
            jobId: jobId,
            job: const JobResult(id: '', items: []),
          );
        },
      ),
    ],
  );
});
