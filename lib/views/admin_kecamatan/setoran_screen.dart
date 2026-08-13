import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/desa_filter_provider.dart';
import '../../providers/setoran_kecamatan_provider.dart';

/// Setoran Screen untuk Admin Kecamatan
/// Menampilkan daftar setoran dari desa-desa serta opsi verifikasi
class SetoranScreen extends StatefulWidget {
  const SetoranScreen({super.key});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final desaFilter = Provider.of<DesaFilterProvider>(context, listen: false);
    final setoran = Provider.of<SetoranKecamatanProvider>(context, listen: false);

    final desaId = desaFilter.isAllDesa ? null : desaFilter.selectedDesaId;
    await setoran.fetchSetoranList(desaId: desaId);
  }

  void _showVerifyDialog(SetoranItem item) {
    final keteranganController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Verifikasi Setoran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Desa', item.namaDesa ?? '-'),
                  _buildDetailRow('Nominal', _currency.format(item.nominal)),
                  _buildDetailRow('No. Bukti', item.nomorBukti ?? '-'),
                  _buildDetailRow('Penyetor', item.namaPenyetor ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keteranganController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Keterangan verifikasi (opsional)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Tolak'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doVerify(item.id, 'DITOLAK', keteranganController.text);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Terima'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _doVerify(item.id, 'DITERIMA', keteranganController.text);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _doVerify(int id, String status, String keterangan) async {
    final setoran = Provider.of<SetoranKecamatanProvider>(context, listen: false);
    final success = await setoran.verifySetoran(
      setoranId: id,
      status: status,
      keterangan: keterangan.isNotEmpty ? keterangan : null,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Setoran berhasil ${status == 'DITERIMA' ? 'diterima' : 'ditolak'}'
              : setoran.errorMessage ?? 'Gagal memverifikasi setoran',
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (success) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final desaFilter = Provider.of<DesaFilterProvider>(context);
    final setoran = Provider.of<SetoranKecamatanProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Setoran ke Kecamatan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              desaFilter.selectedDesaLabel,
              style: const TextStyle(fontSize: 11, color: AppColors.accent),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: setoran.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : setoran.setoranList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: setoran.setoranList.length,
                    itemBuilder: (context, index) {
                      final item = setoran.setoranList[index];
                      return _buildSetoranCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildSetoranCard(SetoranItem item) {
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
        ? 'DITERIMA'
        : item.isDitolak
            ? 'DITOLAK'
            : 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Desa + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_city_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaDesa ?? 'Desa',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (item.nomorBukti != null)
                        Text(
                          'No. ${item.nomorBukti}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nominal
          Text(
            _currency.format(item.nominal),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Tanggal Setor', item.tanggalSetor ?? '-'),
                _buildDetailRow('Metode', item.metodePembayaran ?? '-'),
                _buildDetailRow('Bank', item.namaBank ?? '-'),
                _buildDetailRow('Penyetor', item.namaPenyetor ?? '-'),
                if (item.keterangan != null && item.keterangan!.isNotEmpty)
                  _buildDetailRow('Keterangan', item.keterangan!),
                if (item.keteranganVerifikasi != null &&
                    item.keteranganVerifikasi!.isNotEmpty)
                  _buildDetailRow('Ket. Verifikasi', item.keteranganVerifikasi!),
              ],
            ),
          ),

          // Verify Button (only for PENDING)
          if (item.isPending) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified_rounded, size: 18),
                label: const Text('Verifikasi Setoran'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _showVerifyDialog(item),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada setoran masuk',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setoran dari desa akan muncul di sini\nuntuk diverifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
