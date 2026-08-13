import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/struk_share_helper.dart';
import '../../../models/transaction_item_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';

class StrukModal extends StatelessWidget {
  final TransactionItemModel item;

  const StrukModal({super.key, required this.item});

  static void show(BuildContext context, TransactionItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StrukModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey strukKey = GlobalKey();
    final NumberFormat currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final userDesa = authProvider.user?.desa;
    final String namaDesa = (userDesa?.namaDesa != null && userDesa!.namaDesa.isNotEmpty)
        ? userDesa.namaDesa
        : settingsProvider.settings.namaDesa;
    final String namaKec = (userDesa?.namaKecamatan != null && userDesa!.namaKecamatan.isNotEmpty)
        ? userDesa.namaKecamatan
        : settingsProvider.settings.namaKecamatan;
    final String namaKab = (userDesa?.namaKabupaten != null && userDesa!.namaKabupaten.isNotEmpty)
        ? userDesa.namaKabupaten
        : settingsProvider.settings.namaKabupaten;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bukti Setoran STTS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'LUNAS STTS',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // STTS Digital Receipt Ticket Box (Wrapped with RepaintBoundary for PNG snapshot)
          RepaintBoundary(
            key: strukKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'PEMERINTAH KAB. ${namaKab.toUpperCase()} — DESA ${namaDesa.toUpperCase()}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'KEC. ${namaKec.toUpperCase()} • STTS PBB-P2',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SURAT TANDA TERIMA SETORAN (STTS)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1, color: AppColors.glassBorder),
                  const SizedBox(height: 12),
                  _buildStrukRow('No. STTS Transaksi', item.kodeTransaksi),
                  _buildStrukRow('Nama Wajib Pajak', item.namaWp),
                  _buildStrukRow('NOP PBB-P2', item.nop),
                  _buildStrukRow('Wilayah Dusun', 'Dusun ${item.dusun}'),
                  _buildStrukRow('Waktu Bayar', item.createdAt.isNotEmpty ? item.createdAt : DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())),
                  _buildStrukRow('Metode Setoran', item.metode),
                  _buildStrukRow('Petugas Kolektor', item.operatorName ?? 'Kolektor Lapangan'),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  const SizedBox(height: 8),
                  _buildStrukRow('PBB Pokok Terutang', currency.format(item.pokok > 0 ? item.pokok : item.amount)),
                  if (item.denda > 0) _buildStrukRow('Denda / Sanksi', currency.format(item.denda)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL SETORAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        currency.format(item.amount),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    StrukShareHelper.showShareOptionsModal(
                      context: context,
                      item: item,
                      repaintKey: strukKey,
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Bagikan Struk'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Struk Bukti Pembayaran STTS telah dicetak via Bluetooth/Thermal Printer.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Cetak Struk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrukRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
