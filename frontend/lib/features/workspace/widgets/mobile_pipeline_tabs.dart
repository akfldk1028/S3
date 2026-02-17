// ignore_for_file: unused_import, unnecessary_import

import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';
import '../workspace_state.dart';
import '../../../core/auth/user_provider.dart';
import 'concepts_section.dart';
import 'domain_section.dart';
import 'protect_section.dart';
import 'rules_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProBadge
// ─────────────────────────────────────────────────────────────────────────────

/// Gradient diamond PRO badge overlay widget.
///
/// Wraps [child] with a gradient diamond "PRO" badge in the top-right corner
/// when [showBadge] is true. If [showBadge] is false, returns [child] unchanged.
///
/// Usage:
/// ```dart
/// ProBadge(
///   showBadge: !isPro && ruleSlots.used >= ruleSlots.max,
///   child: ElevatedButton(onPressed: _saveRule, child: Text('Save Rule')),
/// )
/// ```
class ProBadge extends StatelessWidget {
  const ProBadge({
    super.key,
    required this.child,
    this.showBadge = false,
  });

  final Widget child;

  /// When true, renders the gradient diamond PRO badge over [child].
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        const Positioned(
          top: -8,
          right: -8,
          child: _ProDiamondBadge(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProDiamondBadge (private)
// ─────────────────────────────────────────────────────────────────────────────

/// Rotated-square diamond badge displaying "PRO" in gradient colours.
///
/// The container is rotated 45° to form a diamond shape; the inner [Text]
/// is counter-rotated −45° so the label remains upright.
class _ProDiamondBadge extends StatelessWidget {
  const _ProDiamondBadge();

  static const double _size = 26.0;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: _size,
        height: _size,
        decoration: const BoxDecoration(
          gradient: WsColors.gradientDiagonal,
        ),
        child: Transform.rotate(
          angle: -pi / 4,
          child: const Center(
            child: Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PlanComparisonSheet
// ─────────────────────────────────────────────────────────────────────────────

/// Free vs Pro plan comparison bottom sheet.
///
/// Shows a 2-column comparison table of plan features:
/// - Rule Slots (2 / 20)
/// - Batch Size (10 / 200 photos)
/// - Concurrent Jobs (1 / 3)
///
/// Opened by tapping the credits pill in [TopBar].
class PlanComparisonSheet extends StatelessWidget {
  const PlanComparisonSheet({super.key});

  /// Shows the plan comparison sheet as a modal bottom sheet over [context].
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlanComparisonSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WsColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(WsTheme.radiusLg),
        ),
        border: const Border(
          top: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: WsColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'Plans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: WsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Compare Free and Pro features.',
            style: TextStyle(
              fontSize: 13,
              color: WsColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Comparison table
          const _ComparisonTable(),
          const SizedBox(height: 20),
          // Upgrade CTA
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: WsColors.gradientPrimary,
                borderRadius: BorderRadius.circular(WsTheme.radiusSm),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WsTheme.radiusSm),
                  ),
                ),
                child: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ComparisonTable (private)
// ─────────────────────────────────────────────────────────────────────────────

/// Two-column plan feature comparison table used by [PlanComparisonSheet].
///
/// Renders a header row (Free | Pro) followed by feature rows for:
/// Rule Slots, Batch Size, and Concurrent Jobs.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  // Plan feature rows: [label, freeValue, proValue]
  static const _rows = <(String, String, String)>[
    ('Rule Slots', '2', '20'),
    ('Batch Size', '10 photos', '200 photos'),
    ('Concurrent Jobs', '1', '3'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(WsTheme.radius),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          _buildHeaderRow(),
          const Divider(color: WsColors.glassBorder, height: 1, thickness: 0.5),
          // Feature rows
          for (int i = 0; i < _rows.length; i++) ...[
            _buildFeatureRow(_rows[i]),
            if (i < _rows.length - 1)
              const Divider(
                  color: WsColors.glassBorder, height: 1, thickness: 0.5),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Feature label column (spacer)
          const Expanded(child: SizedBox.shrink()),
          // Free column header
          Expanded(
            child: Center(
              child: Text(
                'Free',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WsColors.textSecondary,
                ),
              ),
            ),
          ),
          // Pro column header with gradient text
          Expanded(
            child: Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    WsColors.gradientPrimary.createShader(bounds),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow((String, String, String) row) {
    final (label, freeVal, proVal) = row;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Feature label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: WsColors.textPrimary,
              ),
            ),
          ),
          // Free value
          Expanded(
            child: Center(
              child: Text(
                freeVal,
                style: const TextStyle(
                  fontSize: 13,
                  color: WsColors.textSecondary,
                ),
              ),
            ),
          ),
          // Pro value (gradient highlight)
          Expanded(
            child: Center(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    WsColors.gradientPrimary.createShader(bounds),
                child: Text(
                  proVal,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabItem
// ─────────────────────────────────────────────────────────────────────────────

/// Defines a single tab entry in [MobilePipelineTabs].
class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

// ─────────────────────────────────────────────────────────────────────────────
// MobilePipelineTabs
// ─────────────────────────────────────────────────────────────────────────────

/// Mobile-only persistent 4-tab bottom strip for the workspace pipeline.
///
/// Replaces the FAB + [MobileBottomSheet] pattern with a SNOW-style
/// persistent tab strip showing:
/// - **Palette** (index 0): [DomainSection] + [ConceptsSection]
/// - **Instances** (index 1): Coming Soon placeholder
/// - **Protect** (index 2): [ProtectSection]
/// - **Rules** (index 3): [RulesSection] + [ProBadge] on Save Rule
///
/// Only visible on mobile viewports (width < 768) when photos are selected
/// and the workspace phase is not [WorkspacePhase.done].
///
/// On desktop (width >= 768), returns [SizedBox.shrink] immediately.
class MobilePipelineTabs extends ConsumerStatefulWidget {
  const MobilePipelineTabs({super.key});

  @override
  ConsumerState<MobilePipelineTabs> createState() => _MobilePipelineTabsState();
}

class _MobilePipelineTabsState extends ConsumerState<MobilePipelineTabs> {
  /// Index of the currently selected tab (0–3).
  int _selectedTab = 0;

  /// Currently selected domain in the Palette panel.
  String? _selectedDomain;

  /// Active concept labels in the Palette panel.
  final _selectedConcepts = <String>{};

  /// Instance count selection in the Palette panel (1–3).
  int _instanceCount = 1;

  /// Active protect-element labels in the Protect panel.
  final _selectedProtectItems = <String>{};

  /// Tab definitions for the four pipeline sections.
  static const _tabs = <_TabItem>[
    _TabItem(label: 'Palette', icon: Icons.palette_rounded),
    _TabItem(label: 'Instances', icon: Icons.auto_awesome_motion_rounded),
    _TabItem(label: 'Protect', icon: Icons.shield_rounded),
    _TabItem(label: 'Rules', icon: Icons.rule_rounded),
  ];

  /// Available domain options shown in the Palette panel.
  static const _domains = <String>[
    'Portrait',
    'Landscape',
    'Product',
    'Fashion',
    'Architecture',
  ];

  /// Available concept options shown in the Palette panel.
  static const _concepts = <String>[
    'Hair',
    'Skin',
    'Eyes',
    'Background',
    'Clothing',
  ];

  /// Available protect-element options shown in the Protect panel.
  static const _protectItems = <String>[
    'Face',
    'Eyes',
    'Skin Tone',
    'Background',
    'Text',
  ];

  @override
  Widget build(BuildContext context) {
    final ws = ref.watch(workspaceProvider);
    final hasPhotos = ws.selectedImages.isNotEmpty;
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // Hidden on desktop, when no photos are selected, or after processing completes.
    if (isDesktop || !hasPhotos || ws.phase == WorkspacePhase.done) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Panel area: height capped at 60% of screen to leave room for content above.
        Container(
          decoration: const BoxDecoration(
            color: WsColors.glassWhite,
            border: Border(
              top: BorderSide(color: WsColors.glassBorder, width: 0.5),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: IndexedStack(
              index: _selectedTab,
              children: [
                // index 0 — Palette panel: domain + concept selection.
                _PalettePanel(
                  domains: _domains,
                  selectedDomain: _selectedDomain,
                  onDomainSelected: (d) => setState(() => _selectedDomain = d),
                  concepts: _concepts,
                  selectedConcepts: _selectedConcepts,
                  onConceptToggled: (c) => setState(() {
                    if (_selectedConcepts.contains(c)) {
                      _selectedConcepts.remove(c);
                    } else {
                      _selectedConcepts.add(c);
                    }
                  }),
                  instanceCount: _instanceCount,
                  onInstanceSelected: (n) =>
                      setState(() => _instanceCount = n),
                ),
                // index 1 — Instances panel: coming soon placeholder.
                const _ComingSoonPanel(),
                // index 2 — Protect panel: protect-element selection.
                _ProtectPanelWrapper(
                  protectItems: _protectItems,
                  selectedItems: _selectedProtectItems,
                  onItemToggled: (item) => setState(() {
                    if (_selectedProtectItems.contains(item)) {
                      _selectedProtectItems.remove(item);
                    } else {
                      _selectedProtectItems.add(item);
                    }
                  }),
                ),
                // index 3 — Rules panel: active rules + save rule button.
                const _RulesPanelWrapper(),
              ],
            ),
          ),
        ),
        // Tab strip: 56 px glassmorphism bar.
        _TabStrip(
          tabs: _tabs,
          selectedIndex: _selectedTab,
          onTap: (i) => setState(() => _selectedTab = i),
          showRulesBadge: false,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabStrip
// ─────────────────────────────────────────────────────────────────────────────

/// 56 px glassmorphism bottom tab bar with 4 equally-spaced pipeline tabs.
///
/// The selected tab renders its icon and label through a [ShaderMask] so they
/// appear in [WsColors.gradientPrimary]. Unselected tabs use
/// [WsColors.textMuted]. The strip sits above the system navigation bar via
/// [SafeArea] (top padding suppressed).
///
/// The Rules tab (index 3) shows a [ProBadge] overlay when [showRulesBadge]
/// is true (i.e. the free plan's rule-slot limit is reached).
///
/// Glassmorphism is achieved with [ClipRect] + [BackdropFilter] blur so that
/// whatever is rendered beneath the bar appears frosted.
class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.showRulesBadge = false,
  });

  final List<_TabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  /// When true, wraps the Rules tab (index 3) with a [ProBadge] diamond.
  final bool showRulesBadge;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SafeArea(
          top: false,
          child: Container(
            height: 56,
            decoration: const BoxDecoration(
              color: WsColors.glassWhite,
              border: Border(
                top: BorderSide(color: WsColors.glassBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: _buildTabCell(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single tab cell (icon + label), with optional [ProBadge].
  Widget _buildTabCell(int index) {
    final isSelected = index == selectedIndex;

    final icon = isSelected
        ? ShaderMask(
            shaderCallback: (bounds) =>
                WsColors.gradientPrimary.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Icon(tabs[index].icon, size: 18, color: Colors.white),
          )
        : Icon(tabs[index].icon, size: 18, color: WsColors.textMuted);

    final label = isSelected
        ? ShaderMask(
            shaderCallback: (bounds) =>
                WsColors.gradientPrimary.createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              tabs[index].label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        : Text(
            tabs[index].label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: WsColors.textMuted,
            ),
          );

    final cell = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [icon, const SizedBox(height: 2), label],
    );

    // Wrap the Rules tab (index 3) with a ProBadge when applicable.
    if (index == 3) {
      return ProBadge(showBadge: showRulesBadge, child: cell);
    }
    return cell;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PalettePanel
// ─────────────────────────────────────────────────────────────────────────────

/// Palette tab panel (index 0) combining [DomainSection] and [ConceptsSection].
///
/// The parent [_MobilePipelineTabsState] owns the domain / concept /
/// instance-count selections and passes them in; mutations fire setState on
/// the parent via the provided callbacks.
class _PalettePanel extends StatelessWidget {
  const _PalettePanel({
    required this.domains,
    required this.selectedDomain,
    required this.onDomainSelected,
    required this.concepts,
    required this.selectedConcepts,
    required this.onConceptToggled,
    required this.instanceCount,
    required this.onInstanceSelected,
  });

  final List<String> domains;
  final String? selectedDomain;
  final ValueChanged<String> onDomainSelected;
  final List<String> concepts;
  final Set<String> selectedConcepts;
  final ValueChanged<String> onConceptToggled;
  final int instanceCount;
  final ValueChanged<int> onInstanceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: WsTheme.spacingSm),
        DomainSection(
          domains: domains,
          selectedDomain: selectedDomain,
          onDomainSelected: onDomainSelected,
        ),
        ConceptsSection(
          concepts: concepts,
          selectedConcepts: selectedConcepts,
          onConceptToggled: onConceptToggled,
          instanceCount: instanceCount,
          onInstanceSelected: onInstanceSelected,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ComingSoonPanel
// ─────────────────────────────────────────────────────────────────────────────

/// "Coming Soon" placeholder shown at tab index 1 (Instances).
class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: WsTheme.spacingLg,
        vertical: WsTheme.spacingXl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_motion_rounded,
              size: 32,
              color: WsColors.textMuted,
            ),
            SizedBox(height: WsTheme.spacingSm),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: WsColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProtectPanelWrapper
// ─────────────────────────────────────────────────────────────────────────────

/// Protect tab panel (index 2) wrapping [ProtectSection].
///
/// The parent [_MobilePipelineTabsState] owns the selected protect-item set
/// and fires setState on mutations via [onItemToggled].
class _ProtectPanelWrapper extends StatelessWidget {
  const _ProtectPanelWrapper({
    required this.protectItems,
    required this.selectedItems,
    required this.onItemToggled,
  });

  final List<String> protectItems;
  final Set<String> selectedItems;
  final ValueChanged<String> onItemToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: WsTheme.spacingSm),
        ProtectSection(
          protectItems: protectItems,
          selectedItems: selectedItems,
          onItemToggled: onItemToggled,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RulesPanelWrapper
// ─────────────────────────────────────────────────────────────────────────────

/// Rules tab panel (index 3) wrapping [RulesSection].
///
/// [RulesSection] reads workspace state internally via Riverpod; no data
/// needs to be passed from the parent.
class _RulesPanelWrapper extends StatelessWidget {
  const _RulesPanelWrapper();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: WsTheme.spacingSm),
        RulesSection(),
      ],
    );
  }
}
