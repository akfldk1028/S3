import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'rule.freezed.dart';  // Freezed code generation
part 'rule.g.dart';         // JSON serialization

@freezed
abstract class Rule with _$Rule {
  const factory Rule({
    required String id,
    required String name,
    @JsonKey(name: 'preset_id') required String presetId,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
    Map<String, ConceptAction>? concepts,
    List<String>? protect,
  }) = _Rule;

  /// Custom fromJson — Workers returns concepts_json/protect_json as JSON strings.
  factory Rule.fromJson(Map<String, dynamic> json) {
    // Parse concepts: try concepts_json (string) first, then concepts (map)
    Map<String, ConceptAction>? concepts;
    final conceptsRaw = json['concepts_json'] ?? json['concepts'];
    if (conceptsRaw is String && conceptsRaw.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(conceptsRaw) as Map);
        concepts = decoded.map(
          (k, v) => MapEntry(k, ConceptAction.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {}
    } else if (conceptsRaw is Map<String, dynamic>) {
      concepts = conceptsRaw.map(
        (k, v) => MapEntry(k, ConceptAction.fromJson(v as Map<String, dynamic>)),
      );
    }

    // Parse protect: try protect_json (string) first, then protect (list)
    List<String>? protect;
    final protectRaw = json['protect_json'] ?? json['protect'];
    if (protectRaw is String && protectRaw.isNotEmpty) {
      try {
        protect = List<String>.from(jsonDecode(protectRaw) as List);
      } catch (_) {}
    } else if (protectRaw is List) {
      protect = List<String>.from(protectRaw);
    }

    return Rule(
      id: json['id'] as String,
      name: json['name'] as String,
      presetId: json['preset_id'] as String,
      createdAt: (json['created_at'] as String?) ?? '',
      concepts: concepts,
      protect: protect,
    );
  }
}

@freezed
abstract class ConceptAction with _$ConceptAction {
  const factory ConceptAction({
    required String action,  // 'recolor' | 'tone' | 'texture' | 'remove'
    String? value,           // Optional value for action (e.g., 'oak_a', 'offwhite_b')
  }) = _ConceptAction;

  factory ConceptAction.fromJson(Map<String, dynamic> json) => _$ConceptActionFromJson(json);
}
