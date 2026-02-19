// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_preset_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the currently selected domain preset ID.
///
/// When domain changes, resets palette concept selections.

@ProviderFor(SelectedPreset)
final selectedPresetProvider = SelectedPresetProvider._();

/// Tracks the currently selected domain preset ID.
///
/// When domain changes, resets palette concept selections.
final class SelectedPresetProvider
    extends $NotifierProvider<SelectedPreset, String?> {
  /// Tracks the currently selected domain preset ID.
  ///
  /// When domain changes, resets palette concept selections.
  SelectedPresetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPresetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPresetHash();

  @$internal
  @override
  SelectedPreset create() => SelectedPreset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedPresetHash() => r'9d39c36ca879127ec5133b1d554bf1e6ea6cbcb3';

/// Tracks the currently selected domain preset ID.
///
/// When domain changes, resets palette concept selections.

abstract class _$SelectedPreset extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
