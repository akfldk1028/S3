import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// User model matching Workers GET /me response.
///
/// Workers response (after envelope unwrap):
/// ```json
/// { "user_id": "abc", "plan": "free", "credits": 10, "rule_slots": 0, "concurrent_jobs": 0 }
/// ```
@freezed
abstract class User with _$User {
  const factory User({
    @JsonKey(name: 'user_id') required String id,
    @Default('free') String plan,
    @Default(0) int credits,
    @JsonKey(name: 'rule_slots') @Default(0) int ruleSlots,
    @JsonKey(name: 'concurrent_jobs') @Default(0) int concurrentJobs,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Login response matching Workers POST /auth/anon response.
///
/// Workers response (after envelope unwrap):
/// ```json
/// { "user_id": "abc", "token": "jwt...", "plan": "free", "is_new": true }
/// ```
@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    @JsonKey(name: 'user_id') required String userId,
    required String token,
    @Default('free') String plan,
    @JsonKey(name: 'is_new') @Default(false) bool isNew,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}
