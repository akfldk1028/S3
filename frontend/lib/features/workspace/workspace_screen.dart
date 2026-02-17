import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/action_bar.dart';
import 'widgets/concepts_section.dart';
import 'widgets/photo_grid.dart';
import 'widgets/progress_overlay.dart';
import 'widgets/protect_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorkspaceScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Main workspace screen.
///
/// Manages photo selection, concept configuration, and job submission.
///
/// Layout is responsive:
/// - Desktop (≥ 840 px wide): sidebar + photo area side-by-side.
/// - Mobile (< 840 px): single-column scrollable layout.
///
/// Two ambient gradient orbs are rendered as the first [Positioned] children
/// in both the desktop and mobile [Stack]s (see [_buildBody]) to create a
/// subtle depth backdrop without intercepting touch events.
class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  // ── Photo state ───────────────────────────────────────────────────────────
  final List<PhotoItem> _photos = [];

  // ── Concept state ─────────────────────────────────────────────────────────
  static const List<String> _allConcepts = [
    'Modern',
    'Minimalist',
    'Industrial',
    'Scandinavian',
    'Bohemian',
    'Classic',
  ];

  final Set<String> _selectedConcepts = {};
  int _instanceCount = 1;

  // ── Protect state ─────────────────────────────────────────────────────────
  static const List<String> _protectOptions = [
    'Furniture',
    'Windows',
    'Doors',
    'Fixtures',
    'Artwork',
  ];

  final Set<String> _selectedProtects = {};

  // ── Job / upload state ────────────────────────────────────────────────────
  OverlayStatus? _overlayStatus;
  double _progressValue = 0.0;
  ActionBarState _actionBarState = ActionBarState.idle;
  double _uploadProgress = 0.0;

  // ── Photo callbacks ───────────────────────────────────────────────────────
  void _handleAddPhotos() {
    setState(() {
      _photos.add(PhotoItem(
        id: 'photo_${_photos.length}',
        path: 'assets/placeholder_${_photos.length}.jpg',
      ));
    });
  }

  void _handleRemovePhoto(String id) {
    setState(() {
      _photos.removeWhere((p) => p.id == id);
    });
  }

  // ── Concept callbacks ─────────────────────────────────────────────────────
  void _handleConceptToggled(String concept) {
    setState(() {
      if (_selectedConcepts.contains(concept)) {
        _selectedConcepts.remove(concept);
      } else {
        _selectedConcepts.add(concept);
      }
    });
  }

  void _handleInstanceSelected(int count) {
    setState(() => _instanceCount = count);
  }

  // ── Protect callbacks ─────────────────────────────────────────────────────
  void _handleProtectToggled(String option) {
    setState(() {
      if (_selectedProtects.contains(option)) {
        _selectedProtects.remove(option);
      } else {
        _selectedProtects.add(option);
      }
    });
  }

  // ── Action bar callbacks ──────────────────────────────────────────────────
  void _handleGo() {
    if (_photos.isEmpty || _selectedConcepts.isEmpty) return;
    setState(() {
      _actionBarState = ActionBarState.uploading;
      _uploadProgress = 0.0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _actionBarState = ActionBarState.running;
        _overlayStatus = OverlayStatus.running;
        _progressValue = 0.0;
      });
    });
  }

  void _handleCancel() {
    setState(() {
      _actionBarState = ActionBarState.idle;
      _overlayStatus = null;
      _progressValue = 0.0;
      _uploadProgress = 0.0;
    });
  }

  void _handleRetry() {
    setState(() {
      _actionBarState = ActionBarState.idle;
      _overlayStatus = null;
      _progressValue = 0.0;
      _uploadProgress = 0.0;
    });
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: WsColors.glassWhite,
        border: Border(
          right: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(WsTheme.spacingXl),
            child: Text(
              'Workspace',
              style: TextStyle(
                color: WsColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(color: WsColors.glassBorder, height: 0.5),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WsTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConceptsSection(
                    concepts: _allConcepts,
                    selectedConcepts: _selectedConcepts,
                    onConceptToggled: _handleConceptToggled,
                    instanceCount: _instanceCount,
                    onInstanceSelected: _handleInstanceSelected,
                  ),
                  const SizedBox(height: WsTheme.spacingLg),
                  ProtectSection(
                    protectItems: _protectOptions,
                    selectedItems: _selectedProtects,
                    onItemToggled: _handleProtectToggled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo area ────────────────────────────────────────────────────────────
  Widget _buildPhotoArea() {
    return Expanded(
      child: Stack(
        children: [
          PhotoGrid(
            photos: _photos,
            onAddPhotos: _handleAddPhotos,
            onRemovePhoto: _handleRemovePhoto,
          ),
          if (_overlayStatus != null)
            ProgressOverlay(
              status: _overlayStatus!,
              progressValue: _progressValue,
              onCancel: _handleCancel,
            ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  /// Returns the responsive body, switching between a desktop two-column
  /// layout and a mobile single-column layout based on available width.
  ///
  /// Both layouts use a [Stack] whose FIRST two children are ambient gradient
  /// orbs (wrapped in [IgnorePointer]) so they render behind all interactive
  /// content without consuming pointer events.
  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 840;

        if (isDesktop) {
          // ── Desktop layout ──────────────────────────────────────────────
          return Stack(
            children: [
              // Orb 1 — top-left, accent1 at 8 % opacity.
              IgnorePointer(
                child: Positioned(
                  top: -150,
                  left: -150,
                  child: Container(
                    width: 600,
                    height: 600,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WsColors.accent1.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              // Orb 2 — bottom-right, accent2 at 4 % opacity.
              IgnorePointer(
                child: Positioned(
                  bottom: -150,
                  right: -150,
                  child: Container(
                    width: 600,
                    height: 600,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WsColors.accent2.withValues(alpha: 0.04),
                    ),
                  ),
                ),
              ),
              // Main desktop content.
              Row(
                children: [
                  _buildSidebar(),
                  _buildPhotoArea(),
                ],
              ),
            ],
          );
        }

        // ── Mobile layout ────────────────────────────────────────────────
        return Stack(
          children: [
            // Orb 1 — top-left, accent1 at 8 % opacity.
            IgnorePointer(
              child: Positioned(
                top: -150,
                left: -150,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WsColors.accent1.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            // Orb 2 — bottom-right, accent2 at 4 % opacity.
            IgnorePointer(
              child: Positioned(
                bottom: -150,
                right: -150,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WsColors.accent2.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ),
            // Main mobile content.
            Column(
              children: [
                _buildPhotoArea(),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Root widget ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final canGo = _photos.isNotEmpty && _selectedConcepts.isNotEmpty;

    return Scaffold(
      backgroundColor: WsColors.bgDark,
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          WorkspaceActionBar(
            state: _actionBarState,
            uploadProgress: _uploadProgress,
            onGo: canGo ? _handleGo : null,
            onCancel: _handleCancel,
            onRetry: _handleRetry,
          ),
        ],
      ),
    );
  }
}
