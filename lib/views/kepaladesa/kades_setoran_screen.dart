import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/setoran_kecamatan_provider.dart';
import 'widgets/buat_setoran_modal.dart';

class KadesSetoranScreen extends StatefulWidget {
  const KadesSetoranScreen({super.key});

  @override
  State<KadesSetoranScreen> createState() => _KadesSetoranScreenState();
}

class _KadesSetoranScreenState extends State<KadesSetoranScreen> {
  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _selectedStatusFilter = 'SEMUA';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context, listen: false);

    final desaId = authProvider.user?.desaId?.toString();
    await Future.wait([
      setoranProvider.fetchSummary(desaId: desaId),
      setoranProvider.fetchSetoranList(desaId: desaId),
    ]);
  }

  void _openBuatSetoranModal() {
    BuatSetoranModal.show(
      context,
      onSuccess: () {
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context);
    final user = authProvider.user;

    // Filter items locally based on selected chip
    final filteredList = setoranProvider.setoranList.where((item) {
      if (_selectedStatusFilter == 'SEMUA') return true;
      if (_selectedStatusFilter == 'DITERIMA') return item.isDiterima;
      if (_selectedStatusFilter == 'PENDING') return item.isPending;
      if (_selectedStatusFilter == 'DITOLAK') return item.isDitolak;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catatan Setoran ke Kecamatan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${user?.desa?.namaDesa ?? "Desa"} · Riwayat & Rekapitulasi',
              style: const TextStyle(fontSize: 11, color: AppColors.accent),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadData,
            tooltip: 'Perbarui Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards Header
              _buildKpiHeader(setoranProvider),
              const SizedBox(height: 20),

              // Action Banner & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Catatan Setoran',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openBuatSetoranModal,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat Setoran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // List Data or Loading / Empty State
              if (setoranProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (filteredList.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return _buildSetoranCard(item);
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuatSetoranModal,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Setoran Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKpiHeader(SetoranKecamatanProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REKAPITULASI KAS SETORAN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text('Tahun berjalan', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Columns Mini KPI
          Row(
            children: [
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Disetorkan',
                  value: _currency.format(provider.totalDiterima),
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  bg: AppColors.successBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Pending Verifikasi',
                  value: _currency.format(provider.totalPending),
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  bg: AppColors.warningBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Sisa Kas Desa',
                  value: _currency.format(provider.totalSisaKas),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.accent,
                  bg: AppColors.surfaceCard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniKpiTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'SEMUA', 'label': 'Semua Data'},
      {'key': 'DITERIMA', 'label': 'Diterima'},
      {'key': 'PENDING', 'label': 'Pending'},
      {'key': 'DITOLAK', 'label': 'Ditolak'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatusFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceCard,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatusFilter = f['key']!;
                  });
                }
              },
            ),
          );
        }).toList(),
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
        ? 'DITERIMA KECAMATAN'
        : item.isDitolak
            ? 'DITOLAK'
            : 'MENUNGGU VERIFIKASI';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: No Bukti & Status
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
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nomorBukti != null ? 'No. ${item.nomorBukti}' : 'Setoran #${item.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        item.tanggalSetor ?? '-',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nominal Setoran
          Text(
            _currency.format(item.nominal),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Informational Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Metode Pembayaran', item.metodePembayaran ?? '-'),
                if (item.namaBank != null && item.namaBank!.isNotEmpty) _buildDetailRow('Bank / Rekening', item.namaBank!),
                _buildDetailRow('Penyetor', '${item.namaPenyetor ?? "-"} (${item.keterangan ?? "Petugas Desa"})'),
                if (item.keterangan != null && item.keterangan!.isNotEmpty) _buildDetailRow('Catatan Desa', item.keterangan!),
                if (item.keteranganVerifikasi != null && item.keteranganVerifikasi!.isNotEmpty)
                  _buildDetailRow('Catatan Kecamatan', item.keteranganVerifikasi!, isHighlight: true),
                if (item.tanggalVerifikasi != null) _buildDetailRow('Tgl Verifikasi', item.tanggalVerifikasi!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppColors.accent : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: isHighlight ? AppColors.accent : AppColors.textPrimary,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada catatan setoran',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan setoran yang dibuat akan tersimpan\ndan diteruskan ke Kecamatan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openBuatSetoranModal,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat Setoran Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
