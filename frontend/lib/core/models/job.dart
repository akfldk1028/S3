import 'package:freezed_annotation/freezed_annotation.dart';
import 'job_progress.dart';
import 'job_item.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
abstract class Job with _$Job {
  const factory Job({
    @JsonKey(name: 'job_id') required String jobId,
    required String status,
    required String preset,
    required JobProgress progress,
    @JsonKey(name: 'outputs_ready') required List<JobItem> outputsReady,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
