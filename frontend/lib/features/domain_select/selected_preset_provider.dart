import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../palette/palette_provider.dart';

part 'selected_preset_provider.g.dart';

/// Tracks the currently selected domain preset ID.
///
/// When domain changes, resets palette concept selections.
@riverpod
class SelectedPreset extends _$SelectedPreset {
  @override
  String? build() => null;

  void select(String presetId) {
    if (state == presetId) return;
    state = presetId;
    ref.read(paletteProvider.notifier).reset();
  }
}
