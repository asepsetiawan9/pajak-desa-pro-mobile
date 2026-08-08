class DusunSummary {
  final String dusun;
  final int totalSppt;
  final double totalPokok;
  final double totalTerbayar;
  final double sisaTerutang;
  final double persentase;

  DusunSummary({
    required this.dusun,
    required this.totalSppt,
    required this.totalPokok,
    required this.totalTerbayar,
    required this.sisaTerutang,
    required this.persentase,
  });

  factory DusunSummary.fromJson(Map<String, dynamic> json) {
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

    return DusunSummary(
      dusun: json['dusun'] ?? json['nama_dusun'] ?? 'Dusun',
      totalSppt: parseI(json['total_sppt']),
      totalPokok: parseD(json['target'] ?? json['total_pokok'] ?? json['target_pbb']),
      totalTerbayar: parseD(json['realisasi'] ?? json['total_terbayar'] ?? json['terbayar'] ?? json['realisasi_pbb']),
      sisaTerutang: parseD(json['sisa_piutang'] ?? json['sisa_terutang'] ?? json['sisa']),
      persentase: parseD(json['persentase'] ?? json['persentase_realisasi'] ?? json['capaian']),
    );
  }
}

class SummaryMetricsModel {
  final int totalSppt;
  final int totalLunasSppt;
  final int totalBelumLunasSppt;
  final double totalPokok;
  final double totalTerbayar;
  final double sisaTerutang;
  final double persentaseCapaian;
  final List<DusunSummary> breakdownDusun;

  SummaryMetricsModel({
    required this.totalSppt,
    required this.totalLunasSppt,
    required this.totalBelumLunasSppt,
    required this.totalPokok,
    required this.totalTerbayar,
    required this.sisaTerutang,
    required this.persentaseCapaian,
    required this.breakdownDusun,
  });

  factory SummaryMetricsModel.fromJson(Map<String, dynamic> json) {
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

    List<DusunSummary> dusunList = [];
    if (json['by_dusun'] is List) {
      dusunList = (json['by_dusun'] as List)
          .map((item) => DusunSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['breakdown_dusun'] is List) {
      dusunList = (json['breakdown_dusun'] as List)
          .map((item) => DusunSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['per_dusun'] is List) {
      dusunList = (json['per_dusun'] as List)
          .map((item) => DusunSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return SummaryMetricsModel(
      totalSppt: parseI(json['total_sppt']),
      totalLunasSppt: parseI(json['sppt_lunas'] ?? json['total_lunas_sppt'] ?? json['lunas']),
      totalBelumLunasSppt: parseI(json['sppt_belum'] ?? json['total_belum_lunas_sppt'] ?? json['belum_lunas']),
      totalPokok: parseD(json['total_ketetapan'] ?? json['total_pokok'] ?? json['target_pbb']),
      totalTerbayar: parseD(json['terbayar'] ?? json['total_terbayar'] ?? json['realisasi_pbb']),
      sisaTerutang: parseD(json['sisa_piutang'] ?? json['sisa_terutang'] ?? json['sisa_pbb']),
      persentaseCapaian: parseD(json['persentase_realisasi'] ?? json['persentase_capaian'] ?? json['persentase']),
      breakdownDusun: dusunList,
    );
  }
}
