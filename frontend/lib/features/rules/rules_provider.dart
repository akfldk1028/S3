import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/models/rule.dart';
import '../../core/api/api_client_provider.dart';

part 'rules_provider.g.dart';

/// Riverpod provider for rules CRUD operations.
///
/// Manages rule state and provides methods for:
/// - Fetching all rules (GET /rules)
/// - Creating new rules (POST /rules)
/// - Updating existing rules (PUT /rules/:id)
/// - Deleting rules (DELETE /rules/:id)
///
/// State: AsyncValue of List of Rule containing all user rules.
///
/// Usage:
/// ```dart
/// // Watch rules state
/// final rulesAsync = ref.watch(rulesProvider);
/// rulesAsync.when(
///   data: (rules) => ListView(children: rules.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
///
/// // Create new rule
/// await ref.read(rulesProvider.notifier).createRule({
///   'name': 'My Rule',
///   'preset_id': 'interior',
///   'concepts': {'sofa': {'action': 'recolor', 'value': 'oak_a'}},
///   'protect': ['wall'],
/// });
///
/// // Update existing rule
/// await ref.read(rulesProvider.notifier).updateRule('rule-id', {
///   'name': 'Updated Rule',
/// });
///
/// // Delete rule
/// await ref.read(rulesProvider.notifier).deleteRule('rule-id');
///
/// // Refresh rules list
/// await ref.read(rulesProvider.notifier).refreshRules();
/// ```
@riverpod
class Rules extends _$Rules {
  @override
  FutureOr<List<Rule>> build() async {
    // Initialize: fetch all rules from API
    final apiClient = ref.watch(apiClientProvider);
    return await apiClient.getRules();
  }

  /// Fetches all rules from GET /rules API endpoint.
  ///
  /// This method is called automatically on build(), but can be
  /// called manually to refresh the rules list.
  Future<void> refreshRules() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      return await apiClient.getRules();
    });
  }

  /// Creates a new rule via POST /rules API endpoint.
  ///
  /// Parameters:
  /// - [name]: Rule name
  /// - [presetId]: Preset ID this rule belongs to
  /// - [concepts]: Map from concept name to ConceptAction objects
  /// - [protect]: Optional list of protected concept names
  ///
  /// After successful creation, refreshes the rules list.
  ///
  /// Throws if API call fails or validation errors occur.
  Future<void> createRule({
    required String name,
    required String presetId,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      // Create rule via API
      await apiClient.createRule(
        name: name,
        presetId: presetId,
        concepts: concepts,
        protect: protect,
      );

      // Refresh rules list after successful creation
      await refreshRules();
    } catch (e) {
      // Re-throw error to be handled by UI
      rethrow;
    }
  }

  /// Updates an existing rule via PUT /rules/:id API endpoint.
  ///
  /// Parameters:
  /// - [id]: Rule ID to update
  /// - [name]: Updated rule name
  /// - [concepts]: Updated map from concept name to ConceptAction objects
  /// - [protect]: Optional updated list of protected concept names
  ///
  /// After successful update, refreshes the rules list.
  ///
  /// Throws if API call fails or rule not found.
  Future<void> updateRule(
    String id, {
    required String name,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      // Update rule via API
      await apiClient.updateRule(
        id,
        name: name,
        concepts: concepts,
        protect: protect,
      );

      // Refresh rules list after successful update
      await refreshRules();
    } catch (e) {
      // Re-throw error to be handled by UI
      rethrow;
    }
  }

  /// Deletes a rule via DELETE /rules/:id API endpoint.
  ///
  /// Parameters:
  /// - [id]: Rule ID to delete
  ///
  /// After successful deletion, refreshes the rules list.
  ///
  /// Throws if API call fails or rule not found.
  Future<void> deleteRule(String id) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      // Delete rule via API
      await apiClient.deleteRule(id);

      // Refresh rules list after successful deletion
      await refreshRules();
    } catch (e) {
      // Re-throw error to be handled by UI
      rethrow;
    }
  }
}
