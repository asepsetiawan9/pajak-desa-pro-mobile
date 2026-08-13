class SettingsModel {
  final String namaDesa;
  final String namaKecamatan;
  final String namaKabupaten;
  final String namaKades;
  final String jabatanKades;
  final String namaPetugas;
  final String jabatanPetugas;
  final bool enableFeeKolektorLuarDesa;
  final double feeKolektorLuarDesa;

  SettingsModel({
    required this.namaDesa,
    required this.namaKecamatan,
    required this.namaKabupaten,
    required this.namaKades,
    required this.jabatanKades,
    required this.namaPetugas,
    required this.jabatanPetugas,
    required this.enableFeeKolektorLuarDesa,
    required this.feeKolektorLuarDesa,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val == 1;
      final s = val.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }

    return SettingsModel(
      namaDesa: json['nama_desa']?.toString() ?? json['namaDesa']?.toString() ?? 'Desa',
      namaKecamatan: json['nama_kecamatan']?.toString() ?? json['namaKecamatan']?.toString() ?? 'Kecamatan',
      namaKabupaten: json['nama_kabupaten']?.toString() ?? json['namaKabupaten']?.toString() ?? 'Kabupaten',
      namaKades: json['nama_kades']?.toString() ?? json['namaKades']?.toString() ?? 'Kepala Desa',
      jabatanKades: json['jabatan_kades']?.toString() ?? json['jabatanKades']?.toString() ?? 'Kepala Desa',
      namaPetugas: json['nama_petugas']?.toString() ?? json['namaPetugas']?.toString() ?? 'Bendahara / Kolektor',
      jabatanPetugas: json['jabatan_petugas']?.toString() ?? json['jabatanPetugas']?.toString() ?? 'Bendahara PBB-P2',
      enableFeeKolektorLuarDesa: parseBool(json['enable_fee_kolektor_luar_desa'] ?? json['enableFeeKolektorLuarDesa']),
      feeKolektorLuarDesa: parseDouble(json['fee_kolektor_luar_desa'] ?? json['feeKolektorLuarDesa']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_desa': namaDesa,
      'nama_kecamatan': namaKecamatan,
      'nama_kabupaten': namaKabupaten,
      'nama_kades': namaKades,
      'jabatan_kades': jabatanKades,
      'nama_petugas': namaPetugas,
      'jabatan_petugas': jabatanPetugas,
      'enable_fee_kolektor_luar_desa': enableFeeKolektorLuarDesa,
      'fee_kolektor_luar_desa': feeKolektorLuarDesa,
    };
  }

  factory SettingsModel.defaultSettings() {
    return SettingsModel(
      namaDesa: 'Desa',
      namaKecamatan: 'Kecamatan',
      namaKabupaten: 'Kabupaten',
      namaKades: 'Kepala Desa',
      jabatanKades: 'Kepala Desa',
      namaPetugas: 'Bendahara / Kolektor',
      jabatanPetugas: 'Bendahara PBB-P2',
      enableFeeKolektorLuarDesa: false,
      feeKolektorLuarDesa: 0.0,
    );
  }
}
