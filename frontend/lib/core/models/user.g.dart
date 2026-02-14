// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  userId: json['user_id'] as String,
  plan: json['plan'] as String,
  credits: (json['credits'] as num).toInt(),
  activeJobs: (json['active_jobs'] as num).toInt(),
  ruleSlots: RuleSlots.fromJson(json['rule_slots'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'user_id': instance.userId,
  'plan': instance.plan,
  'credits': instance.credits,
  'active_jobs': instance.activeJobs,
  'rule_slots': instance.ruleSlots,
};

_RuleSlots _$RuleSlotsFromJson(Map<String, dynamic> json) => _RuleSlots(
  used: (json['used'] as num).toInt(),
  max: (json['max'] as num).toInt(),
);

Map<String, dynamic> _$RuleSlotsToJson(_RuleSlots instance) =>
    <String, dynamic>{'used': instance.used, 'max': instance.max};
