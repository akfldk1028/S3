// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String?,
  profileImage: json['profileImage'] as String?,
  credits: (json['credits'] as num?)?.toInt() ?? 0,
  plan: json['plan'] as String? ?? 'free',
  ruleSlotsUsed: (json['ruleSlotsUsed'] as num?)?.toInt() ?? 0,
  ruleSlotsMax: (json['ruleSlotsMax'] as num?)?.toInt() ?? 2,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'profileImage': instance.profileImage,
  'credits': instance.credits,
  'plan': instance.plan,
  'ruleSlotsUsed': instance.ruleSlotsUsed,
  'ruleSlotsMax': instance.ruleSlotsMax,
};

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    _LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(_LoginResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };
