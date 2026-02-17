import 'package:flutter/material.dart';

import '../theme.dart';

/// Workspace domain selection section.
///
/// Renders a horizontal list of domain option chips (toggleable).
/// Each chip represents a processing domain (e.g., Portrait, Landscape, Product).
class DomainSection extends StatelessWidget {
  const DomainSection({
    super.key,
    required this.domains,
    required this.selectedDomain,
    required this.onDomainSelected,
  });

  /// Full list of available domain labels.
  final List<String> domains;

  /// Currently selected domain label, or null if none selected.
  final String? selectedDomain;

  /// Callback fired when the user taps a domain chip.
  final ValueChanged<String> onDomainSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: domains.map((domain) {
          final isSelected = domain == selectedDomain;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onDomainSelected(domain),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? WsColors.accent1.withValues(alpha: 0.2)
                      : WsColors.glassWhite,
                  borderRadius:
                      BorderRadius.circular(WsTheme.radiusXl),
                  border: Border.all(
                    color:
                        isSelected ? WsColors.accent1 : WsColors.glassBorder,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Text(
                  domain,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? WsColors.accent1 : WsColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
