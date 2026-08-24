import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/kolektor_target_model.dart';

/// Provider untuk mengelola Target & Kinerja Kolektor di aplikasi Mobile
class KolektorTargetProvider extends ChangeNotifier {
  KolektorTargetModel? _myPerformance;
  List<KolektorTargetModel> _leaderboard = [];
  KolektorTargetModel? _selectedDetail;
  int _selectedTahun = DateTime.now().year;

  bool _isLoading = false;
  bool _isLoadingLeaderboard = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;

  // Getters
  KolektorTargetModel? get myPerformance => _myPerformance;
  List<KolektorTargetModel> get leaderboard => _leaderboard;
  KolektorTargetModel? get selectedDetail => _selectedDetail;
  int get selectedTahun => _selectedTahun;

  bool get isLoading => _isLoading;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get errorMessage => _errorMessage;

  /// Ubah tahun aktif yang sedang dipantau
  void setSelectedTahun(int tahun) {
    if (_selectedTahun != tahun) {
      _selectedTahun = tahun;
      notifyListeners();
    }
  }

  /// Reset pesan error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset detail kolektor terpilih
  void clearSelectedDetail() {
    _selectedDetail = null;
    notifyListeners();
  }

  /// 1. Fetch performa kolektor yang sedang login (Role: KOLEKTOR)
  /// GET /api/v1/kolektor-targets/my-performance?tahun=
  Future<void> fetchMyPerformance(int tahun) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        ApiConstants.kolektorMyPerformanceEndpoint,
        queryParams: {'tahun': tahun.toString()},
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> dataMap =
            response.data is Map<String, dynamic> ? response.data : {};
        _myPerformance = KolektorTargetModel.fromJson(dataMap);
      } else {
        // Jika belum ada target ditetapkan atau response.data == null
        _myPerformance = null;
        if (!response.success) {
          _errorMessage = response.message;
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat performa kolektor: ${e.toString()}';
      _myPerformance = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 2. Fetch ranking leaderboard seluruh kolektor (Role: KEPALA_DESA, SUPER_ADMIN, KOLEKTOR)
  /// GET /api/v1/kolektor-targets/leaderboard?tahun=&desa_id=
  Future<void> fetchLeaderboard(int tahun, {int? desaId}) async {
    _isLoadingLeaderboard = true;
    _errorMessage = null;
    notifyListeners();

    final Map<String, String> queryParams = {'tahun': tahun.toString()};
    if (desaId != null) {
      queryParams['desa_id'] = desaId.toString();
    }

    try {
      final response = await ApiService.get(
        ApiConstants.kolektorLeaderboardEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final List<dynamic> rawList = response.data is List
            ? response.data as List<dynamic>
            : (response.data is Map && response.data['data'] is List)
                ? response.data['data'] as List<dynamic>
                : [];

        _leaderboard = rawList
            .map((e) => KolektorTargetModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _leaderboard = [];
        if (!response.success) {
          _errorMessage = response.message;
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat leaderboard kolektor: ${e.toString()}';
      _leaderboard = [];
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  /// 3. Fetch detail performa spesifik kolektor (beserta trend harian & mingguan)
  /// GET /api/v1/kolektor-targets/{id}?tahun=
  Future<void> fetchKolektorDetail(int kolektorId, int tahun) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '${ApiConstants.kolektorTargetsEndpoint}/$kolektorId',
        queryParams: {'tahun': tahun.toString()},
      );

      if (response.success && response.data != null) {
        final Map<String, dynamic> dataMap =
            response.data is Map<String, dynamic> ? response.data : {};
        _selectedDetail = KolektorTargetModel.fromJson(dataMap);
      } else {
        _selectedDetail = null;
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat detail performa kolektor: ${e.toString()}';
      _selectedDetail = null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }
}
