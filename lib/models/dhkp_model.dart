class DhkpModel {
  final int id;
  final String nop;
  final String namaWp;
  final String? alamatWp;
  final String dusun;
  final String? rw;
  final String? rt;
  final double luasBumi;
  final double luasBgn;
  final double pbbTerutang;
  final String statusBayar; // 'terbayar' | 'belum_bayar'
  final double denda;
  final double totalBayar;
  final String? tglBayar;
  final String? kolektorNama;

  DhkpModel({
    required this.id,
    required this.nop,
    required this.namaWp,
    this.alamatWp,
    required this.dusun,
    this.rw,
    this.rt,
    required this.luasBumi,
    required this.luasBgn,
    required this.pbbTerutang,
    required this.statusBayar,
    required this.denda,
    required this.totalBayar,
    this.tglBayar,
    this.kolektorNama,
  });

  bool get isTerbayar {
    final s = statusBayar.toUpperCase();
    return s == 'LUNAS' || s == 'TERBAYAR';
  }
  bool get isLunas => isTerbayar;

  factory DhkpModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    String status = (json['status_bayar'] ?? (json['status'] == 1 ? 'LUNAS' : 'BELUM_BAYAR')).toString().toUpperCase();
    if (status == 'TERBAYAR') status = 'LUNAS';

    String? rtVal;
    String? rwVal;
    if (json['rt'] != null) rtVal = json['rt'].toString();
    if (json['rw'] != null) rwVal = json['rw'].toString();

    if ((rtVal == null || rwVal == null) && json['rt_rw'] != null) {
      final parts = json['rt_rw'].toString().split('/');
      if (parts.length >= 2) {
        rtVal ??= parts[0].trim();
        rwVal ??= parts[1].trim();
      } else if (parts.isNotEmpty) {
        rtVal ??= parts[0].trim();
      }
    }

    String? collectorName;
    if (json['kolektor_nama'] != null) {
      collectorName = json['kolektor_nama'].toString();
    } else if (json['kolektor'] != null) {
      if (json['kolektor'] is Map) {
        collectorName = (json['kolektor'] as Map)['name']?.toString();
      } else if (json['kolektor'] is String) {
        collectorName = json['kolektor'].toString();
      }
    }

    return DhkpModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nop: json['nop']?.toString() ?? '',
      namaWp: json['nama_wp']?.toString() ?? json['nama']?.toString() ?? 'Tanpa Nama',
      alamatWp: json['alamat_wp']?.toString() ?? json['alamat']?.toString(),
      dusun: json['dusun']?.toString() ?? '',
      rw: rwVal,
      rt: rtVal,
      luasBumi: parseDouble(json['luas_bumi']),
      luasBgn: parseDouble(json['luas_bangunan'] ?? json['luas_bgn']),
      pbbTerutang: parseDouble(json['ketetapan_pbb'] ?? json['pbb_terutang'] ?? json['pbb']),
      statusBayar: status,
      denda: parseDouble(json['denda']),
      totalBayar: parseDouble(json['total_bayar'] ?? json['total']),
      tglBayar: json['tanggal_bayar']?.toString() ?? json['tgl_bayar']?.toString(),
      kolektorNama: collectorName,
    );
  }
}
