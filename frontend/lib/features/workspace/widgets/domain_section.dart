import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../../domain_select/presets_provider.dart';
import '../workspace_provider.dart';

class DomainSection extends ConsumerWidget {
  const DomainSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetsProvider);
    final selectedId = ref.watch(workspaceProvider).selectedPresetId;

    return presetsAsync.when(
      data: (presets) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final preset in presets) _DomainChip(
              name: preset.name,
              conceptCount: preset.conceptCount ?? 0,
              selected: selectedId == preset.id,
              onTap: () =>
                  ref.read(workspaceProvider.notifier).selectPreset(preset.id),
            ),
          ],
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
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
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Failed to load domains',
          style: TextStyle(fontSize: 12, color: WsColors.error.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  final String name;
  final int conceptCount;
  final bool selected;
  final VoidCallback onTap;

  const _DomainChip({
    required this.name,
    required this.conceptCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? WsColors.accent1.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(WsTheme.radiusSm),
            border: Border.all(
              color: selected ? WsColors.accent1.withValues(alpha: 0.4) : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? WsColors.gradientPrimary : null,
                  color: selected ? null : WsColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? WsColors.textPrimary : WsColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$conceptCount',
                style: const TextStyle(
                  fontSize: 11,
                  color: WsColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
