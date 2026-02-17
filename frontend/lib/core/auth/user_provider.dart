import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/api_endpoints.dart';
import '../models/user.dart';

/// Fetches and caches the authenticated user from GET /me.
///
/// Usage:
/// ```dart
/// final userAsync = ref.watch(userProvider);
/// userAsync.when(
///   loading: () => ...,
///   error: (e, st) => ...,
///   data: (user) => ...,
/// );
/// ```
///
/// To refresh: `ref.invalidate(userProvider)`
final userProvider = AsyncNotifierProvider<UserNotifier, User>(
  UserNotifier.new,
);

class UserNotifier extends AsyncNotifier<User> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<User> build() async {
    final token = await _storage.read(key: 'accessToken');
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: token != null
            ? {'Authorization': 'Bearer $token'}
            : null,
      ),
    );
    final response = await dio.get(ApiEndpoints.me);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  /// Force-refresh the user data from the server.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
