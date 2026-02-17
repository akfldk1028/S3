// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobProgress _$JobProgressFromJson(Map<String, dynamic> json) => _JobProgress(
  done: (json['done'] as num).toInt(),
  failed: (json['failed'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$JobProgressToJson(_JobProgress instance) =>
    <String, dynamic>{
      'done': instance.done,
      'failed': instance.failed,
      'total': instance.total,
    };
