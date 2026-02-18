import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

@riverpod
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@riverpod
class AuthState extends _$AuthState {
  @override
  FutureOr<bool> build() async {
    try {
      final storage = ref.watch(secureStorageProvider);
      final token = await storage.read(key: 'accessToken');
      return token != null;
    } catch (_) {
      // FlutterSecureStorage may throw on web when WebCrypto API
      // encounters issues (e.g., key generation failure). Treat as
      // unauthenticated so the splash screen navigates to /login gracefully.
      return false;
    }
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'accessToken', value: accessToken);
    await storage.write(key: 'refreshToken', value: refreshToken);
    state = const AsyncData(true);
  }

  Future<void> clearTokens() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
    state = const AsyncData(false);
  }
}
