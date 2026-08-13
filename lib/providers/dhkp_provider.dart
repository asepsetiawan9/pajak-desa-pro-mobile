import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/dhkp_model.dart';
import '../models/user_model.dart';

class DhkpProvider extends ChangeNotifier {
  List<DhkpModel> _allRows = [];
  List<DhkpModel> _filteredRows = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasFetched = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  final int _perPage = 20;

  String _searchQuery = '';
  String _selectedDesaId = 'ALL';
  String _selectedDusun = 'ALL';
  String _selectedStatus = 'ALL'; // 'ALL', 'terbayar', 'belum_bayar'
  String _selectedDomisili = 'ALL'; // 'ALL', 'DALAM_DESA', 'LUAR_DESA'
  String _sortBy =
      'default'; // 'default', 'nama_asc', 'nama_desc', 'nominal_desc', 'nominal_asc'

  Timer? _debounceTimer;

  List<DhkpModel> get allRows => _allRows;
  List<DhkpModel> get items => _allRows;
  List<DhkpModel> get filteredRows => _filteredRows;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get hasFetched => _hasFetched;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;

  String get searchQuery => _searchQuery;
  String get selectedDesaId => _selectedDesaId;
  String get selectedDusun => _selectedDusun;
  String get selectedStatus => _selectedStatus;
  String get selectedDomisili => _selectedDomisili;
  String get sortBy => _sortBy;

  int get activeFilterCount {
    int count = 0;
    if (_searchQuery.trim().isNotEmpty) count++;
    if (_selectedDesaId.trim().toUpperCase() != 'ALL') count++;
    if (_selectedDusun.trim().toUpperCase() != 'ALL') count++;
    if (_selectedStatus.trim().toUpperCase() != 'ALL') count++;
    if (_selectedDomisili.trim().toUpperCase() != 'ALL') count++;
    if (_sortBy != 'default') count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  Future<void> fetchDhkp({
    bool isRefresh = false,
    UserModel? currentUser,
  }) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _allRows = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadPageData(page: 1, currentUser: currentUser);
    } catch (e) {
      _errorMessage = 'Gagal memuat data DHKP: ${e.toString()}';
    } finally {
      _isLoading = false;
      _hasFetched = true;
      notifyListeners();
    }
  }

  Future<void> fetchNextPage({UserModel? currentUser}) async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    try {
      await _loadPageData(page: nextPage, currentUser: currentUser);
    } catch (e) {
      _errorMessage = 'Gagal memuat halaman berikutnya: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _loadPageData({
    required int page,
    UserModel? currentUser,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': _perPage.toString(),
    };

    if (_searchQuery.trim().isNotEmpty) {
      queryParams['search'] = _searchQuery.trim();
    }

    if (_selectedDesaId.trim().toUpperCase() != 'ALL') {
      queryParams['desa_id'] = _selectedDesaId.trim();
    }

    if (_selectedDusun.trim().toUpperCase() != 'ALL') {
      queryParams['dusun'] = _selectedDusun.trim();
    }

    if (_selectedStatus.trim().toUpperCase() != 'ALL') {
      final statusUpper = _selectedStatus.trim().toUpperCase();
      if (statusUpper == 'TERBAYAR' || statusUpper == 'LUNAS') {
        queryParams['status_bayar'] = 'LUNAS';
      } else if (statusUpper == 'BELUM_BAYAR' || statusUpper == 'BELUM BAYAR') {
        queryParams['status_bayar'] = 'BELUM_BAYAR';
      } else {
        queryParams['status_bayar'] = statusUpper;
      }
    }

    if (_selectedDomisili.trim().toUpperCase() != 'ALL') {
      queryParams['domisili'] = _selectedDomisili.trim().toUpperCase();
    }

    final response = await ApiService.get(
      ApiConstants.dhkpEndpoint,
      queryParams: queryParams,
    );

    if (response.success && response.data != null) {
      try {
        List<dynamic> rawList = [];
        Map<String, dynamic>? metaData;

        if (response.data is List) {
          rawList = response.data as List;
        } else if (response.data is Map) {
          final mapData = response.data as Map<String, dynamic>;
          if (mapData['data'] is List) {
            rawList = mapData['data'] as List;
          }
          if (mapData['meta'] is Map) {
            metaData = Map<String, dynamic>.from(mapData['meta']);
          }
        }

        final List<DhkpModel> parsedRows = rawList
            .map((item) {
              if (item is Map<String, dynamic>) {
                return DhkpModel.fromJson(item);
              } else if (item is Map) {
                return DhkpModel.fromJson(Map<String, dynamic>.from(item));
              }
              return null;
            })
            .whereType<DhkpModel>()
            .toList();

        if (metaData != null) {
          _currentPage = metaData['current_page'] ?? page;
          _lastPage = metaData['last_page'] ?? 1;
          _totalRows = metaData['total'] ?? parsedRows.length;
          _hasMore = _currentPage < _lastPage;
        } else {
          _currentPage = page;
          _hasMore = parsedRows.length >= _perPage;
        }

        if (page == 1) {
          _allRows = parsedRows;
        } else {
          _allRows.addAll(parsedRows);
        }

        _applyFilters(currentUser);
      } catch (e) {
        _errorMessage = 'Gagal membaca data DHKP: ${e.toString()}';
      }
    } else {
      _errorMessage = response.message;
    }
  }

  void setSearchQuery(String query, {UserModel? currentUser}) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchDhkp(isRefresh: true, currentUser: currentUser);
    });
  }

  void setSelectedDesaId(String desaId, {UserModel? currentUser}) {
    if (_selectedDesaId != desaId) {
      _selectedDesaId = desaId;
      fetchDhkp(isRefresh: true, currentUser: currentUser);
    }
  }

  void setSelectedDusun(String dusun, {UserModel? currentUser}) {
    if (_selectedDusun != dusun) {
      _selectedDusun = dusun;
      fetchDhkp(isRefresh: true, currentUser: currentUser);
    }
  }

  void setSelectedStatus(String status, {UserModel? currentUser}) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      fetchDhkp(isRefresh: true, currentUser: currentUser);
    }
  }

  void setSelectedDomisili(String domisili, {UserModel? currentUser}) {
    if (_selectedDomisili != domisili) {
      _selectedDomisili = domisili;
      fetchDhkp(isRefresh: true, currentUser: currentUser);
    }
  }

  void setSortBy(String sortOption, {UserModel? currentUser}) {
    if (_sortBy != sortOption) {
      _sortBy = sortOption;
      _applyFilters(currentUser);
      notifyListeners();
    }
  }

  void resetFilters({UserModel? currentUser}) {
    _searchQuery = '';
    _selectedDesaId = 'ALL';
    _selectedDusun = 'ALL';
    _selectedStatus = 'ALL';
    _selectedDomisili = 'ALL';
    _sortBy = 'default';
    fetchDhkp(isRefresh: true, currentUser: currentUser);
  }

  void _applyFilters(UserModel? currentUser) {
    List<DhkpModel> temp = List.from(_allRows);

    // 1. Collector Dusun Access Scope Client-side safeguard
    if (currentUser != null && currentUser.isKolektor) {
      final allowedDusuns = currentUser.allowedDusuns
          .map((d) => d.trim().toLowerCase())
          .where((d) => d.isNotEmpty && d != 'all' && d != '*')
          .toList();

      if (allowedDusuns.isNotEmpty) {
        temp = temp.where((row) {
          final rowDusun = row.dusun.trim().toLowerCase();
          return allowedDusuns.any((d) => d == rowDusun);
        }).toList();
      }
    }

    // 2. Status Filter Client-side safeguard
    final statusUpper = _selectedStatus.trim().toUpperCase();
    if (statusUpper == 'TERBAYAR' || statusUpper == 'LUNAS') {
      temp = temp.where((row) => row.isTerbayar).toList();
    } else if (statusUpper == 'BELUM_BAYAR' || statusUpper == 'BELUM BAYAR') {
      temp = temp.where((row) => !row.isTerbayar).toList();
    }

    // 3. Domisili Filter Client-side safeguard
    final domisiliUpper = _selectedDomisili.trim().toUpperCase();
    if (domisiliUpper == 'DALAM_DESA') {
      temp = temp.where((row) => !row.isLuarDesa).toList();
    } else if (domisiliUpper == 'LUAR_DESA') {
      temp = temp.where((row) => row.isLuarDesa).toList();
    }

    // 4. Client-side Sorting
    if (_sortBy == 'nama_asc') {
      temp.sort(
        (a, b) => a.namaWp.toLowerCase().compareTo(b.namaWp.toLowerCase()),
      );
    } else if (_sortBy == 'nama_desc') {
      temp.sort(
        (a, b) => b.namaWp.toLowerCase().compareTo(a.namaWp.toLowerCase()),
      );
    } else if (_sortBy == 'nominal_desc') {
      temp.sort((a, b) => b.pbbTerutang.compareTo(a.pbbTerutang));
    } else if (_sortBy == 'nominal_asc') {
      temp.sort((a, b) => a.pbbTerutang.compareTo(b.pbbTerutang));
    }

    _filteredRows = temp;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
