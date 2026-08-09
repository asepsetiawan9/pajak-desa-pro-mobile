import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/dhkp_model.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> submitPayment({
    required DhkpModel item,
    required double denda,
    required double totalBayar,
    required String metodePembayaran,
    String? catatan,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final body = {
      'dhkp_id': item.id,
      'dhkp_ids': [item.id],
      'nop': item.nop,
      'nops': [item.nop],
      'nama_wp': item.namaWp,
      'dusun': item.dusun,
      'pbb_terutang': item.pbbTerutang,
      'denda': denda,
      'total_bayar': totalBayar,
      'metode_pembayaran': metodePembayaran,
      'catatan': catatan ?? 'Pembayaran via Mobile App',
    };

    final response = await ApiService.post(
      ApiConstants.transactionsEndpoint,
      body: body,
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

  Future<bool> submitMultiPayment({
    required List<DhkpModel> items,
    required double totalDenda,
    required double totalBayar,
    required String metodePembayaran,
    double? uangDibayar,
    double? kembalian,
    String? catatan,
  }) async {
    if (items.isEmpty) {
      _errorMessage = 'Pilih minimal 1 NOP untuk dibayar.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final nops = items.map((e) => e.nop).toList();
    final dhkpIds = items.map((e) => e.id).where((id) => id > 0).toList();
    final body = {
      'nops': nops,
      'dhkp_ids': dhkpIds,
      'metode_pembayaran': metodePembayaran,
      'catatan': catatan ?? 'Pembayaran Multi-NOP Mobile',
      'metadata_kk': {
        'uang_dibayar': uangDibayar,
        'kembalian': kembalian,
        'jumlah_nop': items.length,
        'wp_names': items.map((e) => e.namaWp).toSet().toList(),
      },
    };

    final response = await ApiService.post(
      ApiConstants.transactionsEndpoint,
      body: body,
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
}
