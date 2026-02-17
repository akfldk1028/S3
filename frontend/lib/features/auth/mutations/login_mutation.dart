import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../queries/get_me_query.dart';

part 'login_mutation.g.dart';

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
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.authAnon,
        data: {
          'email': email,
          'password': password,
        },
      );
      final result = LoginResponse.fromJson(response.data);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
