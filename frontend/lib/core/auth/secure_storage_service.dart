import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service wrapper for FlutterSecureStorage providing JWT token persistence.
///
/// This service wraps flutter_secure_storage to provide a simple API for
/// saving, reading, and deleting JWT tokens securely. Tokens persist across
/// app restarts and are stored in platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
/// - Web: Web Crypto API
///
/// Usage:
/// ```dart
/// final storageService = SecureStorageService();
/// await storageService.saveToken('eyJhbGc...');
/// final token = await storageService.readToken();
/// await storageService.deleteToken();
/// ```
class SecureStorageService {
  // Use const for performance (singleton instance)
  static const _storage = FlutterSecureStorage();

  // Storage key for JWT token
  static const _jwtTokenKey = 'jwt_token';

  /// Saves JWT token to secure storage.
  ///
  /// [jwt] - The JWT token string to persist
  ///
  /// Returns a Future that completes when the token is saved.
  Future<void> saveToken(String jwt) async {
    await _storage.write(key: _jwtTokenKey, value: jwt);
  }

  /// Reads JWT token from secure storage.
  ///
  /// Returns the stored JWT token string, or null if no token exists.
  Future<String?> readToken() async {
    return await _storage.read(key: _jwtTokenKey);
  }

  /// Deletes JWT token from secure storage.
  ///
  /// Returns a Future that completes when the token is deleted.
  /// Safe to call even if no token exists.
  Future<void> deleteToken() async {
    await _storage.delete(key: _jwtTokenKey);
  }

  /// Checks if a JWT token exists in secure storage.
  ///
  /// Returns true if a token is stored, false otherwise.
  /// Useful for checking authentication state without reading the token.
  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}
