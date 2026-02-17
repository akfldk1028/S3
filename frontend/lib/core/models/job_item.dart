/// A single processed image result returned from the AI worker.
///
/// [idx] is **1-based** — use `selectedImages[idx - 1]` when looking up the
/// original input bytes in [WorkspaceState.selectedImages].
class JobItem {
  const JobItem({
    required this.idx,
    required this.resultUrl,
    required this.previewUrl,
  });

  /// 1-based position of this item within the current job batch.
  final int idx;

  /// Full-resolution output image URL (AI-processed result).
  final String resultUrl;

  /// Thumbnail / preview URL (lower-resolution preview of the result).
  final String previewUrl;
}
