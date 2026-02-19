import 'package:freezed_annotation/freezed_annotation.dart';

part 'preset.freezed.dart';  // Freezed code generation
part 'preset.g.dart';         // JSON serialization

@freezed
abstract class Preset with _$Preset {
  const factory Preset({
    required String id,
    required String name,
    @JsonKey(name: 'concept_count') @Default(0) int conceptCount,
    // Detail view fields (optional for list view)
    List<String>? concepts,
    @JsonKey(name: 'protect_defaults') List<String>? protectDefaults,
    @JsonKey(name: 'output_templates') List<OutputTemplate>? outputTemplates,
  }) = _Preset;

  factory Preset.fromJson(Map<String, dynamic> json) => _$PresetFromJson(json);
}

@freezed
abstract class OutputTemplate with _$OutputTemplate {
  const factory OutputTemplate({
    required String id,
    required String name,
    required String description,
  }) = _OutputTemplate;

  factory OutputTemplate.fromJson(Map<String, dynamic> json) => _$OutputTemplateFromJson(json);
}
