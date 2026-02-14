import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_progress.freezed.dart';  // Freezed code generation
part 'job_progress.g.dart';         // JSON serialization

@freezed
class JobProgress with _$JobProgress {
  const factory JobProgress({
    required int done,
    required int failed,
    required int total,
  }) = _JobProgress;

  factory JobProgress.fromJson(Map<String, dynamic> json) => _$JobProgressFromJson(json);
}
