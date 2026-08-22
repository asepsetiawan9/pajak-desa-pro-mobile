import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../models/kolektor_target_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kolektor_target_provider.dart';

/// Screen Detail Kinerja Kolektor (Mobile)
/// Dilengkapi KPI Grid, SPPT Progress, Interactive Line/Bar Charts (fl_chart), dan Mini-Leaderboard.
class KinerjaKolektorScreen extends StatefulWidget {
  final int? kolektorId;
  final int? tahun;

  const KinerjaKolektorScreen({
    super.key,
    this.kolektorId,
    this.tahun,
  });

  @override
  State<KinerjaKolektorScreen> createState() => _KinerjaKolektorScreenState();
}

class _KinerjaKolektorScreenState extends State<KinerjaKolektorScreen> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late int _selectedTahun;
  int _activeChartIndex = 0; // 0: Trend Harian (30 Hari), 1: Trend Mingguan (12 Minggu)

  @override
  void initState() {
    super.initState();
    _selectedTahun = widget.tahun ?? DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<KolektorTargetProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (widget.kolektorId != null) {
      await provider.fetchKolektorDetail(widget.kolektorId!, _selectedTahun);
    } else {
      await provider.fetchMyPerformance(_selectedTahun);
    }

    final desaId = auth.user?.desaId ?? auth.user?.desa?.id;
    await provider.fetchLeaderboard(_selectedTahun, desaId: desaId);
  }

  void _onYearChanged(int newYear) {
    if (newYear != _selectedTahun) {
      setState(() {
        _selectedTahun = newYear;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KolektorTargetProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final target = widget.kolektorId != null
        ? provider.selectedDetail
        : provider.myPerformance;

    final isLoading = widget.kolektorId != null
        ? provider.isLoadingDetail
        : provider.isLoading;

    final currentYear = DateTime.now().year;
    final years = [currentYear + 1, currentYear, currentYear - 1, currentYear - 2];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Detail Kinerja Kolektor',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Year Selector Chip Dropdown
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedTahun,
                icon: const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                items: years.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text('Tahun $year'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _onYearChanged(val);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Segarkan Data',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: isLoading
            ? _buildSkeletonLoading()
            : target == null
                ? _buildEmptyState()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header Card (Hero Gradient & Tier Badge)
                        _buildHeroHeaderCard(target),
                        const SizedBox(height: 16),

                        // 2. Catatan / Motivasi Admin (Jika ada)
                        if (target.catatan != null && target.catatan!.trim().isNotEmpty) ...[
                          _buildNoteCard(target.catatan!),
                          const SizedBox(height: 16),
                        ],

                        // 3. KPI Metrics 2x2 Grid
                        _buildKpiGrid(target),
                        const SizedBox(height: 16),

                        // 4. Progres SPPT Realisasi Card
                        _buildSpptProgressCard(target),
                        const SizedBox(height: 16),

                        // 5. Interactive Trends Section (fl_chart)
                        _buildChartsSection(target),
                        const SizedBox(height: 16),

                        // 6. Mini Leaderboard se-Desa
                        _buildLeaderboardSection(provider, auth.user?.id),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ==========================================
  // 1. HERO HEADER CARD
  // ==========================================
  Widget _buildHeroHeaderCard(KolektorTargetModel target) {
    final gradient = _getBadgeGradient(target.badge);
    final glowColor = _getBadgeGlow(target.badge);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle circles
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -15,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Row: Tahun & Rank & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_note_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            'Tahun ${target.tahun}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (target.rank != null && target.rank! > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.leaderboard_rounded, color: Colors.amber, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Rank #${target.rank}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(target.badgeEmoji, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                target.badgeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Name and Village
                Text(
                  target.kolektorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (target.namaDesa != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Desa ${target.namaDesa}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 18),

                // Radial / Percentage Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${target.persentaseNominal.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pencapaian Target Nominal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    target.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. NOTE / MOTIVATION CARD
  // ==========================================
  Widget _buildNoteCard(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan & Arahan Target',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. KPI 2x2 GRID
  // ==========================================
  Widget _buildKpiGrid(KolektorTargetModel target) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'TARGET POKOK',
                value: _currency.format(target.targetNominal),
                subtitle: '${target.targetSppt} lembar SPPT',
                icon: Icons.flag_rounded,
                color: AppColors.info,
                bgColor: const Color(0xFFE0F2FE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'TOTAL REALISASI',
                value: _currency.format(target.realisasiNominal),
                subtitle: '${target.realisasiSppt} SPPT terbayar',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                bgColor: AppColors.successBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'SISA TARGET',
                value: _currency.format(target.sisaNominal),
                subtitle: '${target.sisaSppt} SPPT tersisa',
                icon: Icons.timelapse_rounded,
                color: AppColors.danger,
                bgColor: AppColors.dangerBg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'ESTIMASI INSENTIF',
                value: _currency.format(target.totalFee),
                subtitle: 'Total fee terkumpul',
                icon: Icons.monetization_on_rounded,
                color: AppColors.warning,
                bgColor: AppColors.warningBg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. SPPT PROGRESS CARD
  // ==========================================
  Widget _buildSpptProgressCard(KolektorTargetModel target) {
    final progress = (target.persentaseSppt / 100.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Capaian Lembar SPPT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${target.persentaseSppt.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceCard,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Terbayar: ${target.realisasiSppt} SPPT',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.inputBorder,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Target: ${target.targetSppt} SPPT',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. INTERACTIVE CHARTS (FL_CHART)
  // ==========================================
  Widget _buildChartsSection(KolektorTargetModel target) {
    final dailyData = target.trendHarian ?? [];
    final weeklyData = target.trendMingguan ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Segmented Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tren Setoran Pajak',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Segmented Tab Toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildChartTabButton('Harian', 0),
                    _buildChartTabButton('Mingguan', 1),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Display selected chart
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _activeChartIndex == 0
                ? _buildDailyLineChart(dailyData)
                : _buildWeeklyBarChart(weeklyData),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTabButton(String title, int index) {
    final isSelected = _activeChartIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeChartIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 5A. LineChart untuk Trend Harian (30 Hari)
  Widget _buildDailyLineChart(List<TrendItem> data) {
    if (data.isEmpty) {
      return _buildEmptyChartPlaceholder(
        title: 'Belum Ada Transaksi 30 Hari Terakhir',
        subtitle: 'Data grafik garis akan muncul setelah ada setoran DHKP lunas pada periode ini.',
        icon: Icons.show_chart_rounded,
      );
    }

    final maxNominal = data.map((e) => e.nominal).reduce((a, b) => a > b ? a : b);
    final totalNominal = data.fold<int>(0, (sum, item) => sum + item.nominal);
    final totalSppt = data.fold<int>(0, (sum, item) => sum + item.jumlahSppt);
    final maxY = maxNominal > 0 ? (maxNominal * 1.25).toDouble() : 1000000.0;

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.nominal.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart Statistics Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total 30 Hari: ${_currency.format(totalNominal)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$totalSppt SPPT',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Line Chart Widget
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.inputBorder.withValues(alpha: 0.4),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (data.length / 5).clamp(1, 10).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final rawDate = data[index].tanggal;
                      // Format date string e.g. "2026-08-15" to "15/08"
                      String label = rawDate;
                      try {
                        final parsed = DateTime.parse(rawDate);
                        label = DateFormat('dd/MM').format(parsed);
                      } catch (_) {}

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        _formatCompactCurrency(value),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= data.length) return null;
                      final item = data[index];
                      return LineTooltipItem(
                        '${item.tanggal}\n',
                        const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: '${_currency.format(item.nominal)}\n',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '${item.jumlahSppt} SPPT',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: data.length <= 15,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppColors.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 5B. BarChart untuk Trend Mingguan (12 Minggu)
  Widget _buildWeeklyBarChart(List<TrendMingguanItem> data) {
    if (data.isEmpty) {
      return _buildEmptyChartPlaceholder(
        title: 'Belum Ada Transaksi 12 Minggu Terakhir',
        subtitle: 'Data grafik batang mingguan akan muncul seiring bertambahnya penerimaan pajak.',
        icon: Icons.bar_chart_rounded,
      );
    }

    final maxNominal = data.map((e) => e.nominal).reduce((a, b) => a > b ? a : b);
    final totalNominal = data.fold<int>(0, (sum, item) => sum + item.nominal);
    final totalSppt = data.fold<int>(0, (sum, item) => sum + item.jumlahSppt);
    final maxY = maxNominal > 0 ? (maxNominal * 1.25).toDouble() : 1000000.0;

    final barGroups = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.nominal.toDouble(),
            gradient: const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: AppColors.surfaceCard,
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total 12 Minggu: ${_currency.format(totalNominal)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$totalSppt SPPT',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),

        // Bar Chart Widget
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.inputBorder.withValues(alpha: 0.4),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'M${index + 1}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        _formatCompactCurrency(value),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex < 0 || groupIndex >= data.length) return null;
                    final item = data[groupIndex];
                    return BarTooltipItem(
                      'Minggu ${groupIndex + 1}\n',
                      const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '${_currency.format(item.nominal)}\n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '${item.jumlahSppt} SPPT (${item.mulai} s/d ${item.selesai})',
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChartPlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted.withValues(alpha: 0.5), size: 36),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. MINI LEADERBOARD SE-DESA
  // ==========================================
  Widget _buildLeaderboardSection(
    KolektorTargetProvider provider,
    int? currentUserId,
  ) {
    final list = provider.leaderboard;
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text(
                  'Top 5 Peringkat Kolektor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${list.length} Kolektor',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length > 5 ? 5 : list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = list[index];
            final isMe = item.kolektorId == currentUserId;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMe
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.glassBorder,
                  width: isMe ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _getRankLabel(index),
                      style: TextStyle(
                        color: index < 3 ? Colors.white : AppColors.textSecondary,
                        fontSize: index < 3 ? 14 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Dusun
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.kolektorName,
                                style: TextStyle(
                                  fontWeight: isMe
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Anda',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currency.format(item.realisasiNominal),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Percentage & Tier Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.persentaseNominal.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.badgeEmoji,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            item.badgeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // SKELETON & EMPTY STATES
  // ==========================================
  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Target Belum Ditetapkan ($_selectedTahun)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  'Data target kinerja penagihan untuk tahun ini belum diatur oleh administrator desa. Silakan hubungi admin atau periksa tahun lainnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================
  String _formatCompactCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} rb';
    }
    return value.toInt().toString();
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFEAB308); // Gold
      case 1:
        return const Color(0xFF94A3B8); // Silver
      case 2:
        return const Color(0xFFB45309); // Bronze
      default:
        return AppColors.surfaceCard;
    }
  }

  String _getRankLabel(int index) {
    switch (index) {
      case 0: return '🥇';
      case 1: return '🥈';
      case 2: return '🥉';
      default: return '${index + 1}';
    }
  }

  LinearGradient _getBadgeGradient(String badge) {
    switch (badge) {
      case 'LEGEND':
        return const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEA580C), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'GOLD':
        return const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'SILVER':
        return const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'BRONZE':
        return const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFF9A3412), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getBadgeGlow(String badge) {
    switch (badge) {
      case 'LEGEND':
        return const Color(0xFFEA580C).withValues(alpha: 0.35);
      case 'GOLD':
        return const Color(0xFFF59E0B).withValues(alpha: 0.35);
      case 'SILVER':
        return const Color(0xFF64748B).withValues(alpha: 0.25);
      case 'BRONZE':
        return const Color(0xFFC2410C).withValues(alpha: 0.3);
      default:
        return const Color(0xFF059669).withValues(alpha: 0.3);
    }
  }
}
