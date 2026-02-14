// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for fetching available presets (domains).
///
/// Fetches the list of presets from GET /presets API endpoint.
/// Used in domain selection screen to display available domains
/// (e.g., "건축/인테리어", "쇼핑/셀러").
///
/// Returns: Future with List of Preset objects containing id, name, conceptCount fields.
///
/// Usage:
/// ```dart
/// final presetsAsync = ref.watch(presetsProvider);
/// presetsAsync.when(
///   data: (presets) => ListView(children: presets.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```

@ProviderFor(presets)
final presetsProvider = PresetsProvider._();

/// Riverpod provider for fetching available presets (domains).
///
/// Fetches the list of presets from GET /presets API endpoint.
/// Used in domain selection screen to display available domains
/// (e.g., "건축/인테리어", "쇼핑/셀러").
///
/// Returns: Future with List of Preset objects containing id, name, conceptCount fields.
///
/// Usage:
/// ```dart
/// final presetsAsync = ref.watch(presetsProvider);
/// presetsAsync.when(
///   data: (presets) => ListView(children: presets.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```

final class PresetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Preset>>,
          List<Preset>,
          FutureOr<List<Preset>>
        >
    with $FutureModifier<List<Preset>>, $FutureProvider<List<Preset>> {
  /// Riverpod provider for fetching available presets (domains).
  ///
  /// Fetches the list of presets from GET /presets API endpoint.
  /// Used in domain selection screen to display available domains
  /// (e.g., "건축/인테리어", "쇼핑/셀러").
  ///
  /// Returns: Future with List of Preset objects containing id, name, conceptCount fields.
  ///
  /// Usage:
  /// ```dart
  /// final presetsAsync = ref.watch(presetsProvider);
  /// presetsAsync.when(
  ///   data: (presets) => ListView(children: presets.map(...)),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (err, stack) => Text('Error: $err'),
  /// );
  /// ```
  PresetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presetsHash();

  @$internal
  @override
  $FutureProviderElement<List<Preset>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Preset>> create(Ref ref) {
    return presets(ref);
  }
}

String _$presetsHash() => r'eddbce255e57940764af9dc0c717ce9863b72e3b';
