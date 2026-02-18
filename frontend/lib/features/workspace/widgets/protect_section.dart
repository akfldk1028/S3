import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../../palette/palette_provider.dart';

class ProtectSection extends ConsumerWidget {
  const ProtectSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteState = ref.watch(paletteProvider);
    final selectedConcepts = paletteState.selectedConcepts;
    final protectConcepts = paletteState.protectConcepts;

    if (selectedConcepts.isEmpty) {
      return const Text(
        'Select concepts first',
        style: TextStyle(fontSize: 12, color: WsColors.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lock to prevent changes:',
          style: TextStyle(fontSize: 11, color: WsColors.textMuted),
        ),
        const SizedBox(height: 8),
        ...selectedConcepts.keys.map((concept) {
          final isProtected = protectConcepts.contains(concept);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () =>
                  ref.read(paletteProvider.notifier).toggleProtect(concept),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isProtected
                      ? WsColors.warning.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                  border: Border.all(
                    color: isProtected
                        ? WsColors.warning.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProtected
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
                      size: 14,
                      color: isProtected
                          ? WsColors.warning
                          : WsColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      concept,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isProtected ? FontWeight.w600 : FontWeight.w400,
                        color: isProtected
                            ? WsColors.textPrimary
                            : WsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
