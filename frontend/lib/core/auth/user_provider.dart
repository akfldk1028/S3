import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/user_model.dart';
import '../api/api_client_provider.dart';

/// Provides the current authenticated user from GET /me.
///
/// Usage:
/// ```dart
/// final credits = ref.read(userProvider).value?.credits ?? 0;
/// ```
class _UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() {
    final apiClient = ref.watch(apiClientProvider);
    return apiClient.getMe();
  }
}

final userProvider = AsyncNotifierProvider<_UserNotifier, User>(
  _UserNotifier.new,
);
