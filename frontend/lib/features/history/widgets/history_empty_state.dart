import 'package:flutter/material.dart';
import '../../workspace/theme.dart';

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WsColors.accent1.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: WsColors.accent1,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No jobs yet',
              style: TextStyle(
                color: WsColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your processed jobs will appear here',
              style: TextStyle(
                color: WsColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
