import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import '../../workspace/theme.dart';
import 'status_badge.dart';

/// A single row in the History list representing one past job.
///
/// Displays:
/// - Placeholder icon (thumbnail not available in current Job model)
/// - Job ID (truncated) + StatusBadge
/// - Progress info
/// - Chevron right indicator
class JobHistoryItem extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobHistoryItem({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: WsTheme.cardDecoration,
        child: Row(
          children: [
            // Thumbnail placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(WsTheme.radiusSm),
              child: _buildThumbnailPlaceholder(),
            ),
            const SizedBox(width: 12),
            // Job details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Job ${job.id.length > 8 ? job.id.substring(0, 8) : job.id}',
                          style: const TextStyle(
                            color: WsColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: job.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 12,
                        color: WsColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.progress != null ? '${job.progress}%' : 'N/A',
                        style: const TextStyle(
                          color: WsColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: WsColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: WsColors.surfaceLight,
      child: const Icon(Icons.image_outlined, color: WsColors.textMuted),
    );
  }
}
