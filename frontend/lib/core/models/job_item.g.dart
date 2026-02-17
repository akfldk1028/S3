// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobItem _$JobItemFromJson(Map<String, dynamic> json) => _JobItem(
  idx: (json['idx'] as num).toInt(),
  resultUrl: json['result_url'] as String,
  previewUrl: json['preview_url'] as String,
);

Map<String, dynamic> _$JobItemToJson(_JobItem instance) => <String, dynamic>{
  'idx': instance.idx,
  'result_url': instance.resultUrl,
  'preview_url': instance.previewUrl,
};
