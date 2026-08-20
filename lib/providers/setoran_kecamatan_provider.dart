import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';

/// Model untuk data setoran / pengeluaran kas desa individual
class SetoranItem {
  final int id;
  final int? desaId;
  final String? namaDesa;
  final String kategori; // 'SETOR_KECAMATAN', 'KEGIATAN_DESA', 'OPERASIONAL_DESA', 'ADMINISTRASI', 'LAINNYA'
  final bool perluVerifikasiKecamatan;
  final double nominal;
  final String? tanggalSetor;
  final String? nomorBukti;
  final String? metodePembayaran;
  final String? namaBank;
  final String? namaPenyetor;
  final String? status; // 'PENDING', 'DITERIMA', 'DITOLAK'
  final String? keterangan;
  final String? keteranganVerifikasi;
  final String? tanggalVerifikasi;

  SetoranItem({
    required this.id,
    this.desaId,
    this.namaDesa,
    this.kategori = 'SETOR_KECAMATAN',
    this.perluVerifikasiKecamatan = true,
    required this.nominal,
    this.tanggalSetor,
    this.nomorBukti,
    this.metodePembayaran,
    this.namaBank,
    this.namaPenyetor,
    this.status,
    this.keterangan,
    this.keteranganVerifikasi,
    this.tanggalVerifikasi,
  });

  factory SetoranItem.fromJson(Map<String, dynamic> json) {
    return SetoranItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      desaId: json['desa_id'] != null ? (json['desa_id'] is int ? json['desa_id'] : int.tryParse(json['desa_id'].toString())) : null,
      namaDesa: json['desa']?['nama_desa'] ?? json['nama_desa'],
      kategori: json['kategori']?.toString() ?? 'SETOR_KECAMATAN',
      perluVerifikasiKecamatan: json['perlu_verifikasi_kecamatan'] == true || json['perlu_verifikasi_kecamatan'] == 1 || json['kategori'] == 'SETOR_KECAMATAN',
      nominal: (json['nominal'] is num ? json['nominal'] : num.tryParse(json['nominal']?.toString() ?? '0') ?? 0).toDouble(),
      tanggalSetor: json['tanggal_setor']?.toString(),
      nomorBukti: json['nomor_bukti']?.toString(),
      metodePembayaran: json['metode_setoran']?.toString() ?? json['metode_pembayaran']?.toString(),
      namaBank: json['bank_tujuan']?.toString() ?? json['nama_bank']?.toString(),
      namaPenyetor: json['penyetor_nama']?.toString() ?? json['nama_penyetor']?.toString(),
      status: json['status']?.toString(),
      keterangan: json['catatan_desa']?.toString() ?? json['keterangan']?.toString(),
      keteranganVerifikasi: json['catatan_kecamatan']?.toString() ?? json['keterangan_verifikasi']?.toString(),
      tanggalVerifikasi: json['tanggal_diterima']?.toString() ?? json['tanggal_verifikasi']?.toString(),
    );
  }

  bool get isPending => status?.toUpperCase() == 'PENDING';
  bool get isDiterima => status?.toUpperCase() == 'DITERIMA';
  bool get isDitolak => status?.toUpperCase() == 'DITOLAK';
  bool get isSetorKecamatan => kategori == 'SETOR_KECAMATAN';
}

/// Model untuk rekap setoran per desa (summary)
class SetoranDesaSummary {
  final int desaId;
  final String namaDesa;
  final double targetPbb;
  final double realisasiPbb;
  final double totalDisetor;
  final double totalPengeluaranInternal;
  final double sisaKasDesa;
  final double persentaseDisetor;

  SetoranDesaSummary({
    required this.desaId,
    required this.namaDesa,
    required this.targetPbb,
    required this.realisasiPbb,
    required this.totalDisetor,
    required this.totalPengeluaranInternal,
    required this.sisaKasDesa,
    required this.persentaseDisetor,
  });

  factory SetoranDesaSummary.fromJson(Map<String, dynamic> json) {
    return SetoranDesaSummary(
      desaId: json['desa_id'] is int ? json['desa_id'] : int.tryParse(json['desa_id']?.toString() ?? '0') ?? 0,
      namaDesa: json['nama_desa']?.toString() ?? 'Desa',
      targetPbb: (json['target_pbb'] is num ? json['target_pbb'] : num.tryParse(json['target_pbb']?.toString() ?? '0') ?? 0).toDouble(),
      realisasiPbb: (json['realisasi_pbb'] is num ? json['realisasi_pbb'] : num.tryParse(json['realisasi_pbb']?.toString() ?? '0') ?? 0).toDouble(),
      totalDisetor: (json['total_disetor_diterima'] is num ? json['total_disetor_diterima'] : num.tryParse(json['total_disetor_diterima']?.toString() ?? '0') ?? 0).toDouble(),
      totalPengeluaranInternal: (json['total_pengeluaran_internal'] is num ? json['total_pengeluaran_internal'] : num.tryParse(json['total_pengeluaran_internal']?.toString() ?? '0') ?? 0).toDouble(),
      sisaKasDesa: (json['sisa_kas_desa'] is num ? json['sisa_kas_desa'] : num.tryParse(json['sisa_kas_desa']?.toString() ?? '0') ?? 0).toDouble(),
      persentaseDisetor: (json['persentase_disetor'] is num ? json['persentase_disetor'] : num.tryParse(json['persentase_disetor']?.toString() ?? '0') ?? 0).toDouble(),
    );
  }
}

/// Provider untuk mengelola data setoran ke kecamatan & pengeluaran kas desa.
class SetoranKecamatanProvider extends ChangeNotifier {
  List<SetoranItem> _setoranList = [];
  List<SetoranDesaSummary> _rekapPerDesa = [];
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // KPI Aggregates
  double _totalDiterima = 0;
  double _totalPengeluaranInternal = 0;
  double _totalPending = 0;
  double _totalSisaKas = 0;
  double _totalRealisasiDesa = 0;

  List<SetoranItem> get setoranList => _setoranList;
  List<SetoranDesaSummary> get rekapPerDesa => _rekapPerDesa;
  bool get isLoading => _isLoading;
  bool get isVerifying => _isVerifying;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  double get totalDiterima => _totalDiterima;
  double get totalPengeluaranInternal => _totalPengeluaranInternal;
  double get totalPending => _totalPending;
  double get totalSisaKas => _totalSisaKas;
  double get totalRealisasiDesa => _totalRealisasiDesa;

  /// Fetch summary KPI setoran kecamatan & pengeluaran kas desa
  Future<void> fetchSummary({String? desaId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String endpoint = ApiConstants.setoranKecamatanSummaryEndpoint;
    if (desaId != null && desaId != 'all') {
      endpoint += '?desa_id=$desaId';
    }

    final response = await ApiService.get(endpoint);

    if (response.success && response.data != null) {
      try {
        final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {};

        // Parse KPI
        _totalDiterima = (data['total_diterima'] is num ? data['total_diterima'] : num.tryParse(data['total_diterima']?.toString() ?? '0') ?? 0).toDouble();
        _totalPengeluaranInternal = (data['total_pengeluaran_internal'] is num ? data['total_pengeluaran_internal'] : num.tryParse(data['total_pengeluaran_internal']?.toString() ?? '0') ?? 0).toDouble();
        _totalPending = (data['total_pending'] is num ? data['total_pending'] : num.tryParse(data['total_pending']?.toString() ?? '0') ?? 0).toDouble();
        _totalSisaKas = (data['sisa_kas_desa'] is num ? data['sisa_kas_desa'] : num.tryParse(data['sisa_kas_desa']?.toString() ?? '0') ?? 0).toDouble();
        _totalRealisasiDesa = (data['total_realisasi_desa'] is num ? data['total_realisasi_desa'] : num.tryParse(data['total_realisasi_desa']?.toString() ?? '0') ?? 0).toDouble();

        // Parse rekap per desa
        final rekapList = data['rekap_per_desa'];
        if (rekapList is List) {
          _rekapPerDesa = rekapList
              .map((e) => SetoranDesaSummary.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        _errorMessage = 'Gagal memproses data setoran: ${e.toString()}';
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch list setoran
  Future<void> fetchSetoranList({String? desaId, String? kategori}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String endpoint = ApiConstants.setoranKecamatanEndpoint;
    final queryParts = <String>[];
    if (desaId != null && desaId != 'all') {
      queryParts.add('desa_id=$desaId');
    }
    if (kategori != null && kategori != 'ALL' && kategori != 'all') {
      queryParts.add('kategori=$kategori');
    }
    queryParts.add('limit=100');
    if (queryParts.isNotEmpty) {
      endpoint += '?${queryParts.join('&')}';
    }

    final response = await ApiService.get(endpoint);

    if (response.success && response.data != null) {
      try {
        final List<dynamic> rawList = response.data is List
            ? response.data as List<dynamic>
            : (response.data is Map && response.data['data'] != null)
                ? response.data['data'] as List<dynamic>
                : [];

        _setoranList = rawList
            .map((e) => SetoranItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _errorMessage = 'Gagal memproses data setoran: ${e.toString()}';
      }
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Verifikasi setoran (approve/reject)
  Future<bool> verifySetoran({
    required int setoranId,
    required String status,
    String? keterangan,
  }) async {
    _isVerifying = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.post(
      '${ApiConstants.setoranKecamatanEndpoint}/$setoranId/verify',
      body: {
        'status': status,
        'catatan_kecamatan': keterangan ?? '',
      },
    );

    _isVerifying = false;

    if (response.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Membikin pengeluaran / setoran kas baru
  Future<bool> createSetoran({
    required String tanggalSetor,
    String kategori = 'SETOR_KECAMATAN',
    required double nominal,
    required String metodeSetoran,
    String? bankTujuan,
    String? nomorReferensi,
    required String penyetorNama,
    String? penyetorJabatan,
    String? catatanDesa,
    int? desaId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final bodyData = <String, dynamic>{
      'tanggal_setor': tanggalSetor,
      'kategori': kategori,
      'nominal': nominal,
      'metode_setoran': metodeSetoran,
      'penyetor_nama': penyetorNama,
    };

    if (bankTujuan != null && bankTujuan.isNotEmpty) bodyData['bank_tujuan'] = bankTujuan;
    if (nomorReferensi != null && nomorReferensi.isNotEmpty) bodyData['nomor_referensi'] = nomorReferensi;
    if (penyetorJabatan != null && penyetorJabatan.isNotEmpty) bodyData['penyetor_jabatan'] = penyetorJabatan;
    if (catatanDesa != null && catatanDesa.isNotEmpty) bodyData['catatan_desa'] = catatanDesa;
    if (desaId != null) bodyData['desa_id'] = desaId;

    final response = await ApiService.post(
      ApiConstants.setoranKecamatanEndpoint,
      body: bodyData,
    );

    _isSubmitting = false;

    if (response.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui pengeluaran / setoran kas yang sudah ada (mode edit)
  Future<bool> updateSetoran({
    required int id,
    required String tanggalSetor,
    String kategori = 'SETOR_KECAMATAN',
    required double nominal,
    required String metodeSetoran,
    String? bankTujuan,
    String? nomorReferensi,
    required String penyetorNama,
    String? penyetorJabatan,
    String? catatanDesa,
    int? desaId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final bodyData = <String, dynamic>{
      'tanggal_setor': tanggalSetor,
      'kategori': kategori,
      'nominal': nominal,
      'metode_setoran': metodeSetoran,
      'penyetor_nama': penyetorNama,
    };

    if (bankTujuan != null && bankTujuan.isNotEmpty) bodyData['bank_tujuan'] = bankTujuan;
    if (nomorReferensi != null && nomorReferensi.isNotEmpty) bodyData['nomor_referensi'] = nomorReferensi;
    if (penyetorJabatan != null && penyetorJabatan.isNotEmpty) bodyData['penyetor_jabatan'] = penyetorJabatan;
    if (catatanDesa != null && catatanDesa.isNotEmpty) bodyData['catatan_desa'] = catatanDesa;
    if (desaId != null) bodyData['desa_id'] = desaId;

    final response = await ApiService.put(
      '${ApiConstants.setoranKecamatanEndpoint}/$id',
      body: bodyData,
    );

    _isSubmitting = false;

    if (response.success) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Menghapus catatan setoran / pengeluaran kas
  Future<bool> deleteSetoran(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await ApiService.delete(
      '${ApiConstants.setoranKecamatanEndpoint}/$id',
    );

    _isLoading = false;

    if (response.success) {
      _setoranList.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }
}
