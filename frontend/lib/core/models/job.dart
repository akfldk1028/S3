import 'package:freezed_annotation/freezed_annotation.dart';
import 'job_progress.dart';
import 'job_item.dart';

part 'job.freezed.dart';  // Freezed code generation
part 'job.g.dart';         // JSON serialization

@freezed
class Job with _$Job {
  const factory Job({
    @JsonKey(name: 'job_id') required String jobId,
    required String status,  // 'created' | 'uploaded' | 'queued' | 'running' | 'done' | 'failed' | 'canceled'
    required String preset,
    required JobProgress progress,
    @JsonKey(name: 'outputs_ready') required List<JobItem> outputsReady,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
