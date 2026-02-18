// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rule _$RuleFromJson(Map<String, dynamic> json) => _Rule(
  id: json['id'] as String,
  name: json['name'] as String,
  presetId: json['preset_id'] as String,
  createdAt: json['created_at'] as String,
  concepts: (json['concepts'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, ConceptAction.fromJson(e as Map<String, dynamic>)),
  ),
  protect: (json['protect'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$RuleToJson(_Rule instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'preset_id': instance.presetId,
  'created_at': instance.createdAt,
  'concepts': ?instance.concepts?.map((k, e) => MapEntry(k, e.toJson())),
  'protect': ?instance.protect,
};

_ConceptAction _$ConceptActionFromJson(Map<String, dynamic> json) =>
    _ConceptAction(
      action: json['action'] as String,
      value: json['value'] as String?,
    );

Map<String, dynamic> _$ConceptActionToJson(_ConceptAction instance) =>
    <String, dynamic>{'action': instance.action, 'value': ?instance.value};
