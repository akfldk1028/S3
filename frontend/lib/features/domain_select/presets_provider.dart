import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/models/preset.dart';
import '../../core/api/api_client_provider.dart';

part 'presets_provider.g.dart';

/// Riverpod provider for fetching available presets (domains).
///
/// Fetches the list of presets from GET /presets API endpoint.
/// Used in domain selection screen to display available domains
/// (e.g., "건축/인테리어", "쇼핑/셀러").
///
/// Returns: Future<List<Preset>> with id, name, conceptCount fields.
///
/// Usage:
/// ```dart
/// final presetsAsync = ref.watch(presetsProvider);
/// presetsAsync.when(
///   data: (presets) => ListView(children: presets.map(...)),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
/// ```
@riverpod
Future<List<Preset>> presets(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getPresets();
}
