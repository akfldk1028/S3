import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain_select/presets_provider.dart';
import '../../domain_select/selected_preset_provider.dart';
import '../../workspace/theme.dart';

/// Side drawer for domain (preset) selection.
///
/// Shows S3 logo, domain list with highlight on selected, and navigation links.
class DomainDrawer extends ConsumerWidget {
  const DomainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetsProvider);
    final selectedId = ref.watch(selectedPresetProvider);

    return Drawer(
      backgroundColor: WsColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: S3 logo ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: WsColors.glassWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: WsColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'S3',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'S3',
                    style: TextStyle(
                      color: WsColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: WsColors.glassBorder, height: 24),

            // ── Domains section ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'DOMAINS',
                style: TextStyle(
                  color: WsColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            presetsAsync.when(
              data: (presets) => Column(
                children: presets.map((preset) {
                  final isSelected = selectedId == preset.id;
                  return _DomainTile(
                    name: preset.name,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(selectedPresetProvider.notifier)
                          .select(preset.id);
                      Navigator.of(context).pop(); // close drawer
                    },
                  );
                }).toList(),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WsColors.accent1,
                    ),
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load',
                  style: TextStyle(color: WsColors.error, fontSize: 13),
                ),
              ),
            ),

            const Spacer(),

            // ── Bottom links ──
            const Divider(color: WsColors.glassBorder, height: 1),
            _NavTile(
              icon: Icons.rule_rounded,
              label: 'My Rules',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/rules');
              },
            ),
            _NavTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Single domain row in the drawer.
class _DomainTile extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _DomainTile({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? WsColors.accent1.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: WsColors.accent1.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? WsColors.accent1 : WsColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected
                        ? WsColors.textPrimary
                        : WsColors.textSecondary,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation tile (My Rules, Settings).
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: WsColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: WsColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
