import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/summary_provider.dart';
import 'kades_report_screen.dart';
import '../auth/login_screen.dart';

class KadesDashboard extends StatefulWidget {
  const KadesDashboard({super.key});

  @override
  State<KadesDashboard> createState() => _KadesDashboardState();
}

class _KadesDashboardState extends State<KadesDashboard> {
  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SummaryProvider>(context, listen: false).fetchSummary();
    });
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
                  const Text(
                    'Pemantauan Eksekutif PBB-P2',
                    style: TextStyle(fontSize: 11, color: AppColors.accent),
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
            onPressed: () async {
              final navigator = Navigator.of(context);
              await authProvider.logout();
              if (!mounted) return;
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: summaryProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => summaryProvider.fetchSummary(),
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
                                'TOTAL REALISASI DESA',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KadesReportScreen()),
                          );
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
}
