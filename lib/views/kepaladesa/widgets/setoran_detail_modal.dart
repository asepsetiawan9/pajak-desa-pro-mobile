import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/setoran_kecamatan_provider.dart';
import 'buat_setoran_modal.dart';

class SetoranDetailModal extends StatelessWidget {
  final SetoranItem item;
  final VoidCallback onRefreshNeeded;

  const SetoranDetailModal({
    super.key,
    required this.item,
    required this.onRefreshNeeded,
  });

  static Future<void> show(
    BuildContext context, {
    required SetoranItem item,
    required VoidCallback onRefreshNeeded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetoranDetailModal(
        item: item,
        onRefreshNeeded: onRefreshNeeded,
      ),
    );
  }

  Color _getCategoryColor(String kategori) {
    switch (kategori) {
      case 'SETOR_KECAMATAN':
        return Colors.indigo;
      case 'KEGIATAN_DESA':
        return AppColors.success;
      case 'OPERASIONAL_DESA':
        return AppColors.warning;
      case 'ADMINISTRASI':
        return Colors.cyan.shade700;
      default:
        return Colors.purple;
    }
  }

  String _getCategoryLabel(String kategori) {
    switch (kategori) {
      case 'SETOR_KECAMATAN':
        return '🏛️ Setor PBB ke Kecamatan';
      case 'KEGIATAN_DESA':
        return '🎉 Kegiatan Kemasyarakatan';
      case 'OPERASIONAL_DESA':
        return '⚡ Operasional & Insentif';
      case 'ADMINISTRASI':
        return '📄 Administrasi & ATK';
      default:
        return '🛠️ Pengeluaran Kas Lainnya';
    }
  }

  void _confirmDelete(BuildContext context) {
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 10),
            Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus catatan pengeluaran ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Hapus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final success = await setoranProvider.deleteSetoran(item.id);
              if (context.mounted) {
                Navigator.pop(context); // Close bottom sheet
                onRefreshNeeded();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Catatan pengeluaran berhasil dihapus.'
                          : setoranProvider.errorMessage ?? 'Gagal menghapus catatan.',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmAccKades(BuildContext context, bool isApprove) {
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context, listen: false);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.verified_rounded : Icons.cancel_rounded,
              color: isApprove ? AppColors.success : AppColors.danger,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              isApprove ? 'Setujui (ACC) Pengeluaran?' : 'Tolak Pengeluaran?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Pengeluaran sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.nominal)} akan disetujui secara resmi dan memotong Saldo Kas Desa.'
                  : 'Pengeluaran ini akan ditolak dan tidak akan memotong Saldo Kas Desa.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: isApprove ? 'Catatan persetujuan (opsional)...' : 'Alasan penolakan (wajib)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: Icon(isApprove ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 18),
            label: Text(isApprove ? 'ACC & Setujui' : 'Tolak Pengeluaran'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final success = await setoranProvider.verifySetoran(
                setoranId: item.id,
                status: isApprove ? 'DITERIMA' : 'DITOLAK',
                keterangan: notesController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context); // Close bottom sheet
                onRefreshNeeded();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isApprove ? 'Pengeluaran berhasil disetujui (ACC)!' : 'Pengeluaran berhasil ditolak.')
                          : setoranProvider.errorMessage ?? 'Gagal memproses persetujuan.',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isInternal = !item.isSetorKecamatan;

    final statusColor = item.isDiterima
        ? AppColors.success
        : item.isDitolak
            ? AppColors.danger
            : AppColors.warning;

    final statusBg = item.isDiterima
        ? AppColors.successBg
        : item.isDitolak
            ? AppColors.dangerBg
            : AppColors.warningBg;

    final statusLabel = item.isDiterima
        ? (isInternal ? 'DISETUJUI KADES' : 'DITERIMA KECAMATAN')
        : item.isDitolak
            ? (isInternal ? 'DITOLAK KADES' : 'DITOLAK KECAMATAN')
            : (isInternal ? 'MENUNGGU ACC KADES' : 'MENUNGGU VERIFIKASI');

    final categoryColor = _getCategoryColor(item.kategori);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Badge & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _getCategoryLabel(item.kategori),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: categoryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nominal Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOMINAL PENGELUARAN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currency.format(item.nominal),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        item.nomorBukti != null ? 'No. ${item.nomorBukti}' : 'ID Trx #${item.id}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        item.tanggalSetor ?? '-',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Rincian Grid
            const Text(
              'Rincian Pengeluaran Kas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  if (item.namaDesa != null) _buildInfoRow('Desa Pengirim', item.namaDesa!, icon: Icons.location_city_rounded),
                  _buildInfoRow('Metode Setor', item.metodePembayaran ?? '-', icon: Icons.payment_rounded),
                  if (item.namaBank != null && item.namaBank!.isNotEmpty) _buildInfoRow('Bank / Rekening', item.namaBank!, icon: Icons.account_balance_rounded),
                  _buildInfoRow('Penanggung Jawab', '${item.namaPenyetor ?? "-"} (${item.keterangan ?? "Petugas Desa"})', icon: Icons.person_rounded),
                  if (item.keterangan != null && item.keterangan!.isNotEmpty) _buildInfoRow('Catatan Desa', item.keterangan!, icon: Icons.description_rounded),
                  if (item.keteranganVerifikasi != null && item.keteranganVerifikasi!.isNotEmpty)
                    _buildInfoRow('Catatan Kecamatan', item.keteranganVerifikasi!, icon: Icons.verified_user_rounded, isHighlight: true),
                  if (item.tanggalVerifikasi != null) _buildInfoRow('Tgl Verifikasi', item.tanggalVerifikasi!, icon: Icons.event_available_rounded),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons for Kepala Desa (ACC / Tolak)
            if (isInternal && item.isPending && user?.isKepalaDesa == true) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAccKades(context, true),
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: const Text('ACC & Setujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmAccKades(context, false),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons (Edit / Hapus)
            if (item.isPending && (user?.isKepalaDesa == true || user?.isBendahara == true)) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close detail modal
                        BuatSetoranModal.show(
                          context,
                          onSuccess: onRefreshNeeded,
                          itemToEdit: item,
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Catatan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Hapus Catatan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tutup', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required IconData icon, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlight ? AppColors.accent : AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppColors.accent : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: isHighlight ? AppColors.accent : AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
