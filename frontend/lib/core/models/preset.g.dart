// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Preset _$PresetFromJson(Map<String, dynamic> json) => _Preset(
  id: json['id'] as String,
  name: json['name'] as String,
  conceptCount: (json['concept_count'] as num).toInt(),
  concepts: (json['concepts'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  protectDefaults: (json['protect_defaults'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  outputTemplates: (json['output_templates'] as List<dynamic>?)
      ?.map((e) => OutputTemplate.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PresetToJson(_Preset instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'concept_count': instance.conceptCount,
  'concepts': instance.concepts,
  'protect_defaults': instance.protectDefaults,
  'output_templates': instance.outputTemplates,
};

_OutputTemplate _$OutputTemplateFromJson(Map<String, dynamic> json) =>
    _OutputTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$OutputTemplateToJson(_OutputTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };
