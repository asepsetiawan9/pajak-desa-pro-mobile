import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/desa_model.dart';

/// Provider untuk mengelola filter desa (khusus Admin Kecamatan / Super Admin System).
/// Menyediakan list desa dan state filter aktif untuk menyaring data lintas desa.
class DesaFilterProvider extends ChangeNotifier {
  List<DesaModel> _desaList = [];
  String _selectedDesaId = 'all';
  bool _isLoading = false;
  String? _errorMessage;

  List<DesaModel> get desaList => _desaList;
  String get selectedDesaId => _selectedDesaId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Apakah saat ini menampilkan seluruh desa (tanpa filter)
  bool get isAllDesa => _selectedDesaId == 'all';

  /// Mendapatkan objek desa yang sedang dipilih (null jika "Seluruh Desa")
  DesaModel? get selectedDesa {
    if (isAllDesa) return null;
    try {
      return _desaList.firstWhere(
        (d) => d.id.toString() == _selectedDesaId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Nama desa terpilih atau "Seluruh Desa"
  String get selectedDesaLabel {
    if (isAllDesa) return 'Seluruh Desa';
    return selectedDesa?.namaDesa ?? 'Desa Terpilih';
  }

  /// Fetch daftar desa dari backend API
  Future<void> fetchDesaList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.get(ApiConstants.desasEndpoint);

    if (response.success && response.data != null) {
      try {
        final List<dynamic> rawList = response.data is List
            ? response.data as List<dynamic>
            : (response.data is Map && response.data['data'] != null)
                ? response.data['data'] as List<dynamic>
                : [];

        _desaList = rawList
            .map((e) => DesaModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _errorMessage = 'Gagal memproses data desa: ${e.toString()}';
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set filter desa aktif
  void setSelectedDesa(String desaId) {
    _selectedDesaId = desaId;
    notifyListeners();
  }

  /// Reset filter ke "Seluruh Desa"
  void resetFilter() {
    _selectedDesaId = 'all';
    notifyListeners();
  }

  /// Query params untuk dikirim ke API (kosong jika "Seluruh Desa")
  Map<String, String> get queryParams {
    if (isAllDesa) return {};
    return {'desa_id': _selectedDesaId};
  }
}
