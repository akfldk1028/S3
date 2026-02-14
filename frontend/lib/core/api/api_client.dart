import '../models/user.dart';
import '../models/preset.dart';
import '../models/rule.dart';
import '../models/job.dart';

/// Abstract API client interface defining all frontend endpoints.
///
/// Based on workflow.md §6 API endpoints 1-14 (excluding #13 callback).
/// All methods return Futures for async HTTP operations.
///
/// Implementations should handle:
/// - JWT authentication via Authorization header
/// - Request/response envelope format
/// - Error handling and mapping
abstract class ApiClient {
  /// 1. POST /auth/anon - Create anonymous user and get JWT
  ///
  /// Returns: {user_id, token}
  Future<Map<String, dynamic>> createAnonUser();

  /// 2. GET /me - Get current user state
  ///
  /// Returns: User with credits, plan, active_jobs, rule_slots
  Future<User> getMe();

  /// 3. GET /presets - Get domain preset list
  ///
  /// Returns: List of presets (id, name, concept_count)
  Future<List<Preset>> getPresets();

  /// 4. GET /presets/{id} - Get preset detail
  ///
  /// Returns: Preset with concepts, protect_defaults, output_templates
  Future<Preset> getPresetById(String id);

  /// 5. POST /rules - Save a new rule
  ///
  /// Request: {name, preset_id, concepts, protect}
  /// Returns: {id: rule_id}
  Future<String> createRule({
    required String name,
    required String presetId,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  });

  /// 6. GET /rules - Get my rules list
  ///
  /// Returns: List of rules (id, name, preset_id, created_at)
  Future<List<Rule>> getRules();

  /// 7. PUT /rules/{id} - Update existing rule
  ///
  /// Request: {name, concepts, protect}
  Future<void> updateRule(
    String id, {
    required String name,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  });

  /// 8. DELETE /rules/{id} - Delete rule
  Future<void> deleteRule(String id);

  /// 9. POST /jobs - Create job and get presigned upload URLs
  ///
  /// Request: {preset, item_count}
  /// Returns: {job_id, upload: [{idx, url, key}, ...], confirm_url}
  Future<Map<String, dynamic>> createJob({
    required String preset,
    required int itemCount,
  });

  /// 10. POST /jobs/{jobId}/confirm-upload - Confirm upload completion
  ///
  /// Transitions job status: created → uploaded
  Future<void> confirmUpload(String jobId);

  /// 11. POST /jobs/{jobId}/execute - Execute rule application (Queue push)
  ///
  /// Request: {concepts, protect, rule_id?, output_template?}
  /// If rule_id is provided, uses saved rule's concepts/protect
  Future<void> executeJob(
    String jobId, {
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
    String? outputTemplate,
  });

  /// 12. GET /jobs/{jobId} - Get job status and progress
  ///
  /// Returns: Job with status, preset, progress, outputs_ready
  Future<Job> getJob(String jobId);

  /// 14. POST /jobs/{jobId}/cancel - Cancel job
  ///
  /// Triggers credit refund and status → canceled
  Future<void> cancelJob(String jobId);
}
