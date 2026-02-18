import 'package:flutter/material.dart';

import '../theme.dart';
import 'concepts_section.dart';
import 'domain_section.dart';
import 'protect_section.dart';
import 'rules_section.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: WsColors.surface,
        border: Border(
          right: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: const [
                _Section(
                  title: 'Domain',
                  icon: Icons.apps_rounded,
                  initiallyExpanded: true,
                  child: DomainSection(),
                ),
                _Section(
                  title: 'Concepts',
                  icon: Icons.palette_outlined,
                  initiallyExpanded: true,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: ConceptsSection(),
                  ),
                ),
                _Section(
                  title: 'Protect',
                  icon: Icons.shield_outlined,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: ProtectSection(),
                  ),
                ),
                _Section(
                  title: 'Rules',
                  icon: Icons.auto_fix_high_rounded,
                  child: RulesSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: ShaderMask(
          shaderCallback: (bounds) =>
              WsColors.gradientPrimary.createShader(bounds),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WsColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: EdgeInsets.zero,
        iconColor: WsColors.textMuted,
        collapsedIconColor: WsColors.textMuted,
        children: [child],
      ),
    );
  }
}
