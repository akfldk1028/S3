import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart' as models;
import '../api/api_client_provider.dart';

part 'user_provider.g.dart';

/// Riverpod provider for user data from GET /me API endpoint.
///
/// Provides user information including plan, credits, and rule slots.
///
/// State: AsyncValue of User containing current user data.
///
/// Usage:
/// ```dart
/// // Watch user state
/// final userAsync = ref.watch(userProvider);
/// userAsync.when(
///   data: (user) => Text('Plan: ${user.plan}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
///
/// // Refresh user data
/// await ref.read(userProvider.notifier).refresh();
/// ```
@riverpod
class User extends _$User {
  @override
  FutureOr<models.User> build() async {
    // Initialize: fetch user data from API
    final apiClient = ref.watch(apiClientProvider);
    return await apiClient.getMe();
  }

  /// Refreshes user data from GET /me API endpoint.
  ///
  /// This method can be called manually to refresh user information
  /// after operations that might change user state (e.g., creating rules).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      return await apiClient.getMe();
    });
  }
}
