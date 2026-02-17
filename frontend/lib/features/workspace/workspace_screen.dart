import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import 'theme.dart';
import 'workspace_provider.dart';
import 'workspace_state.dart';
import 'widgets/action_bar.dart';
import 'widgets/mobile_bottom_sheet.dart';
import 'widgets/photo_grid.dart';
import 'widgets/progress_overlay.dart';
import 'widgets/results_overlay.dart';
import 'widgets/side_panel.dart';
import 'widgets/top_bar.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  bool _autoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    if (_autoLoginAttempted) return;
    _autoLoginAttempted = true;

    final authState = ref.read(authProvider);
    final token = authState.value;

    if (token == null || token.isEmpty) {
      try {
        await ref.read(authProvider.notifier).login();
      } catch (_) {
        // Auth failed — will show error state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => Scaffold(
        backgroundColor: WsColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WsColors.accent1,
                  backgroundColor: WsColors.glassWhite,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Setting up...',
                style: TextStyle(
                  fontSize: 13,
                  color: WsColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: WsColors.bg,
        body: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: WsColors.surface,
              borderRadius: BorderRadius.circular(WsTheme.radiusLg),
              border: Border.all(color: WsColors.glassBorder, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: WsColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: WsColors.error.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(Icons.wifi_off_rounded,
                      size: 24, color: WsColors.error),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Connection Failed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: WsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: WsColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    _autoLoginAttempted = false;
                    _tryAutoLogin();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: WsColors.gradientPrimary,
                      borderRadius:
                          BorderRadius.circular(WsTheme.radiusXl),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (token) {
        if (token == null || token.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_autoLoginAttempted) _tryAutoLogin();
          });
          return Scaffold(
            backgroundColor: WsColors.bg,
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WsColors.accent1,
                backgroundColor: WsColors.glassWhite,
              ),
            ),
          );
        }

        return _buildWorkspace(context);
      },
    );
  }

  Widget _buildWorkspace(BuildContext context) {
    final ws = ref.watch(workspaceProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final hasPhotos = ws.selectedImages.isNotEmpty;
    final showControls = hasPhotos && ws.phase != WorkspacePhase.done;

    return Scaffold(
      backgroundColor: WsColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // SNOW-like: minimal top bar when no photos, full bar after
            if (hasPhotos) const TopBar(),
            Expanded(
              child: _buildBody(ws, isDesktop),
            ),
            if (showControls) const ActionBar(),
          ],
        ),
      ),
      floatingActionButton: !isDesktop && showControls
          ? Container(
              decoration: BoxDecoration(
                gradient: WsColors.gradientPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: WsColors.accent1.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                onPressed: () => MobileBottomSheet.show(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.tune_rounded,
                    color: Colors.white, size: 20),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(WorkspaceState ws, bool isDesktop) {
    if (ws.phase == WorkspacePhase.done) {
      return const ResultsOverlay();
    }

    final hasPhotos = ws.selectedImages.isNotEmpty;

    // SNOW-like: full-screen photo picker when no photos yet
    if (!hasPhotos) {
      return const PhotoGrid();
    }

    if (isDesktop) {
      return Row(
        children: [
          const SidePanel(),
          Expanded(
            child: Stack(
              children: [
                const PhotoGrid(),
                if (ws.phase == WorkspacePhase.processing)
                  const ProgressOverlay(),
                if (ws.errorMessage != null)
                  _ErrorBanner(message: ws.errorMessage!),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const PhotoGrid(),
        if (ws.phase == WorkspacePhase.processing) const ProgressOverlay(),
        if (ws.errorMessage != null)
          _ErrorBanner(message: ws.errorMessage!),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: WsColors.error.withValues(alpha: 0.15),
              border: const Border(
                bottom:
                    BorderSide(color: WsColors.glassBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: WsColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: WsColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
