import 'package:freezed_annotation/freezed_annotation.dart';

part 'rule.freezed.dart';  // Freezed code generation
part 'rule.g.dart';         // JSON serialization

@freezed
class Rule with _$Rule {
  const factory Rule({
    required String id,
    required String name,
    @JsonKey(name: 'preset_id') required String presetId,
    @JsonKey(name: 'created_at') required String createdAt,
    // Detail/create view fields (optional for list view)
    Map<String, ConceptAction>? concepts,
    List<String>? protect,
  }) = _Rule;

  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
}

@freezed
class ConceptAction with _$ConceptAction {
  const factory ConceptAction({
    required String action,  // 'recolor' | 'tone' | 'texture' | 'remove'
    String? value,           // Optional value for action (e.g., 'oak_a', 'offwhite_b')
  }) = _ConceptAction;

  factory ConceptAction.fromJson(Map<String, dynamic> json) => _$ConceptActionFromJson(json);
}
