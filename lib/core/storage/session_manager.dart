import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../../models/user_model.dart';

class SessionManager {
  static const String _keyToken = 'auth_bearer_token';
  static const String _keyUserData = 'user_data_json';
  static const String _tokenSalt = 'LENTERA_SECURE_TOKEN_SALT_2026';

  static String _encodeToken(String rawToken) {
    try {
      final combined = '$_tokenSalt:$rawToken';
      return base64Encode(utf8.encode(combined));
    } catch (_) {
      return rawToken;
    }
  }

  static String? _decodeToken(String? encodedToken) {
    if (encodedToken == null || encodedToken.isEmpty) return null;
    try {
      if (!encodedToken.contains(':') && !encodedToken.startsWith('1|') && !encodedToken.startsWith('2|')) {
        final decoded = utf8.decode(base64Decode(encodedToken));
        if (decoded.startsWith('$_tokenSalt:')) {
          return decoded.substring(_tokenSalt.length + 1);
        }
      }
      return encodedToken;
    } catch (_) {
      return encodedToken;
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final obfuscated = _encodeToken(token);
    await prefs.setString(_keyToken, obfuscated);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyToken);
    return _decodeToken(stored);
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveBaseUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    
    // Cegah menyimpan localhost atau local emulator di production setup
    if (trimmed.contains('10.0.2.2') || trimmed.contains('127.0.0.1') || trimmed.contains('localhost')) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https')) || uri.host.isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.customBaseUrlKey, trimmed);
    return true;
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(ApiConstants.customBaseUrlKey);
    if (customUrl != null && customUrl.isNotEmpty) {
      if (customUrl.contains('10.0.2.2') || customUrl.contains('127.0.0.1') || customUrl.contains('localhost')) {
        await prefs.remove(ApiConstants.customBaseUrlKey);
        return ApiConstants.defaultProductionVps;
      }
      return customUrl;
    }
    return ApiConstants.defaultProductionVps;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }
}
