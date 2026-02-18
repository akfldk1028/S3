// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(presetDetail)
final presetDetailProvider = PresetDetailFamily._();

final class PresetDetailProvider
    extends $FunctionalProvider<AsyncValue<Preset>, Preset, FutureOr<Preset>>
    with $FutureModifier<Preset>, $FutureProvider<Preset> {
  PresetDetailProvider._({
    required PresetDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'presetDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$presetDetailHash();

  @override
  String toString() {
    return r'presetDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Preset> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Preset> create(Ref ref) {
    final argument = this.argument as String;
    return presetDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PresetDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$presetDetailHash() => r'f88eb580d64640e61079f9428f329851f9245299';

final class PresetDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Preset>, String> {
  PresetDetailFamily._()
    : super(
        retry: null,
        name: r'presetDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PresetDetailProvider call(String id) =>
      PresetDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'presetDetailProvider';
}
