import 'package:freezed_annotation/freezed_annotation.dart';

part 'palette_state.freezed.dart';  // Freezed code generation
part 'palette_state.g.dart';         // JSON serialization

/// Represents the palette (concept selection) state.
///
/// Manages user selections for:
/// - Which concepts are selected
/// - Which instance (#1, #2, etc.) is chosen for each concept
/// - Which concepts have "protect" enabled
///
/// This state is passed to the upload screen to configure job parameters.
@freezed
class PaletteState with _$PaletteState {
  const factory PaletteState({
    /// Map of concept name to selected instance index (1-based).
    /// If a concept is in this map, it's considered "selected".
    /// Example: {'sofa': 2, 'wall': 1} means sofa #2 and wall #1 are selected.
    @Default({}) Map<String, int> selectedConcepts,

    /// Set of concept names that have "protect" enabled.
    /// Protected concepts won't be modified during job processing.
    /// Example: {'sofa', 'floor'} means sofa and floor are protected.
    @Default({}) Set<String> protectConcepts,
  }) = _PaletteState;

  factory PaletteState.fromJson(Map<String, dynamic> json) => _$PaletteStateFromJson(json);
}
