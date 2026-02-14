// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(Rules)
final rulesProvider = RulesProvider._();

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
final class RulesProvider extends $AsyncNotifierProvider<Rules, List<Rule>> {
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
  RulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rulesHash();

  @$internal
  @override
  Rules create() => Rules();
}

String _$rulesHash() => r'd928454cf7984ed4f2b493287b226db92a11b81e';

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

abstract class _$Rules extends $AsyncNotifier<List<Rule>> {
  FutureOr<List<Rule>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Rule>>, List<Rule>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Rule>>, List<Rule>>,
              AsyncValue<List<Rule>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
