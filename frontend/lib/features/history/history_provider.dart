import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client.dart';
import '../../core/models/job.dart';

part 'history_provider.g.dart';

@riverpod
class History extends _$History {
  @override
  FutureOr<List<Job>> build() async {
    final apiClient = ref.watch(apiClientProvider);
    return await apiClient.listJobs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiClient = ref.read(apiClientProvider);
      return await apiClient.listJobs();
    });
  }
}
