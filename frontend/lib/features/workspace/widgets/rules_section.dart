import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/rule.dart';
import '../theme.dart';
import '../../palette/palette_provider.dart';
import '../../rules/rules_provider.dart';
import '../workspace_provider.dart';

class RulesSection extends ConsumerWidget {
  const RulesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(rulesProvider);
    final selectedRuleId = ref.watch(workspaceProvider).selectedRuleId;

    return rulesAsync.when(
      data: (rules) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Current settings" option
              _RuleTile(
                name: 'Current settings',
                subtitle: 'Use selected concepts',
                selected: selectedRuleId == null,
                onTap: () =>
                    ref.read(workspaceProvider.notifier).selectRule(null),
              ),
              ...rules.map((rule) => _RuleTile(
                    name: rule.name,
                    subtitle: rule.presetId,
                    selected: selectedRuleId == rule.id,
                    onTap: () =>
                        ref.read(workspaceProvider.notifier).selectRule(rule.id),
                    onDelete: () => _confirmDelete(context, ref, rule),
                  )),
              const SizedBox(height: 8),
              // New rule button
              GestureDetector(
                onTap: () => _showRuleEditor(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: WsColors.glassWhite,
                    borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                    border: Border.all(
                      color: WsColors.glassBorder,
                      width: 0.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 14, color: WsColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Save Rule',
                        style: TextStyle(
                          fontSize: 12,
                          color: WsColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          'Failed to load rules',
          style: TextStyle(fontSize: 12, color: WsColors.error.withValues(alpha: 0.8)),
        ),
      ),
    );
  }

  void _showRuleEditor(BuildContext context, WidgetRef ref) {
    final presetId = ref.read(workspaceProvider).selectedPresetId;
    if (presetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select a domain first'),
          backgroundColor: WsColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _RuleEditorDialog(presetId: presetId),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Rule rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WsColors.surface,
        title: const Text('Delete Rule',
            style: TextStyle(color: WsColors.textPrimary)),
        content: Text('Delete "${rule.name}"?',
            style: const TextStyle(color: WsColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: WsColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(rulesProvider.notifier).deleteRule(rule.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: WsColors.error)),
          ),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _RuleTile({
    required this.name,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.onDelete,
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
            color: selected
                ? WsColors.accent1.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(WsTheme.radiusSm),
            border: Border.all(
              color: selected
                  ? WsColors.accent1.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 16,
                color: selected ? WsColors.accent1 : WsColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? WsColors.textPrimary
                            : WsColors.textSecondary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: WsColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: WsColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleEditorDialog extends ConsumerStatefulWidget {
  final String presetId;

  const _RuleEditorDialog({required this.presetId});

  @override
  ConsumerState<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends ConsumerState<_RuleEditorDialog> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: WsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WsTheme.radiusLg),
        side: const BorderSide(color: WsColors.glassBorder, width: 0.5),
      ),
      title: const Text('Save Rule',
          style: TextStyle(color: WsColors.textPrimary, fontSize: 16)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: WsColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rule name',
                hintStyle: const TextStyle(color: WsColors.textMuted),
                filled: true,
                fillColor: WsColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                  borderSide:
                      const BorderSide(color: WsColors.glassBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                  borderSide:
                      const BorderSide(color: WsColors.glassBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                  borderSide:
                      const BorderSide(color: WsColors.accent1, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Saves your current concept & protect selections as a reusable rule.',
              style: TextStyle(fontSize: 12, color: WsColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              const Text('Cancel', style: TextStyle(color: WsColors.textMuted)),
        ),
        GestureDetector(
          onTap: _saving ? null : _save,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: WsColors.gradientPrimary,
              borderRadius: BorderRadius.circular(WsTheme.radiusSm),
            ),
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final palette = ref.read(paletteProvider);
      final concepts = <String, ConceptAction>{};
      for (final key in palette.selectedConcepts.keys) {
        concepts[key] = const ConceptAction(action: 'recolor');
      }

      await ref.read(rulesProvider.notifier).createRule(
            name: name,
            presetId: widget.presetId,
            concepts: concepts,
            protect: palette.protectConcepts.toList(),
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
