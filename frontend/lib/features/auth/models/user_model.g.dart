// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['user_id'] as String,
  plan: json['plan'] as String? ?? 'free',
  credits: (json['credits'] as num?)?.toInt() ?? 0,
  ruleSlots: (json['rule_slots'] as num?)?.toInt() ?? 0,
  concurrentJobs: (json['concurrent_jobs'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'user_id': instance.id,
  'plan': instance.plan,
  'credits': instance.credits,
  'rule_slots': instance.ruleSlots,
  'concurrent_jobs': instance.concurrentJobs,
};

_LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    _LoginResponse(
      userId: json['user_id'] as String,
      token: json['token'] as String,
      plan: json['plan'] as String? ?? 'free',
      isNew: json['is_new'] as bool? ?? false,
    );

Map<String, dynamic> _$LoginResponseToJson(_LoginResponse instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'token': instance.token,
      'plan': instance.plan,
      'is_new': instance.isNew,
    };
