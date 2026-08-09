import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../storage/session_manager.dart';

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

typedef UnauthenticatedCallback = void Function();

class ApiService {
  static UnauthenticatedCallback? onUnauthenticated;

  static Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Platform': 'mobile',
    };

    if (requireAuth) {
      final token = await SessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams, bool requireAuth = true}) async {
    try {
      final baseUrl = await SessionManager.getBaseUrl();
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      return _processResponse(response, endpoint: endpoint);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Koneksi timeout. Pastikan backend server aktif.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  static Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, bool requireAuth = true}) async {
    try {
      final baseUrl = await SessionManager.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');

      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));

      return _processResponse(response, endpoint: endpoint);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Koneksi timeout. Silakan periksa jaringan server Anda.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  static ApiResponse _processResponse(http.Response response, {String? endpoint}) {
    if (response.statusCode == 401 && endpoint != null && !endpoint.contains('/auth/login')) {
      onUnauthenticated?.call();
    }

    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final bool success = body['success'] == true || response.statusCode == 200 || response.statusCode == 201;

      String message = body['message'] ?? 'Respon diterima';
      if (!success && body['errors'] != null) {
        if (body['errors'] is Map) {
          final errMap = body['errors'] as Map;
          final firstKey = errMap.keys.firstOrNull;
          if (firstKey != null && errMap[firstKey] is List) {
            message = (errMap[firstKey] as List).first.toString();
          }
        }
      }

      return ApiResponse(
        success: success,
        message: message,
        data: body['data'] ?? body,
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Respon server HTTP ${response.statusCode}',
        data: response.body,
        statusCode: response.statusCode,
      );
    }
  }
}
