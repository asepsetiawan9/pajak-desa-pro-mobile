class TransactionItemModel {
  final int id;
  final String kodeTransaksi;
  final String nop;
  final String namaWp;
  final String dusun;
  final double amount;
  final double denda;
  final double pokok;
  final String metode;
  final String createdAt;
  final String status;
  final String? operatorName;

  TransactionItemModel({
    required this.id,
    required this.kodeTransaksi,
    required this.nop,
    required this.namaWp,
    required this.dusun,
    required this.amount,
    this.denda = 0,
    this.pokok = 0,
    required this.metode,
    required this.createdAt,
    required this.status,
    this.operatorName,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    String opName = 'Kolektor Lapangan';
    if (json['operator'] != null && json['operator'] is Map) {
      opName = json['operator']['name'] ?? opName;
    } else if (json['operator_name'] != null) {
      opName = json['operator_name'].toString();
    }

    String nopVal = json['nop']?.toString() ?? '-';
    String namaWpVal = json['nama_wp']?.toString() ?? json['wp_nama']?.toString() ?? 'Wajib Pajak';
    String dusunVal = json['dusun']?.toString() ?? '-';

    if (json['dhkp_rows'] is List && (json['dhkp_rows'] as List).isNotEmpty) {
      final firstRow = (json['dhkp_rows'] as List).first;
      if (firstRow is Map) {
        if (nopVal == '-' || nopVal.isEmpty) {
          nopVal = firstRow['nop']?.toString() ?? '-';
        }
        if (namaWpVal == 'Wajib Pajak' || namaWpVal.isEmpty) {
          namaWpVal = firstRow['nama_wp']?.toString() ?? firstRow['namaSppt']?.toString() ?? 'Wajib Pajak';
        }
        if (dusunVal == '-' || dusunVal.isEmpty) {
          dusunVal = firstRow['dusun']?.toString() ?? '-';
        }
      }
    }

    double tot = double.tryParse((json['total_bayar'] ?? json['amount'] ?? json['pbb_terutang'] ?? 0).toString()) ?? 0.0;
    double dnd = double.tryParse((json['denda'] ?? 0).toString()) ?? 0.0;
    double pk = double.tryParse((json['pbb_terutang'] ?? json['total_pokok'] ?? (tot - dnd)).toString()) ?? 0.0;

    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    return TransactionItemModel(
      id: parsedId,
      kodeTransaksi: json['kode_transaksi']?.toString() ?? json['nomor_stts']?.toString() ?? 'STTS-$parsedId',
      nop: nopVal,
      namaWp: namaWpVal,
      dusun: dusunVal,
      amount: tot,
      denda: dnd,
      pokok: pk,
      metode: json['metode_pembayaran']?.toString() ?? json['metode']?.toString() ?? 'Tunai',
      createdAt: json['created_at']?.toString() ?? json['tanggal_transaksi']?.toString() ?? '',
      status: json['status_void'] == true ? 'VOID' : (json['status']?.toString() ?? 'SUCCESS'),
      operatorName: opName,
    );
  }
}
