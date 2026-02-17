import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/user_model.dart';
import '../../features/auth/queries/get_me_query.dart';

/// Provides the current authenticated user including their credits balance.
///
/// Usage:
/// ```dart
/// final credits = ref.read(userProvider).value?.credits ?? 0;
/// ```
///
/// Returns `AsyncValue<User>` — use `.value` to access the User
/// synchronously without triggering an async load.
class _UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() {
    return ref.watch(getMeQueryProvider.future);
  }
}

final userProvider = AsyncNotifierProvider<_UserNotifier, User>(
  _UserNotifier.new,
);
