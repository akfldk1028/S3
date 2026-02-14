import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/api_client_provider.dart';
import 'secure_storage_service.dart';

part 'auth_provider.g.dart';

/// Riverpod provider for JWT authentication state.
///
/// Manages anonymous JWT authentication flow:
/// - On app launch: checks if JWT exists in secure storage
/// - login(): calls POST /auth/anon, saves JWT, updates state
/// - logout(): deletes JWT from secure storage, updates state to null
///
/// State: `AsyncValue<String?>` where String is the JWT token.
///
/// Usage:
/// ```dart
/// // Watch auth state
/// final authState = ref.watch(authProvider);
///
/// // Trigger login
/// await ref.read(authProvider.notifier).login();
///
/// // Trigger logout
/// await ref.read(authProvider.notifier).logout();
/// ```
@riverpod
class Auth extends _$Auth {
  final _storageService = SecureStorageService();

  @override
  FutureOr<String?> build() async {
    // Initialize: check if JWT exists in secure storage
    return await _storageService.readToken();
  }

  /// Performs anonymous login via POST /auth/anon.
  ///
  /// 1. Calls apiClient.createAnonUser() to get JWT
  /// 2. Saves JWT to secure storage
  /// 3. Updates state to authenticated with JWT token
  ///
  /// Throws if API call fails or JWT is missing from response.
  Future<void> login() async {
    final apiClient = ref.read(apiClientProvider);

    // Call POST /auth/anon endpoint
    final response = await apiClient.createAnonUser();
    final jwt = response['token'] as String?;

    if (jwt == null || jwt.isEmpty) {
      throw Exception('Anonymous auth failed: No token in response');
    }

    // Save JWT to secure storage
    await _storageService.saveToken(jwt);

    // Update Riverpod state
    state = AsyncValue.data(jwt);
  }

  /// Logs out the current user.
  ///
  /// 1. Deletes JWT from secure storage
  /// 2. Updates state to unauthenticated (null)
  Future<void> logout() async {
    await _storageService.deleteToken();
    state = const AsyncValue.data(null);
  }
}
