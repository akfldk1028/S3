import 'job_item.dart';
import 'job_progress.dart';

/// Represents an active or completed processing job.
class Job {
  final String jobId;
  final String status;
  final String preset;
  final JobProgress progress;

  /// Items that have finished processing so far (may be partial while running).
  final List<JobItem> outputsReady;

  const Job({
    required this.jobId,
    required this.status,
    required this.preset,
    required this.progress,
    required this.outputsReady,
  });
}
