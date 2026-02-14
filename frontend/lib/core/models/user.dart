import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';  // Freezed code generation
part 'user.g.dart';         // JSON serialization

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: 'user_id') required String userId,
    required String plan,  // 'free' | 'pro'
    required int credits,
    @JsonKey(name: 'active_jobs') required int activeJobs,
    @JsonKey(name: 'rule_slots') required RuleSlots ruleSlots,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class RuleSlots with _$RuleSlots {
  const factory RuleSlots({
    required int used,
    required int max,
  }) = _RuleSlots;

  factory RuleSlots.fromJson(Map<String, dynamic> json) => _$RuleSlotsFromJson(json);
}
