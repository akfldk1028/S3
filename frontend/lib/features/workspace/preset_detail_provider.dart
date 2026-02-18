import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client_provider.dart';
import '../../core/models/preset.dart';

part 'preset_detail_provider.g.dart';

@riverpod
Future<Preset> presetDetail(Ref ref, String id) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getPresetById(id);
}
