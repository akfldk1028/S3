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
// MobilePipelineTabs
// ─────────────────────────────────────────────────────────────────────────────

/// Mobile-only persistent 4-tab bottom strip for the workspace pipeline.
///
/// Replaces the FAB + [MobileBottomSheet] pattern with a SNOW-style
/// persistent tab strip showing:
/// - **Palette**: [DomainSection] + [ConceptsSection]
/// - **Instances**: Coming Soon placeholder
/// - **Protect**: [ProtectSection]
/// - **Rules**: [RulesSection] + [ProBadge] on Save Rule
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
  @override
  Widget build(BuildContext context) {
    // TODO(subtask-2-1): Implement tab strip + IndexedStack panel layout
    return const SizedBox.shrink();
  }
}
