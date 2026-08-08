import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/dhkp_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/dhkp_provider.dart';
import '../../providers/auth_provider.dart';

class BayarModal extends StatefulWidget {
  final DhkpModel dhkpItem;

  const BayarModal({super.key, required this.dhkpItem});

  @override
  State<BayarModal> createState() => _BayarModalState();
}

class _BayarModalState extends State<BayarModal> {
  final _formKey = GlobalKey<FormState>();
  final _dendaController = TextEditingController(text: '0');
  final _catatanController = TextEditingController();
  String _metodePembayaran = 'TUNAI';

  double _dendaVal = 0;
  double get _totalBayar => widget.dhkpItem.pbbTerutang + _dendaVal;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _dendaController.addListener(_onDendaChanged);
  }

  @override
  void dispose() {
    _dendaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _onDendaChanged() {
    final txt = _dendaController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final d = double.tryParse(txt) ?? 0.0;
    setState(() {
      _dendaVal = d;
    });
  }

  void _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final dhkpProvider = Provider.of<DhkpProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await paymentProvider.submitPayment(
      item: widget.dhkpItem,
      denda: _dendaVal,
      totalBayar: _totalBayar,
      metodePembayaran: _metodePembayaran,
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Refresh DHKP List
      await dhkpProvider.fetchDhkp(currentUser: authProvider.user);

      if (!mounted) return;
      Navigator.pop(context, true); // Return success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran NOP ${widget.dhkpItem.nop} berhasil dicatat!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.point_of_sale_rounded, color: AppColors.success),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Input Pembayaran SPPT',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 10),

            // WP Details Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.dhkpItem.namaWp,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NOP: ${widget.dhkpItem.nop}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dusun ${widget.dhkpItem.dusun} • RT ${widget.dhkpItem.rt ?? '-'}/RW ${widget.dhkpItem.rw ?? '-'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nominal Pokok
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PBB Terutang (Pokok):', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  _currencyFormatter.format(widget.dhkpItem.pbbTerutang),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Input Denda
            Text('Denda / Sanksi (opsional):', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dendaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),

            // Metode Pembayaran
            Text('Metode Pembayaran:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _metodePembayaran,
              decoration: const InputDecoration(),
              dropdownColor: AppColors.surfaceCard,
              items: const [
                DropdownMenuItem(value: 'TUNAI', child: Text('Tunai (Kolektor)')),
                DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank')),
                DropdownMenuItem(value: 'QRIS', child: Text('QRIS / Digital')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _metodePembayaran = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Total Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL DIBAYAR:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                  ),
                  Text(
                    _currencyFormatter.format(_totalBayar),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error feedback
            if (paymentProvider.errorMessage != null) ...[
              Text(
                paymentProvider.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
              const SizedBox(height: 10),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: paymentProvider.isSubmitting ? null : _submitPayment,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(paymentProvider.isSubmitting ? 'Memproses...' : 'Konfirmasi & Simpan Pembayaran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
