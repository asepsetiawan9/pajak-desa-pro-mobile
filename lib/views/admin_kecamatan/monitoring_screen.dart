import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/desa_filter_provider.dart';
import '../../providers/dhkp_provider.dart';
import '../../providers/summary_provider.dart';
import '../../models/dhkp_model.dart';

/// Monitoring Screen untuk Admin Kecamatan
/// Menampilkan browse data DHKP & transaksi lintas desa dengan filter
class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dhkp = Provider.of<DhkpProvider>(context, listen: false);
    final summary = Provider.of<SummaryProvider>(context, listen: false);
    final desaFilter = Provider.of<DesaFilterProvider>(context, listen: false);

    final desaIdParam = desaFilter.isAllDesa ? 'ALL' : desaFilter.selectedDesaId;
    if (dhkp.selectedDesaId != desaIdParam) {
      dhkp.setSelectedDesaId(desaIdParam, currentUser: auth.user);
    } else {
      await dhkp.fetchDhkp(currentUser: auth.user);
    }
    await summary.fetchSummary(desaId: desaFilter.isAllDesa ? null : desaFilter.selectedDesaId);
  }

  @override
  Widget build(BuildContext context) {
    final desaFilter = Provider.of<DesaFilterProvider>(context);
    final dhkp = Provider.of<DhkpProvider>(context);
    final summary = Provider.of<SummaryProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monitoring Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              desaFilter.selectedDesaLabel,
              style: const TextStyle(fontSize: 11, color: AppColors.accent),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Data DHKP'),
            Tab(text: 'Statistik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDhkpTab(dhkp, desaFilter),
          _buildStatistikTab(summary, desaFilter),
        ],
      ),
    );
  }

  Widget _buildDhkpTab(DhkpProvider dhkp, DesaFilterProvider desaFilter) {
    // Filter items berdasarkan desa terpilih dan search
    final searchText = _searchController.text.toLowerCase().trim();
    final filteredItems = dhkp.items.where((item) {
      if (!desaFilter.isAllDesa) {
        if (item.desaId?.toString() != desaFilter.selectedDesaId) return false;
      }
      if (searchText.isNotEmpty) {
        return item.nop.toLowerCase().contains(searchText) ||
            item.namaWp.toLowerCase().contains(searchText) ||
            item.dusun.toLowerCase().contains(searchText);
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari NOP, Nama WP, Dusun...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatChip(
                  'Total',
                  '${filteredItems.length}',
                  AppColors.info,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Lunas',
                  '${filteredItems.where((e) => e.isLunas).length}',
                  AppColors.success,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  'Belum',
                  '${filteredItems.where((e) => !e.isLunas).length}',
                  AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: dhkp.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'Data tidak ditemukan',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildDhkpCard(item, desaFilter.isAllDesa);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDhkpCard(DhkpModel item, bool showDesaBadge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.namaWp,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.isLunas ? AppColors.successBg : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.isLunas ? 'LUNAS' : 'BELUM',
                  style: TextStyle(
                    color: item.isLunas ? AppColors.success : AppColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'NOP: ${item.nop}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📍 ${item.dusun}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isLuarDesa
                      ? AppColors.warningBg
                      : AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (item.isLuarDesa ? AppColors.warning : AppColors.info)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  item.isLuarDesa ? 'Luar Desa' : 'Dalam Desa',
                  style: TextStyle(
                    color: item.isLuarDesa ? AppColors.warning : AppColors.info,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _currency.format(item.pbbTerutang),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
          if (showDesaBadge && (item.namaDesa?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_city_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    item.namaDesa!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistikTab(SummaryProvider summary, DesaFilterProvider desaFilter) {
    final data = summary.summary;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Kecamatan · ${desaFilter.selectedDesaLabel}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildStatCard(
              icon: Icons.receipt_long_rounded,
              title: 'Total SPPT',
              value: '${data?.totalSppt ?? 0}',
              color: AppColors.info,
            ),
            _buildStatCard(
              icon: Icons.attach_money_rounded,
              title: 'Total Ketetapan PBB',
              value: _currency.format(data?.totalPokok ?? 0),
              color: AppColors.primary,
            ),
            _buildStatCard(
              icon: Icons.check_circle_rounded,
              title: 'Total Realisasi',
              value: _currency.format(data?.totalTerbayar ?? 0),
              color: AppColors.success,
            ),
            _buildStatCard(
              icon: Icons.pending_actions_rounded,
              title: 'Sisa Piutang',
              value: _currency.format(data?.sisaTerutang ?? 0),
              color: AppColors.danger,
            ),
            _buildStatCard(
              icon: Icons.percent_rounded,
              title: 'Persentase Capaian',
              value: '${data?.persentaseCapaian.toStringAsFixed(2) ?? "0.00"}%',
              color: AppColors.warning,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: color, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
