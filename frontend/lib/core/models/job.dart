/// Represents a processing job returned by the Workers API.
class Job {
  final String id;

  /// Job status values: 'pending', 'processing', 'completed', 'failed', 'cancelled'
  final String status;

  final String? errorMessage;
  final int? progress;

  const Job({
    required this.id,
    required this.status,
    this.errorMessage,
    this.progress,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      status: json['status'] as String,
      errorMessage: json['errorMessage'] as String?,
      progress: (json['progress'] as num?)?.toInt(),
    );
  }

  Job copyWith({
    String? id,
    String? status,
    String? errorMessage,
    int? progress,
  }) {
    return Job(
      id: id ?? this.id,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Job &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(id, status, errorMessage, progress);

  @override
  String toString() =>
      'Job(id: $id, status: $status, errorMessage: $errorMessage, progress: $progress)';
}
