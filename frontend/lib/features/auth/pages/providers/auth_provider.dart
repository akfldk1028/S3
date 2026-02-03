import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/user_model.dart';
import '../../queries/get_me_query.dart';

part 'auth_provider.g.dart';

/// 인증 상태를 관리하는 Provider
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authProvider);
/// authState.when(
///   data: (user) => user != null ? HomeScreen() : LoginScreen(),
///   loading: () => SplashScreen(),
///   error: (e, _) => ErrorScreen(e),
/// );
/// ```
@riverpod
class Auth extends _$Auth {
  @override
  FutureOr<User?> build() async {
    // Check if user is already logged in
    // TODO: Check secure storage for token
    // final token = await ref.read(secureStorageProvider).read(key: 'access_token');
    // if (token == null) return null;

    // Try to get current user
    try {
      final user = await ref.read(getMeQueryProvider.future);
      return user;
    } catch (e) {
      // Token invalid or expired
      return null;
    }
  }

  Future<void> setUser(User user) async {
    state = AsyncData(user);
  }

  Future<void> logout() async {
    // TODO: Clear tokens
    // await ref.read(secureStorageProvider).delete(key: 'access_token');
    // await ref.read(secureStorageProvider).delete(key: 'refresh_token');

    state = const AsyncData(null);
  }
}

/// 로그인 여부 확인용 간단한 Provider
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  final authState = ref.watch(authProvider);
  return authState.valueOrNull != null;
}
