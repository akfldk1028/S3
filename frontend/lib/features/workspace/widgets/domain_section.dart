import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/shimmer_list.dart';

/// Provider for the list of domain presets.
///
/// Returns an empty list by default. Replace with a real API call when the
/// preset data source is available.
final presetsProvider = FutureProvider<List<String>>((ref) async {
  // TODO(spec-018): Replace with actual presets API call once presets API is implemented.
  return <String>[];
});

/// A widget that displays the domain/preset section of the workspace.
///
/// Shows a [ShimmerList] skeleton while [presetsProvider] is loading,
/// an error message if it fails, or the preset list once data is available.
class DomainSection extends ConsumerWidget {
  const DomainSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsAsync = ref.watch(presetsProvider);

    return presetsAsync.when(
      loading: () => const ShimmerList(count: 3),
      error: (error, _) => Center(
        child: Text(
          'Failed to load presets: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (presets) {
        if (presets.isEmpty) {
          return const Center(
            child: Text(
              'No presets available.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text(presets[index]),
              ),
            );
          },
        );
      },
    );
  }
}
