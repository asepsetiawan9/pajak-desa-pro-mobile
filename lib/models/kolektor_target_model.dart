/// Model untuk data Target & Performa Kolektor dari API backend
class KolektorTargetModel {
  final int id;
  final int kolektorId;
  final String kolektorName;
  final String kolektorUsername;
  final dynamic dusunAkses;
  final int? desaId;
  final String? namaDesa;
  final int tahun;
  final int targetNominal;
  final int targetSppt;
  final int realisasiNominal;
  final int realisasiSppt;
  final int sisaNominal;
  final int sisaSppt;
  final double persentaseNominal;
  final double persentaseSppt;
  final int totalFee;
  final String badge;
  final String status;
  final int? rank;
  final String? catatan;
  final List<TrendItem>? trendHarian;
  final List<TrendMingguanItem>? trendMingguan;

  KolektorTargetModel({
    required this.id,
    required this.kolektorId,
    required this.kolektorName,
    required this.kolektorUsername,
    this.dusunAkses,
    this.desaId,
    this.namaDesa,
    required this.tahun,
    required this.targetNominal,
    required this.targetSppt,
    required this.realisasiNominal,
    required this.realisasiSppt,
    required this.sisaNominal,
    required this.sisaSppt,
    required this.persentaseNominal,
    required this.persentaseSppt,
    required this.totalFee,
    required this.badge,
    required this.status,
    this.rank,
    this.catatan,
    this.trendHarian,
    this.trendMingguan,
  });

  factory KolektorTargetModel.fromJson(Map<String, dynamic> json) {
    double parseD(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseI(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    List<TrendItem>? harian;
    if (json['trend_harian'] is List) {
      harian = (json['trend_harian'] as List)
          .map((e) => TrendItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<TrendMingguanItem>? mingguan;
    if (json['trend_mingguan'] is List) {
      mingguan = (json['trend_mingguan'] as List)
          .map((e) => TrendMingguanItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return KolektorTargetModel(
      id: parseI(json['id']),
      kolektorId: parseI(json['kolektor_id']),
      kolektorName: json['kolektor_name'] ?? 'Unknown',
      kolektorUsername: json['kolektor_username'] ?? '',
      dusunAkses: json['dusun_akses'],
      desaId: json['desa_id'] != null ? parseI(json['desa_id']) : null,
      namaDesa: json['nama_desa'],
      tahun: parseI(json['tahun']),
      targetNominal: parseI(json['target_nominal']),
      targetSppt: parseI(json['target_sppt']),
      realisasiNominal: parseI(json['realisasi_nominal']),
      realisasiSppt: parseI(json['realisasi_sppt']),
      sisaNominal: parseI(json['sisa_nominal']),
      sisaSppt: parseI(json['sisa_sppt']),
      persentaseNominal: parseD(json['persentase_nominal']),
      persentaseSppt: parseD(json['persentase_sppt']),
      totalFee: parseI(json['total_fee']),
      badge: json['badge'] ?? 'NONE',
      status: json['status'] ?? 'CRITICAL',
      rank: json['rank'] != null ? parseI(json['rank']) : null,
      catatan: json['catatan'],
      trendHarian: harian,
      trendMingguan: mingguan,
    );
  }

  /// Badge display info
  String get badgeEmoji {
    switch (badge) {
      case 'LEGEND': return '🔥';
      case 'GOLD': return '🥇';
      case 'SILVER': return '🥈';
      case 'BRONZE': return '🥉';
      default: return '⭐';
    }
  }

  String get badgeLabel {
    switch (badge) {
      case 'LEGEND': return 'Legend';
      case 'GOLD': return 'Gold';
      case 'SILVER': return 'Silver';
      case 'BRONZE': return 'Bronze';
      default: return 'Pemula';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'EXCEEDED': return 'Melebihi Target 🔥';
      case 'ON_TRACK': return 'Sesuai Target ✅';
      case 'MODERATE': return 'Cukup Baik 📊';
      case 'BEHIND': return 'Perlu Peningkatan ⚠️';
      case 'CRITICAL': return 'Kritis ❗';
      default: return status;
    }
  }
}

class TrendItem {
  final String tanggal;
  final int nominal;
  final int jumlahSppt;

  TrendItem({
    required this.tanggal,
    required this.nominal,
    required this.jumlahSppt,
  });

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      tanggal: json['tanggal'] ?? '',
      nominal: json['nominal'] is int
          ? json['nominal']
          : int.tryParse(json['nominal'].toString()) ?? 0,
      jumlahSppt: json['jumlah_sppt'] is int
          ? json['jumlah_sppt']
          : int.tryParse(json['jumlah_sppt'].toString()) ?? 0,
    );
  }
}

class TrendMingguanItem {
  final String minggu;
  final String mulai;
  final String selesai;
  final int nominal;
  final int jumlahSppt;

  TrendMingguanItem({
    required this.minggu,
    required this.mulai,
    required this.selesai,
    required this.nominal,
    required this.jumlahSppt,
  });

  factory TrendMingguanItem.fromJson(Map<String, dynamic> json) {
    return TrendMingguanItem(
      minggu: json['minggu']?.toString() ?? '',
      mulai: json['mulai'] ?? '',
      selesai: json['selesai'] ?? '',
      nominal: json['nominal'] is int
          ? json['nominal']
          : int.tryParse(json['nominal'].toString()) ?? 0,
      jumlahSppt: json['jumlah_sppt'] is int
          ? json['jumlah_sppt']
          : int.tryParse(json['jumlah_sppt'].toString()) ?? 0,
    );
  }
}
