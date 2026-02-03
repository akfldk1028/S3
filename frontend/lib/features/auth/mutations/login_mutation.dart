import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user_model.dart';
// import '../../../constants/api_endpoints.dart';

part 'login_mutation.g.dart';

/// 로그인 Mutation
///
/// Usage:
/// ```dart
/// final loginMutation = ref.read(loginMutationProvider.notifier);
/// try {
///   final response = await loginMutation.call(
///     email: 'test@example.com',
///     password: 'password123',
///   );
///   // Handle success
/// } catch (e) {
///   // Handle error
/// }
/// ```
@riverpod
class LoginMutation extends _$LoginMutation {
  @override
  FutureOr<LoginResponse?> build() => null;

  Future<LoginResponse> call({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      // TODO: Implement actual API call
      // final dio = ref.read(dioProvider);
      // final response = await dio.post(
      //   ApiEndpoints.login,
      //   data: {'email': email, 'password': password},
      // );
      // final loginResponse = LoginResponse.fromJson(response.data);

      // Mock response for now
      await Future.delayed(const Duration(seconds: 1));
      final loginResponse = LoginResponse(
        user: User(
          id: '1',
          email: email,
          name: 'Test User',
          isVerified: true,
        ),
        token: const AuthToken(
          accessToken: 'mock_access_token',
          refreshToken: 'mock_refresh_token',
          expiresIn: 3600,
        ),
      );

      state = AsyncData(loginResponse);

      // TODO: Save token to secure storage
      // await ref.read(secureStorageProvider).write(
      //   key: 'access_token',
      //   value: loginResponse.token.accessToken,
      // );

      return loginResponse;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
