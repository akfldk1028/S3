// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'palette_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaletteState _$PaletteStateFromJson(Map<String, dynamic> json) =>
    _PaletteState(
      selectedConcepts:
          (json['selectedConcepts'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      protectConcepts:
          (json['protectConcepts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
    );

Map<String, dynamic> _$PaletteStateToJson(_PaletteState instance) =>
    <String, dynamic>{
      'selectedConcepts': instance.selectedConcepts,
      'protectConcepts': instance.protectConcepts.toList(),
    };
