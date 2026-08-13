import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/dhkp_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/dhkp_provider.dart';
import '../../providers/auth_provider.dart';

class MultiBayarModal extends StatefulWidget {
  final List<DhkpModel> selectedItems;

  const MultiBayarModal({super.key, required this.selectedItems});

  @override
  State<MultiBayarModal> createState() => _MultiBayarModalState();
}

class _MultiBayarModalState extends State<MultiBayarModal> {
  final _formKey = GlobalKey<FormState>();
  final _dendaController = TextEditingController(text: '0');
  final _catatanController = TextEditingController();
  final _uangDibayarController = TextEditingController();

  String _metodePembayaran = 'TUNAI';
  double _dendaVal = 0;
  double _uangDibayarVal = 0;

  double get _totalPokok => widget.selectedItems.fold(0.0, (sum, item) => sum + item.pbbTerutang);
  double get _totalFee => widget.selectedItems.fold(0.0, (sum, item) => sum + (item.feeKolektor > 0 ? item.feeKolektor : (item.isLuarDesa ? 5000.0 : 0.0)));
  double get _totalBayar => _totalPokok + _dendaVal + _totalFee;
  double get _kembalian => (_uangDibayarVal - _totalBayar) > 0 ? (_uangDibayarVal - _totalBayar) : 0;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _dendaController.addListener(_onDendaChanged);
    _uangDibayarController.addListener(_onUangDibayarChanged);
  }

  @override
  void dispose() {
    _dendaController.dispose();
    _catatanController.dispose();
    _uangDibayarController.dispose();
    super.dispose();
  }

  void _onDendaChanged() {
    final txt = _dendaController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final d = double.tryParse(txt) ?? 0.0;
    setState(() {
      _dendaVal = d;
    });
  }

  void _onUangDibayarChanged() {
    final txt = _uangDibayarController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final u = double.tryParse(txt) ?? 0.0;
    setState(() {
      _uangDibayarVal = u;
    });
  }

  void _setUangQuick(double val) {
    _uangDibayarController.text = val.toInt().toString();
  }

  void _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.isKepalaDesa == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Lihat-Saja: Kepala Desa tidak dapat melakukan transaksi pembayaran.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final dhkpProvider = Provider.of<DhkpProvider>(context, listen: false);

    final success = await paymentProvider.submitMultiPayment(
      items: widget.selectedItems,
      totalDenda: _dendaVal,
      totalBayar: _totalBayar,
      metodePembayaran: _metodePembayaran,
      uangDibayar: _uangDibayarVal > 0 ? _uangDibayarVal : _totalBayar,
      kembalian: _kembalian,
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Refresh DHKP List
      await dhkpProvider.fetchDhkp(currentUser: authProvider.user, isRefresh: true);

      if (!mounted) return;
      Navigator.pop(context, true); // Return success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran Kolektif (${widget.selectedItems.length} NOP) Berhasil Diproses!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    // Group unique WP Names
    final uniqueWpNames = widget.selectedItems.map((e) => e.namaWp).toSet().toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.layers_rounded, color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedItems.length == 1
                                    ? 'Pembayaran STTS PBB-P2'
                                    : 'Bayar Kolektif STTS',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              Text(
                                widget.selectedItems.length == 1
                                    ? 'NOP: ${widget.selectedItems.first.nop}'
                                    : '${widget.selectedItems.length} SPPT Terpilih (${uniqueWpNames.length} Wajib Pajak)',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorder, height: 20),

              // Selected Items Preview Card
              Text(
                'Daftar NOP Terpilih:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.selectedItems.length,
                  separatorBuilder: (_, index) => const Divider(height: 12, color: AppColors.glassBorder),
                  itemBuilder: (context, idx) {
                    final item = widget.selectedItems[idx];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaWp,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'NOP: ${item.nop} • Dusun ${item.dusun}',
                                style: const TextStyle(color: AppColors.accent, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _currencyFormatter.format(item.pbbTerutang),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Calculation Summary Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pokok (PBB Terutang):', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        Text(
                          _currencyFormatter.format(_totalPokok),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    if (_totalFee > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fee Kolektor (Luar Desa):', style: TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600)),
                          Text(
                            _currencyFormatter.format(_totalFee),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Input Denda Sanksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Denda / Sanksi (Opsional):', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            controller: _dendaController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              prefixText: 'Rp ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Total Payment Highlight Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL DIBAYAR:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          '${widget.selectedItems.length} NOP terakumulasi',
                          style: TextStyle(fontSize: 10, color: AppColors.success.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                    Text(
                      _currencyFormatter.format(_totalBayar),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Form Metode Pembayaran
              Text('Metode Pembayaran:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _metodePembayaran,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                dropdownColor: AppColors.surfaceCard,
                items: const [
                  DropdownMenuItem(value: 'TUNAI', child: Text('Tunai (Kolektor Lapangan)')),
                  DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank / Va')),
                  DropdownMenuItem(value: 'QRIS', child: Text('QRIS / E-Wallet')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _metodePembayaran = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Uang Dibayar & Kembalian (Jika Tunai)
              if (_metodePembayaran == 'TUNAI') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Uang Diterima:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(
                      'Kembalian: ${_currencyFormatter.format(_kembalian)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _kembalian > 0 ? AppColors.accent : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _uangDibayarController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: _totalBayar.toInt().toString(),
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 8),
                // Preset Nominal Quick Buttons
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Uang Pas'),
                      onPressed: () => _setUangQuick(_totalBayar),
                      backgroundColor: AppColors.surfaceCard,
                    ),
                    if (_totalBayar <= 50000)
                      ActionChip(
                        label: const Text('50rb'),
                        onPressed: () => _setUangQuick(50000),
                        backgroundColor: AppColors.surfaceCard,
                      ),
                    if (_totalBayar <= 100000)
                      ActionChip(
                        label: const Text('100rb'),
                        onPressed: () => _setUangQuick(100000),
                        backgroundColor: AppColors.surfaceCard,
                      ),
                    if (_totalBayar <= 200000)
                      ActionChip(
                        label: const Text('200rb'),
                        onPressed: () => _setUangQuick(200000),
                        backgroundColor: AppColors.surfaceCard,
                      ),
                    if (_totalBayar <= 500000)
                      ActionChip(
                        label: const Text('500rb'),
                        onPressed: () => _setUangQuick(500000),
                        backgroundColor: AppColors.surfaceCard,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Catatan Tambahan
              Text('Catatan / Keterangan (opsional):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  hintText: 'Misal: Titipan Kolektor RW 02',
                ),
              ),
              const SizedBox(height: 16),

              // Error feedback display
              if (paymentProvider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paymentProvider.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: paymentProvider.isSubmitting ? null : _submitPayment,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    paymentProvider.isSubmitting
                        ? 'Memproses Pembayaran...'
                        : widget.selectedItems.length == 1
                            ? 'Konfirmasi & Simpan Pembayaran STTS'
                            : 'Konfirmasi & Simpan Pembayaran (${widget.selectedItems.length} NOP)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
