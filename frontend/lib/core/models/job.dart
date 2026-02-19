/// Job-related models matching Workers API responses.
///
/// Workers returns 3 different job shapes:
/// - POST /jobs       → [CreateJobResponse] (job_id + presigned_urls)
/// - GET  /jobs/:id   → [Job] (full status, wrapped in `data.job`)
/// - GET  /jobs       → List<[JobListItem]> (summary with progress)

// ─── POST /jobs response ─────────────────────────────────────────────────────

class CreateJobResponse {
  final String jobId;
  final List<PresignedUrl> presignedUrls;

  const CreateJobResponse({
    required this.jobId,
    required this.presignedUrls,
  });

  factory CreateJobResponse.fromJson(Map<String, dynamic> json) {
    return CreateJobResponse(
      jobId: json['job_id'] as String,
      presignedUrls: (json['presigned_urls'] as List<dynamic>)
          .map((e) => PresignedUrl.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PresignedUrl {
  final int idx;
  final String url;
  final String key;

  const PresignedUrl({
    required this.idx,
    required this.url,
    required this.key,
  });

  factory PresignedUrl.fromJson(Map<String, dynamic> json) {
    return PresignedUrl(
      idx: (json['idx'] as num).toInt(),
      url: json['url'] as String,
      key: json['key'] as String,
    );
  }
}

// ─── GET /jobs/:id response (wrapped in data.job) ────────────────────────────

class Job {
  final String jobId;

  /// created | uploaded | queued | running | done | failed | canceled
  final String status;

  final String preset;
  final int totalItems;
  final int doneItems;
  final int failedItems;
  final List<JobItemStatus> items;
  final List<DownloadUrl> downloadUrls;

  const Job({
    required this.jobId,
    required this.status,
    required this.preset,
    required this.totalItems,
    required this.doneItems,
    required this.failedItems,
    this.items = const [],
    this.downloadUrls = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      preset: json['preset'] as String,
      totalItems: (json['total_items'] as num).toInt(),
      doneItems: (json['done_items'] as num).toInt(),
      failedItems: (json['failed_items'] as num).toInt(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => JobItemStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      downloadUrls: (json['download_urls'] as List<dynamic>?)
              ?.map((e) => DownloadUrl.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(jobId, status);

  @override
  String toString() =>
      'Job(jobId: $jobId, status: $status, done: $doneItems/$totalItems)';
}

class JobItemStatus {
  final int idx;
  final String status;
  final String? error;

  const JobItemStatus({
    required this.idx,
    required this.status,
    this.error,
  });

  factory JobItemStatus.fromJson(Map<String, dynamic> json) {
    return JobItemStatus(
      idx: (json['idx'] as num).toInt(),
      status: json['status'] as String,
      error: json['error'] as String?,
    );
  }
}

class DownloadUrl {
  final int idx;
  final String? outputUrl;
  final String? previewUrl;

  const DownloadUrl({
    required this.idx,
    this.outputUrl,
    this.previewUrl,
  });

  factory DownloadUrl.fromJson(Map<String, dynamic> json) {
    return DownloadUrl(
      idx: (json['idx'] as num).toInt(),
      outputUrl: json['output_url'] as String?,
      previewUrl: json['preview_url'] as String?,
    );
  }
}

// ─── GET /jobs list response ─────────────────────────────────────────────────

class JobListItem {
  final String jobId;
  final String status;
  final String preset;
  final String? createdAt;
  final JobProgress progress;

  const JobListItem({
    required this.jobId,
    required this.status,
    required this.preset,
    this.createdAt,
    required this.progress,
  });

  factory JobListItem.fromJson(Map<String, dynamic> json) {
    return JobListItem(
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      preset: json['preset'] as String,
      createdAt: json['created_at'] as String?,
      progress: JobProgress.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }
}

class JobProgress {
  final int done;
  final int failed;
  final int total;

  const JobProgress({
    required this.done,
    required this.failed,
    required this.total,
  });

  factory JobProgress.fromJson(Map<String, dynamic> json) {
    return JobProgress(
      done: (json['done'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
