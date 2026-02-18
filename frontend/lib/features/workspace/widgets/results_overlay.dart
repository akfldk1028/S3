import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';

/// Full-screen results viewer shown when phase == done.
///
/// Displays the processed output and provides options to download,
/// share, or start a new session.
class ResultsOverlay extends ConsumerWidget {
  const ResultsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(workspaceProvider.notifier);

    return Container(
      color: WsColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: WsColors.accent1,
            ),
            const SizedBox(height: 20),
            const Text(
              'Processing Complete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: WsColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your photos are ready.',
              style: TextStyle(
                fontSize: 14,
                color: WsColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: notifier.resetToIdle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: WsColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(WsTheme.radiusXl),
                ),
                child: const Text(
                  'Start Over',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
