// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'palette_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for palette (concept selection) state management.
///
/// Manages local UI state for concept selection screen:
/// - toggleConcept(name): Toggle concept on/off
/// - setInstance(name, index): Set instance number for a concept
/// - toggleProtect(name): Toggle protect flag for a concept
/// - reset(): Clear all selections
///
/// This is local-only state (not persisted to API) that gets passed
/// to the upload screen when user proceeds.
///
/// Usage:
/// ```dart
/// // Watch state
/// final paletteState = ref.watch(paletteProvider);
///
/// // Toggle concept
/// ref.read(paletteProvider.notifier).toggleConcept('sofa');
///
/// // Set instance
/// ref.read(paletteProvider.notifier).setInstance('sofa', 2);
///
/// // Toggle protect
/// ref.read(paletteProvider.notifier).toggleProtect('sofa');
/// ```

@ProviderFor(Palette)
final paletteProvider = PaletteProvider._();

/// Riverpod provider for palette (concept selection) state management.
///
/// Manages local UI state for concept selection screen:
/// - toggleConcept(name): Toggle concept on/off
/// - setInstance(name, index): Set instance number for a concept
/// - toggleProtect(name): Toggle protect flag for a concept
/// - reset(): Clear all selections
///
/// This is local-only state (not persisted to API) that gets passed
/// to the upload screen when user proceeds.
///
/// Usage:
/// ```dart
/// // Watch state
/// final paletteState = ref.watch(paletteProvider);
///
/// // Toggle concept
/// ref.read(paletteProvider.notifier).toggleConcept('sofa');
///
/// // Set instance
/// ref.read(paletteProvider.notifier).setInstance('sofa', 2);
///
/// // Toggle protect
/// ref.read(paletteProvider.notifier).toggleProtect('sofa');
/// ```
final class PaletteProvider extends $NotifierProvider<Palette, PaletteState> {
  /// Riverpod provider for palette (concept selection) state management.
  ///
  /// Manages local UI state for concept selection screen:
  /// - toggleConcept(name): Toggle concept on/off
  /// - setInstance(name, index): Set instance number for a concept
  /// - toggleProtect(name): Toggle protect flag for a concept
  /// - reset(): Clear all selections
  ///
  /// This is local-only state (not persisted to API) that gets passed
  /// to the upload screen when user proceeds.
  ///
  /// Usage:
  /// ```dart
  /// // Watch state
  /// final paletteState = ref.watch(paletteProvider);
  ///
  /// // Toggle concept
  /// ref.read(paletteProvider.notifier).toggleConcept('sofa');
  ///
  /// // Set instance
  /// ref.read(paletteProvider.notifier).setInstance('sofa', 2);
  ///
  /// // Toggle protect
  /// ref.read(paletteProvider.notifier).toggleProtect('sofa');
  /// ```
  PaletteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paletteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paletteHash();

  @$internal
  @override
  Palette create() => Palette();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaletteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaletteState>(value),
    );
  }
}

String _$paletteHash() => r'ccd18e43a0c2eb14d2d996c2a60caff080fe764c';

/// Riverpod provider for palette (concept selection) state management.
///
/// Manages local UI state for concept selection screen:
/// - toggleConcept(name): Toggle concept on/off
/// - setInstance(name, index): Set instance number for a concept
/// - toggleProtect(name): Toggle protect flag for a concept
/// - reset(): Clear all selections
///
/// This is local-only state (not persisted to API) that gets passed
/// to the upload screen when user proceeds.
///
/// Usage:
/// ```dart
/// // Watch state
/// final paletteState = ref.watch(paletteProvider);
///
/// // Toggle concept
/// ref.read(paletteProvider.notifier).toggleConcept('sofa');
///
/// // Set instance
/// ref.read(paletteProvider.notifier).setInstance('sofa', 2);
///
/// // Toggle protect
/// ref.read(paletteProvider.notifier).toggleProtect('sofa');
/// ```

abstract class _$Palette extends $Notifier<PaletteState> {
  PaletteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PaletteState, PaletteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PaletteState, PaletteState>,
              PaletteState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
