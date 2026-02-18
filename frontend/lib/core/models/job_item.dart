/// A single processed output item from a job.
///
/// [idx] is 1-based (from the backend). To access the corresponding
/// original image in WorkspaceState.selectedImages, use [idx] - 1.
class JobItem {
  final int idx;
  final String resultUrl;
  final String previewUrl;

  const JobItem({
    required this.idx,
    required this.resultUrl,
    required this.previewUrl,
  });
}
