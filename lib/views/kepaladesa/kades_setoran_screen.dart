import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/setoran_kecamatan_provider.dart';
import 'widgets/buat_setoran_modal.dart';
import 'widgets/setoran_detail_modal.dart';

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

  void _openBuatSetoranModal([SetoranItem? itemToEdit]) {
    BuatSetoranModal.show(
      context,
      itemToEdit: itemToEdit,
      onSuccess: () {
        _loadData();
      },
    );
  }

  void _openDetailModal(SetoranItem item) {
    SetoranDetailModal.show(
      context,
      item: item,
      onRefreshNeeded: _loadData,
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
      if (_selectedStatusFilter == 'SETOR_KECAMATAN') return item.isSetorKecamatan;
      if (_selectedStatusFilter == 'INTERNAL') return !item.isSetorKecamatan;
      if (_selectedStatusFilter == 'PENDING') return item.isPending;
      if (_selectedStatusFilter == 'DITERIMA') return item.isDiterima;
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
              'Pengeluaran Kas & Setoran Desa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${user?.desa?.namaDesa ?? "Desa"} · Operasional & Setoran Kecamatan',
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
              // KPI Cards Header (4 Metrics)
              _buildKpiHeader(setoranProvider),
              const SizedBox(height: 20),

              // Action Banner & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Riwayat Catatan Pengeluaran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openBuatSetoranModal(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Catat Pengeluaran'),
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
        onPressed: () => _openBuatSetoranModal(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
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
                'REKAPITULASI KAS DESA',
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
                    Text('Tahun 2026', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Grid KPI Metrics
          Row(
            children: [
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Realisasi PBB Desa',
                  value: _currency.format(provider.totalRealisasiDesa),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.primary,
                  bg: AppColors.surfaceCard,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Setor ke Kecamatan',
                  value: _currency.format(provider.totalDiterima),
                  icon: Icons.account_balance_rounded,
                  color: Colors.indigo,
                  bg: Colors.indigo.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Pengeluaran Internal',
                  value: _currency.format(provider.totalPengeluaranInternal),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.warning,
                  bg: AppColors.warningBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMiniKpiTile(
                  label: 'Sisa Kas Desa Netto',
                  value: _currency.format(provider.totalSisaKas),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.success,
                  bg: AppColors.successBg,
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
          const SizedBox(height: 4),
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
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context, listen: false);
    final allItems = setoranProvider.setoranList;

    // Hitung jumlah per kategori filter untuk badge count
    final countMap = {
      'SEMUA': allItems.length,
      'SETOR_KECAMATAN': allItems.where((i) => i.isSetorKecamatan).length,
      'INTERNAL': allItems.where((i) => !i.isSetorKecamatan).length,
      'PENDING': allItems.where((i) => i.isPending).length,
      'DITERIMA': allItems.where((i) => i.isDiterima).length,
    };

    final filters = [
      {'key': 'SEMUA', 'label': 'Semua', 'icon': Icons.apps_rounded},
      {'key': 'SETOR_KECAMATAN', 'label': 'Setor', 'icon': Icons.account_balance_rounded},
      {'key': 'INTERNAL', 'label': 'Internal', 'icon': Icons.receipt_long_rounded},
      {'key': 'PENDING', 'label': 'Pending', 'icon': Icons.hourglass_top_rounded},
      {'key': 'DITERIMA', 'label': 'Diterima', 'icon': Icons.check_circle_outline_rounded},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final key = f['key'] as String;
        final label = f['label'] as String;
        final icon = f['icon'] as IconData;
        final isSelected = _selectedStatusFilter == key;
        final count = countMap[key] ?? 0;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedStatusFilter = key;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.glassBorder,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
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

  String _getCategoryBadgeLabel(String kategori) {
    switch (kategori) {
      case 'SETOR_KECAMATAN':
        return '🏛️ Setor Kecamatan';
      case 'KEGIATAN_DESA':
        return '🎉 Kegiatan Desa';
      case 'OPERASIONAL_DESA':
        return '⚡ Operasional';
      case 'ADMINISTRASI':
        return '📄 Administrasi/ATK';
      default:
        return '🛠️ Pengeluaran Lain';
    }
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

    final catColor = _getCategoryColor(item.kategori);

    return InkWell(
      onTap: () => _openDetailModal(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            // Header: Category Badge & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: catColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _getCategoryBadgeLabel(item.kategori),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.tanggalSetor ?? '-',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nominal Setoran & Proof Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nomorBukti != null ? 'No. ${item.nomorBukti}' : 'Setoran #${item.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted),
                    ),
                    Text(
                      _currency.format(item.nominal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  onPressed: () => _openDetailModal(item),
                  tooltip: 'Lihat Detail',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Informational Grid
            Container(
              padding: const EdgeInsets.all(10),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppColors.accent : AppColors.textMuted,
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
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
              onPressed: () => _openBuatSetoranModal(),
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

