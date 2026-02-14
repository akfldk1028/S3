// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Job _$JobFromJson(Map<String, dynamic> json) => _Job(
  jobId: json['job_id'] as String,
  status: json['status'] as String,
  preset: json['preset'] as String,
  progress: JobProgress.fromJson(json['progress'] as Map<String, dynamic>),
  outputsReady: (json['outputs_ready'] as List<dynamic>)
      .map((e) => JobItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$JobToJson(_Job instance) => <String, dynamic>{
  'job_id': instance.jobId,
  'status': instance.status,
  'preset': instance.preset,
  'progress': instance.progress,
  'outputs_ready': instance.outputsReady,
};
