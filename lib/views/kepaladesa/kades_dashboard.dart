import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/summary_provider.dart';
import '../../providers/setoran_kecamatan_provider.dart';
import 'kades_report_screen.dart';
import 'kades_setoran_screen.dart';
import 'widgets/buat_setoran_modal.dart';
import 'widgets/setoran_detail_modal.dart';
import '../auth/login_screen.dart';

class KadesDashboard extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const KadesDashboard({super.key, this.onNavigateTab});

  @override
  State<KadesDashboard> createState() => _KadesDashboardState();
}

class _KadesDashboardState extends State<KadesDashboard> {
  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final desaId = authProvider.user?.desaId?.toString();

    await Future.wait([
      Provider.of<SummaryProvider>(context, listen: false).fetchSummary(desaId: desaId),
      Provider.of<SetoranKecamatanProvider>(context, listen: false).fetchSummary(desaId: desaId),
      Provider.of<SetoranKecamatanProvider>(context, listen: false).fetchSetoranList(desaId: desaId),
    ]);
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
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
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Konfirmasi Keluar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Kepala Desa? Anda perlu login kembali untuk mengakses pemantauan eksekutif.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Keluar Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final summaryProvider = Provider.of<SummaryProvider>(context);
    final summary = summaryProvider.summary;
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Kepala Desa',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${user?.desa?.namaDesa ?? "Desa"} · Pemantauan Eksekutif',
                    style: const TextStyle(fontSize: 11, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context, authProvider),
          ),
        ],
      ),
      body: summaryProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Capaian Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'REALISASI PBB-P2 ${(user?.desa?.namaDesa ?? "Desa").toUpperCase()}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Text(
                                  '${summary?.persentaseCapaian.toStringAsFixed(1) ?? '0.0'}%',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _currency.format(summary?.totalTerbayar ?? 0),
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 28,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: (summary?.persentaseCapaian ?? 0) / 100.0,
                            backgroundColor: AppColors.surfaceCard,
                            color: AppColors.success,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Target PBB Pokok', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currency.format(summary?.totalPokok ?? 0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Sisa Terutang', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currency.format(summary?.sisaTerutang ?? 0),
                                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation to 21 Column Report
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(2);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KadesReportScreen()),
                            );
                          }
                        },
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Buka Laporan Realisasi Per Dusun'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Executive Section: Catatan Setoran ke Kecamatan
                    _buildSetoranKecamatanSection(context),
                    const SizedBox(height: 24),

                    // Per Dusun Breakdown
                    Text(
                      'Capaian Per Dusun',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),

                    if (summary?.breakdownDusun.isEmpty ?? true)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Belum ada data breakdown dusun.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: summary!.breakdownDusun.length,
                        itemBuilder: (context, index) {
                          final item = summary.breakdownDusun[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Dusun ${item.dusun}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        '${item.persentase.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: item.persentase / 100.0,
                                    backgroundColor: AppColors.surfaceCard,
                                    color: AppColors.accent,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Terbayar: ${_currency.format(item.totalTerbayar)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
                                      Text('Target: ${_currency.format(item.totalPokok)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSetoranKecamatanSection(BuildContext context) {
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context);
    final recentList = setoranProvider.setoranList.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
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
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setoran ke Kecamatan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Pengawasan & Riwayat Kas Desa',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                onPressed: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KadesSetoranScreen()),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini summary KPI
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diterima', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currency.format(setoranProvider.totalDiterima),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currency.format(setoranProvider.totalPending),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sisa Kas Desa', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _currency.format(setoranProvider.totalSisaKas),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Recent Preview Items
          if (recentList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Text(
                'Belum ada catatan setoran disetorkan.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              children: recentList.map((item) {
                final statusColor = item.isDiterima
                    ? AppColors.success
                    : item.isDitolak
                        ? AppColors.danger
                        : AppColors.warning;
                return InkWell(
                  onTap: () {
                    SetoranDetailModal.show(
                      context,
                      item: item,
                      onRefreshNeeded: _loadDashboardData,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currency.format(item.nominal),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              Text(
                                '${item.tanggalSetor ?? "-"} · ${item.namaPenyetor ?? "Petugas"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.status ?? 'PENDING',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 14),

          // Buttons Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onNavigateTab != null) {
                      widget.onNavigateTab!(1);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KadesSetoranScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.list_alt_rounded, size: 16),
                  label: const Text('Catatan Lengkap', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    BuatSetoranModal.show(
                      context,
                      onSuccess: () => _loadDashboardData(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Buat Setoran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
}
