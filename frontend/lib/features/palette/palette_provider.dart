import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'palette_state.dart';

part 'palette_provider.g.dart';

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
@riverpod
class Palette extends _$Palette {
  @override
  PaletteState build() {
    // Initialize with empty state
    return const PaletteState();
  }

  /// Toggles a concept on/off.
  ///
  /// If concept is not selected: adds it with instance #1
  /// If concept is already selected: removes it (and its protect flag if any)
  void toggleConcept(String conceptName) {
    final currentState = state;
    final selectedConcepts = Map<String, int>.from(currentState.selectedConcepts);
    final protectConcepts = Set<String>.from(currentState.protectConcepts);

    if (selectedConcepts.containsKey(conceptName)) {
      // Remove concept
      selectedConcepts.remove(conceptName);
      protectConcepts.remove(conceptName);
    } else {
      // Add concept with instance #1 by default
      selectedConcepts[conceptName] = 1;
    }

    state = currentState.copyWith(
      selectedConcepts: selectedConcepts,
      protectConcepts: protectConcepts,
    );
  }

  /// Sets the instance number for a concept.
  ///
  /// The concept must be selected first. Instance numbers are 1-based.
  /// Example: setInstance('sofa', 2) selects sofa instance #2
  void setInstance(String conceptName, int instanceIndex) {
    final currentState = state;
    final selectedConcepts = Map<String, int>.from(currentState.selectedConcepts);

    if (!selectedConcepts.containsKey(conceptName)) {
      // Auto-select concept if not already selected
      selectedConcepts[conceptName] = instanceIndex;
    } else {
      selectedConcepts[conceptName] = instanceIndex;
    }

    state = currentState.copyWith(selectedConcepts: selectedConcepts);
  }

  /// Toggles the "protect" flag for a concept.
  ///
  /// Protected concepts won't be modified during job processing.
  /// The concept must be selected before it can be protected.
  void toggleProtect(String conceptName) {
    final currentState = state;
    final protectConcepts = Set<String>.from(currentState.protectConcepts);

    // Only allow protecting concepts that are selected
    if (!currentState.selectedConcepts.containsKey(conceptName)) {
      return;
    }

    if (protectConcepts.contains(conceptName)) {
      protectConcepts.remove(conceptName);
    } else {
      protectConcepts.add(conceptName);
    }

    state = currentState.copyWith(protectConcepts: protectConcepts);
  }

  /// Resets all selections to empty state.
  ///
  /// Used when navigating back or starting fresh.
  void reset() {
    state = const PaletteState();
  }
}
