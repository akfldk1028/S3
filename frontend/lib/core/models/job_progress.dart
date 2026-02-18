/// Progress counters for a running job.
class JobProgress {
  final int done;
  final int failed;
  final int total;

  const JobProgress({
    required this.done,
    required this.failed,
    required this.total,
  });
}
