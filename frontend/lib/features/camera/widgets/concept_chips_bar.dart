import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_select/selected_preset_provider.dart';
import '../../palette/palette_provider.dart';
import '../../workspace/preset_detail_provider.dart';
import '../../workspace/theme.dart';

/// Horizontal scrolling concept chips shown above camera controls.
///
/// Shows concepts for the currently selected domain preset.
/// Hides when no domain is selected.
class ConceptChipsBar extends ConsumerWidget {
  const ConceptChipsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetId = ref.watch(selectedPresetProvider);
    if (presetId == null) return const SizedBox.shrink();

    final detailAsync = ref.watch(presetDetailProvider(presetId));
    final paletteState = ref.watch(paletteProvider);

    return detailAsync.when(
      data: (preset) {
        final concepts = preset.concepts;
        if (concepts == null || concepts.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: concepts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final concept = concepts[index];
              final isSelected =
                  paletteState.selectedConcepts.containsKey(concept);

              return GestureDetector(
                onTap: () {
                  ref.read(paletteProvider.notifier).toggleConcept(concept);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WsColors.accent1
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: WsColors.glassBorder,
                            width: 0.5,
                          ),
                  ),
                  child: Center(
                    child: Text(
                      concept,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: WsColors.accent1,
            ),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
