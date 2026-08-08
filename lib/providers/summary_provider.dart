import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/summary_model.dart';

class SummaryProvider extends ChangeNotifier {
  SummaryMetricsModel? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  SummaryMetricsModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiConstants.summaryMetricsEndpoint);

    if (response.success && response.data != null) {
      try {
        final Map<String, dynamic> dataMap = response.data is Map<String, dynamic> ? response.data : {};
        _summary = SummaryMetricsModel.fromJson(dataMap);
      } catch (e) {
        _errorMessage = 'Gagal memproses data statistik: ${e.toString()}';
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }
}
