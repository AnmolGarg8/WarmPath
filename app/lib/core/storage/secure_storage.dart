import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'warmpath_jwt_token';
  static const String _refreshTokenKey = 'warmpath_refresh_token';
  static const String _userKey = 'warmpath_user_data';

  // Backward-compatible access token methods
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  // Token pair management
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await getToken();
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // User profile storage
  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Full session wipe (logout)
  static Future<void> clearAll() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
