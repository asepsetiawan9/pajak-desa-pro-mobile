import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/summary_provider.dart';
import '../../providers/desa_filter_provider.dart';
import '../../providers/setoran_kecamatan_provider.dart';

class AdminDashboard extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AdminDashboard({super.key, this.onNavigateTab});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
    final summary = Provider.of<SummaryProvider>(context, listen: false);
    final setoran = Provider.of<SetoranKecamatanProvider>(context, listen: false);

    await desaFilter.fetchDesaList();
    final desaIdParam = desaFilter.isAllDesa ? null : desaFilter.selectedDesaId;
    await summary.fetchSummary(desaId: desaIdParam);
    await setoran.fetchSummary(desaId: desaIdParam);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final summary = Provider.of<SummaryProvider>(context);
    final desaFilter = Provider.of<DesaFilterProvider>(context);
    final setoran = Provider.of<SetoranKecamatanProvider>(context);

    final user = auth.user;
    final summaryData = summary.summary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Admin Kecamatan',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Kec. ${user?.desa?.namaKecamatan ?? "Kecamatan"} · Admin Kecamatan',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Desa Dropdown
              _buildDesaFilter(desaFilter),
              const SizedBox(height: 16),

              // KPI Capaian Utama
              _buildMainKpiCard(summaryData),
              const SizedBox(height: 20),

              // Setoran Kecamatan KPI
              Text(
                'Setoran ke Kecamatan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildSetoranKpiRow(setoran),
              const SizedBox(height: 20),

              // Rekap Per Desa
              Text(
                'Rekap Per Desa',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (setoran.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (setoran.rekapPerDesa.isEmpty)
                _buildEmptyState('Belum ada data rekap desa')
              else
                ...setoran.rekapPerDesa.map((desa) => _buildDesaRekapCard(desa)),

              const SizedBox(height: 20),

              // Quick Actions
              Text(
                'Menu Akses Cepat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Monitoring',
                      subtitle: 'DHKP & Transaksi',
                      color: AppColors.info,
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortcutCard(
                      icon: Icons.verified_rounded,
                      title: 'Setoran',
                      subtitle: 'Verifikasi Desa',
                      color: AppColors.primary,
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesaFilter(DesaFilterProvider desaFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.filter_alt_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: desaFilter.selectedDesaId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('🏘️ Seluruh Desa'),
                  ),
                  ...desaFilter.desaList.map((desa) => DropdownMenuItem(
                        value: desa.id.toString(),
                        child: Text(desa.namaDesa),
                      )),
                ],
                onChanged: (value) {
                  if (value != null) {
                    desaFilter.setSelectedDesa(value);
                    _loadData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainKpiCard(dynamic summaryData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                'CAPAIAN SELURUH DESA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${summaryData?.persentaseCapaian.toStringAsFixed(1) ?? '0.0'}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currency.format(summaryData?.totalTerbayar ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ((summaryData?.persentaseCapaian ?? 0) / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${_currency.format(summaryData?.totalPokok ?? 0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Sisa: ${_currency.format(summaryData?.sisaTerutang ?? 0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetoranKpiRow(SetoranKecamatanProvider setoran) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiMini(
            title: 'DITERIMA',
            value: _currency.format(setoran.totalDiterima),
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            bgColor: AppColors.successBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiMini(
            title: 'PENDING',
            value: _currency.format(setoran.totalPending),
            icon: Icons.pending_rounded,
            color: AppColors.warning,
            bgColor: AppColors.warningBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiMini(
            title: 'SISA KAS',
            value: _currency.format(setoran.totalSisaKas),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.info,
            bgColor: const Color(0xFFE0F2FE),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiMini({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesaRekapCard(SetoranDesaSummary desa) {
    final pct = desa.persentaseDisetor.clamp(0.0, 100.0);
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
                  Text(
                    desa.namaDesa,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pct >= 80
                      ? AppColors.successBg
                      : pct >= 50
                          ? AppColors.warningBg
                          : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: pct >= 80
                        ? AppColors.success
                        : pct >= 50
                            ? AppColors.warning
                            : AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.glassBorder,
              color: pct >= 80
                  ? AppColors.success
                  : pct >= 50
                      ? AppColors.warning
                      : AppColors.danger,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDesaStatItem('Target', _currency.format(desa.targetPbb)),
              _buildDesaStatItem('Disetor', _currency.format(desa.totalDisetor)),
              _buildDesaStatItem('Sisa Kas', _currency.format(desa.sisaKasDesa)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesaStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
