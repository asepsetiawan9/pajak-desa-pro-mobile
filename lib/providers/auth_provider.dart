import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/storage/session_manager.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

import '../core/navigation/navigation_service.dart';
import '../views/auth/login_screen.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  UserModel? _user;
  String? _errorMessage;
  bool _isAccessDeniedRole = false;
  String _currentBaseUrl = ApiConstants.defaultProductionVps;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAccessDeniedRole => _isAccessDeniedRole;
  String get currentBaseUrl => _currentBaseUrl;

  AuthProvider() {
    ApiService.onUnauthenticated = handleUnauthenticated;
    _initAuth();
  }

  Future<void> handleUnauthenticated() async {
    if (!_isLoggedIn) return;
    await SessionManager.clearSession();
    _user = null;
    _isLoggedIn = false;
    _isAccessDeniedRole = false;
    _errorMessage = 'Sesi telah berakhir atau tidak sah. Silakan login kembali.';
    notifyListeners();

    NavigationService.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    _currentBaseUrl = await SessionManager.getBaseUrl();
    final token = await SessionManager.getToken();
    final cachedUser = await SessionManager.getUser();

    if (token != null && token.isNotEmpty && cachedUser != null) {
      if (cachedUser.isMobileAllowed) {
        _user = cachedUser;
        _isLoggedIn = true;
        _isAccessDeniedRole = false;
      } else {
        // Token exists but user role is not allowed on mobile
        _isAccessDeniedRole = true;
        _isLoggedIn = false;
        await SessionManager.clearSession();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBaseUrl(String newUrl) async {
    await SessionManager.saveBaseUrl(newUrl);
    _currentBaseUrl = await SessionManager.getBaseUrl();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isAccessDeniedRole = false;
    notifyListeners();

    final response = await ApiService.post(
      ApiConstants.loginEndpoint,
      body: {
        'username': username,
        'password': password,
        'client_platform': 'mobile',
      },
      requireAuth: false,
    );

    if (response.success && response.data != null) {
      try {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] ?? data['token'];
        final userJson = data['user'];

        if (token != null && userJson != null) {
          final loggedUser = UserModel.fromJson(userJson);

          // Front-end RBAC Check for Mobile Platform
          if (!loggedUser.isMobileAllowed) {
            _isAccessDeniedRole = true;
            _errorMessage = 'Role ${loggedUser.role.toUpperCase()} tidak diizinkan mengakses aplikasi mobile. Aplikasi mobile khusus untuk Kolektor dan Kepala Desa.';
            _isLoading = false;
            notifyListeners();
            return false;
          }

          await SessionManager.saveToken(token.toString());
          await SessionManager.saveUser(loggedUser);

          _user = loggedUser;
          _isLoggedIn = true;
          _isAccessDeniedRole = false;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (e) {
        _errorMessage = 'Gagal memproses data login: ${e.toString()}';
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await ApiService.post(ApiConstants.logoutEndpoint);
    await SessionManager.clearSession();

    _user = null;
    _isLoggedIn = false;
    _isAccessDeniedRole = false;
    _isLoading = false;
    notifyListeners();
  }
}
