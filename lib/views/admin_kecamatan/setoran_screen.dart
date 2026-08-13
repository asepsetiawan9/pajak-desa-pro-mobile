import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/desa_filter_provider.dart';
import '../../providers/setoran_kecamatan_provider.dart';
import '../kepaladesa/widgets/setoran_detail_modal.dart';

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
  String _selectedStatusFilter = 'SEMUA';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final desaFilter = Provider.of<DesaFilterProvider>(context, listen: false);
    final setoran = Provider.of<SetoranKecamatanProvider>(context, listen: false);

    final desaId = desaFilter.isAllDesa ? null : desaFilter.selectedDesaId;
    await Future.wait([
      setoran.fetchSummary(desaId: desaId),
      setoran.fetchSetoranList(desaId: desaId, kategori: 'SETOR_KECAMATAN'),
    ]);
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
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
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

    // Filter items locally based on selected status & search query
    final filteredList = setoran.setoranList.where((item) {
      if (_selectedStatusFilter == 'PENDING' && !item.isPending) return false;
      if (_selectedStatusFilter == 'DITERIMA' && !item.isDiterima) return false;
      if (_selectedStatusFilter == 'DITOLAK' && !item.isDitolak) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchDesa = (item.namaDesa ?? '').toLowerCase().contains(q);
        final matchBukti = (item.nomorBukti ?? '').toLowerCase().contains(q);
        final matchPenyetor = (item.namaPenyetor ?? '').toLowerCase().contains(q);
        return matchDesa || matchBukti || matchPenyetor;
      }

      return true;
    }).toList();

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
              // Mini KPI Summary Header for Admin Kecamatan
              _buildKecamatanKpiHeader(setoran),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama desa, penyetor, no. bukti...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Status Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // Content List or Loading / Empty State
              if (setoran.isLoading)
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
    );
  }

  Widget _buildKecamatanKpiHeader(SetoranKecamatanProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Setoran Diterima', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currency.format(provider.totalDiterima),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.glassBorder),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.warningBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Verifikasi', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _currency.format(provider.totalPending),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'SEMUA', 'label': 'Semua Setoran'},
      {'key': 'PENDING', 'label': '⏳ Pending Verifikasi'},
      {'key': 'DITERIMA', 'label': '✅ Diterima'},
      {'key': 'DITOLAK', 'label': '❌ Ditolak'},
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
        ? 'DITERIMA'
        : item.isDitolak
            ? 'DITOLAK'
            : 'PENDING';

    return InkWell(
      onTap: () {
        SetoranDetailModal.show(
          context,
          item: item,
          onRefreshNeeded: _loadData,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaDesa ?? 'Desa',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.nomorBukti != null)
                              Text(
                                'No. ${item.nomorBukti}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                  if (item.keteranganVerifikasi != null && item.keteranganVerifikasi!.isNotEmpty)
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
          Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
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

