import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'concepts_section.dart';
import 'domain_section.dart';
import 'protect_section.dart';
import 'rules_section.dart';

class MobileBottomSheet extends StatelessWidget {
  const MobileBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MobileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: WsColors.surface.withValues(alpha: 0.95),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(
              top: BorderSide(color: WsColors.glassBorder, width: 0.5),
              left: BorderSide(color: WsColors.glassBorder, width: 0.5),
              right: BorderSide(color: WsColors.glassBorder, width: 0.5),
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: WsColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: const [
                        _SheetSection(
                          title: 'Domain',
                          icon: Icons.category_rounded,
                          child: DomainSection(),
                        ),
                        _SheetSection(
                          title: 'Concepts',
                          icon: Icons.palette_rounded,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ConceptsSection(),
                          ),
                        ),
                        _SheetSection(
                          title: 'Protect',
                          icon: Icons.shield_rounded,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ProtectSection(),
                          ),
                        ),
                        _SheetSection(
                          title: 'Rules',
                          icon: Icons.auto_fix_high_rounded,
                          child: RulesSection(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SheetSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    WsColors.gradientPrimary.createShader(bounds),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: WsColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        child,
        Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: WsColors.glassBorder,
        ),
      ],
    );
  }
}
