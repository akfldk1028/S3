import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import '../../workspace/theme.dart';
import 'status_badge.dart';

/// A single row in the History list representing one past job.
///
/// Displays:
/// - 56×56 thumbnail (or a placeholder icon if no outputs are ready or URL fails)
/// - Preset name (with ellipsis on overflow) + StatusBadge
/// - Image count + formatted creation date
/// - Chevron right indicator
class JobHistoryItem extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobHistoryItem({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        job.outputsReady.isNotEmpty ? job.outputsReady.first.previewUrl : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: WsTheme.cardDecoration,
        child: Row(
          children: [
            // Thumbnail or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(WsTheme.radiusSm),
              child: thumbnailUrl != null
                  ? Image.network(
                      thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildThumbnailPlaceholder(),
                    )
                  : _buildThumbnailPlaceholder(),
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
                          job.preset,
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
                        '${job.progress.total} images',
                        style: const TextStyle(
                          color: WsColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(job.createdAt),
                        style: const TextStyle(
                          color: WsColors.textMuted,
                          fontSize: 11,
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

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}
