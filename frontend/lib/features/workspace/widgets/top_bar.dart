import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

/// Top navigation bar shown when photos are selected.
///
/// Displays the app name and user credit balance.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: WsColors.surface,
        border: Border(
          bottom: BorderSide(color: WsColors.glassBorder, width: 0.5),
        ),
      ),
      child: const Row(
        children: [
          Text(
            'S3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: WsColors.textPrimary,
              letterSpacing: -1,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
