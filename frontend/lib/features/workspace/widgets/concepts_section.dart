import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../../palette/palette_provider.dart';
import '../preset_detail_provider.dart';
import '../workspace_provider.dart';

class ConceptsSection extends ConsumerWidget {
  const ConceptsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetId = ref.watch(workspaceProvider).selectedPresetId;
    final paletteState = ref.watch(paletteProvider);

    if (presetId == null) {
      return const Text(
        'Select a domain first',
        style: TextStyle(fontSize: 12, color: WsColors.textMuted),
      );
    }

    final presetAsync = ref.watch(presetDetailProvider(presetId));

    return presetAsync.when(
      data: (preset) {
        final concepts = preset.concepts ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concept chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: concepts.map((concept) {
                final selected =
                    paletteState.selectedConcepts.containsKey(concept);
                return GestureDetector(
                  onTap: () =>
                      ref.read(paletteProvider.notifier).toggleConcept(concept),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: selected ? WsColors.gradientPrimary : null,
                      color: selected ? null : WsColors.glassWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : WsColors.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      concept,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? Colors.white
                            : WsColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Instance selectors
            if (paletteState.selectedConcepts.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...paletteState.selectedConcepts.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: WsColors.gradientPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: WsColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      for (int i = 1; i <= 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(paletteProvider.notifier)
                                .setInstance(entry.key, i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: entry.value == i
                                    ? WsColors.gradientPrimary
                                    : null,
                                color: entry.value == i
                                    ? null
                                    : WsColors.glassWhite,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: entry.value == i
                                      ? Colors.transparent
                                      : WsColors.glassBorder,
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '#$i',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: entry.value == i
                                        ? Colors.white
                                        : WsColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: WsColors.accent1,
          ),
        ),
      ),
      error: (e, st) => Text(
        'Failed to load concepts',
        style: TextStyle(fontSize: 12, color: WsColors.error.withValues(alpha: 0.8)),
      ),
    );
  }
}
