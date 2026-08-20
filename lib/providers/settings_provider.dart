import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  SettingsModel _settings = SettingsModel.defaultSettings();
  bool _isLoading = false;
  String? _errorMessage;

  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  // 1. Call Api with Params
  Future<void> fetchSettings({int? desaId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, String> queryParams = {};
      if (desaId != null && desaId != 0) {
        queryParams['desa_id'] = desaId.toString();
      }

      final response = await ApiService.get(
        ApiConstants.settingsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          _settings = SettingsModel.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat pengaturan: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
