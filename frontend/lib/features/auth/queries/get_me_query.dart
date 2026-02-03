import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user_model.dart';
// import '../../../constants/api_endpoints.dart';

part 'get_me_query.g.dart';

/// 현재 로그인한 사용자 정보 조회
///
/// Usage:
/// ```dart
/// final userAsync = ref.watch(getMeQueryProvider);
/// userAsync.when(
///   data: (user) => Text(user.name),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
@riverpod
Future<User> getMeQuery(GetMeQueryRef ref) async {
  // TODO: Implement actual API call
  // final dio = ref.watch(dioProvider);
  // final response = await dio.get(ApiEndpoints.me);
  // return User.fromJson(response.data);

  // Mock data for now
  await Future.delayed(const Duration(seconds: 1));
  return const User(
    id: '1',
    email: 'test@example.com',
    name: 'Test User',
    isVerified: true,
  );
}
