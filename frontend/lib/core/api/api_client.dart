import 'package:s3_frontend/core/models/job.dart';

/// Represents an action to apply to a concept segment during job execution.
///
/// Serialized to JSON as `{ "action": "recolor", "value": "oak_a" }`.
/// The [value] field is optional — e.g. `remove` actions carry no value.
class ConceptAction {
  final String action;
  final String? value;

  const ConceptAction({required this.action, this.value});

  Map<String, dynamic> toJson() => {
        'action': action,
        if (value != null) 'value': value,
      };

  factory ConceptAction.fromJson(Map<String, dynamic> json) => ConceptAction(
        action: json['action'] as String,
        value: json['value'] as String?,
      );

  @override
  String toString() => 'ConceptAction(action: $action, value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConceptAction &&
          runtimeType == other.runtimeType &&
          action == other.action &&
          value == other.value;

  @override
  int get hashCode => Object.hash(action, value);
}

/// Abstract API client interface for the S3 Workers REST API.
///
/// Implementations:
/// - `S3ApiClient` — real Dio-based HTTP client with JWT interceptor
/// - `MockApiClient` — in-memory stub for unit testing
abstract class ApiClient {
  /// Creates a new processing job and returns the job ID and presigned upload URLs.
  ///
  /// POST /jobs
  Future<({String jobId, List<String> uploadUrls})> createJob({
    required int imageCount,
    required String presetId,
  });

  /// Uploads a single image byte buffer to the given presigned S3 URL.
  ///
  /// Used during the upload phase before [confirmUpload].
  Future<void> uploadFile(String url, List<int> bytes);

  /// Confirms that all images have been successfully uploaded to presigned URLs.
  ///
  /// POST /jobs/{id}/confirm-upload
  Future<void> confirmUpload(String jobId);

  /// Executes a job by applying the given concept actions.
  ///
  /// POST /jobs/{id}/execute
  ///
  /// Parameters:
  /// - [concepts] — map from concept name to its action
  ///   e.g. `{ "Floor": ConceptAction(action: "recolor", value: "oak_a") }`
  /// - [protect] — optional list of concept names to protect from modification
  /// - [ruleId] — optional saved rule ID to apply
  /// - [outputTemplate] — optional output naming template
  /// - [prompts] — optional list of free-text SAM3 prompts; omitted from the
  ///   request body when null or empty
  Future<void> executeJob(
    String jobId, {
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
    String? outputTemplate,
    List<String>? prompts,
  });

  /// Polls the current status and progress of a job.
  ///
  /// GET /jobs/{id}
  Future<Job> pollJob(String jobId);

  /// Cancels a running job and refunds credits.
  ///
  /// POST /jobs/{id}/cancel
  Future<void> cancelJob(String jobId);
}
