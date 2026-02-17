// ignore_for_file: unused_import

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
    // TODO(subtask-1-2): Implement diamond badge overlay
    return child;
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
    // TODO(subtask-1-3): Implement Free vs Pro comparison table
    return const SizedBox.shrink();
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
