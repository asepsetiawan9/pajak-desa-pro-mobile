import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/kolektor_target_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kolektor_target_provider.dart';
import '../kolektor/kinerja_kolektor_screen.dart';

/// Screen Leaderboard & Monitoring Kinerja Seluruh Kolektor Desa (Khusus Kades / Eksekutif)
class KolektorLeaderboardScreen extends StatefulWidget {
  final int? initialTahun;

  const KolektorLeaderboardScreen({
    super.key,
    this.initialTahun,
  });

  @override
  State<KolektorLeaderboardScreen> createState() => _KolektorLeaderboardScreenState();
}

class _KolektorLeaderboardScreenState extends State<KolektorLeaderboardScreen> {
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late int _selectedTahun;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTahun = widget.initialTahun ?? DateTime.now().year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<KolektorTargetProvider>(context, listen: false);
    final desaId = auth.user?.desaId ?? auth.user?.desa?.id;

    await provider.fetchLeaderboard(_selectedTahun, desaId: desaId);
  }

  void _onYearChanged(int newYear) {
    if (newYear != _selectedTahun) {
      setState(() {
        _selectedTahun = newYear;
      });
      _loadLeaderboard();
    }
  }

  LinearGradient _getBadgeGradient(String badge) {
    switch (badge) {
      case 'LEGEND':
        return const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF9A3412)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'GOLD':
        return const LinearGradient(
          colors: [Color(0xFFEAB308), Color(0xFFCA8A04), Color(0xFFA16207)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'SILVER':
        return const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'BRONZE':
        return const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309), Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF475569), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'LEGEND':
        return const Color(0xFFEA580C);
      case 'GOLD':
        return const Color(0xFFEAB308);
      case 'SILVER':
        return const Color(0xFF94A3B8);
      case 'BRONZE':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KolektorTargetProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final namaDesa = auth.user?.desa?.namaDesa ?? 'Desa';

    final currentYear = DateTime.now().year;
    final years = [currentYear + 1, currentYear, currentYear - 1, currentYear - 2];

    final allList = provider.leaderboard;
    final filteredList = _searchQuery.isEmpty
        ? allList
        : allList.where((item) {
            final query = _searchQuery.toLowerCase();
            final nameMatch = item.kolektorName.toLowerCase().contains(query);
            final usernameMatch = item.kolektorUsername.toLowerCase().contains(query);
            final dusunMatch = item.dusunAkses != null &&
                item.dusunAkses.toString().toLowerCase().contains(query);
            return nameMatch || usernameMatch || dusunMatch;
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leaderboard Kolektor',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Desa $namaDesa · Pemantauan Target',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Year Selector Chip
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
            tooltip: 'Segarkan',
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        color: AppColors.primary,
        child: provider.isLoadingLeaderboard
            ? _buildSkeletonLoading()
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Header Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildSummaryCard(allList),
                    ),
                  ),

                  // 2. Search Box
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.glassBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Cari nama kolektor atau dusun...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Section Title & Counter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Peringkat Kinerja Kolektor',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            '${filteredList.length} Kolektor',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. List of Kolektor Cards
                  if (filteredList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredList[index];
                            final rank = item.rank ?? (index + 1);
                            return _buildKolektorItemCard(item, rank);
                          },
                          childCount: filteredList.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ==========================================
  // 1. EXECUTIVE SUMMARY CARD
  // ==========================================
  Widget _buildSummaryCard(List<KolektorTargetModel> list) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalKolektor = list.length;
    final avgPersen = list.isEmpty
        ? 0.0
        : list.fold<double>(0.0, (sum, e) => sum + e.persentaseNominal) / totalKolektor;

    final totalTarget = list.fold<int>(0, (sum, e) => sum + e.targetNominal);
    final totalRealisasi = list.fold<int>(0, (sum, e) => sum + e.realisasiNominal);
    final topPerformer = list.isNotEmpty ? list.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assessment_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ringkasan Kolektor Desa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Rata-rata ${avgPersen.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 KPI Chips
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Kolektor',
                  value: '$totalKolektor Orang',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Realisasi Desa',
                  value: _currency.format(totalRealisasi),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Target Desa',
                  value: _currency.format(totalTarget),
                  color: AppColors.accent,
                ),
              ),
            ],
          ),

          if (topPerformer != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Top Performer: ${topPerformer.kolektorName} (${topPerformer.persentaseNominal.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    topPerformer.badgeEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. KOLEKTOR ITEM CARD
  // ==========================================
  Widget _buildKolektorItemCard(KolektorTargetModel item, int rank) {
    final progress = (item.persentaseNominal / 100.0).clamp(0.0, 1.0);
    final badgeColor = _getBadgeColor(item.badge);

    Widget rankWidget;
    if (rank == 1) {
      rankWidget = _buildMedalBadge('🥇', const Color(0xFFFEF3C7), const Color(0xFFD97706));
    } else if (rank == 2) {
      rankWidget = _buildMedalBadge('🥈', const Color(0xFFF1F5F9), const Color(0xFF64748B));
    } else if (rank == 3) {
      rankWidget = _buildMedalBadge('🥉', const Color(0xFFFFEDD5), const Color(0xFFC2410C));
    } else {
      rankWidget = Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Text(
          '#$rank',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KinerjaKolektorScreen(
                  kolektorId: item.kolektorId,
                  tahun: _selectedTahun,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Rank, Name, Tier Badge, Arrow
                Row(
                  children: [
                    rankWidget,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.kolektorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item.dusunAkses != null && item.dusunAkses.toString().isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Dusun ${item.dusunAkses}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '@${item.kolektorUsername}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Badge Tier
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: _getBadgeGradient(item.badge),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.badgeEmoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 3),
                          Text(
                            item.badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress Bar & Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Realisasi: ${_currency.format(item.realisasiNominal)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '${item.persentaseNominal.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.surfaceCard,
                    valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 12),

                // Sub-stats Row (Target, SPPT, Fee)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Target Pokok', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          _currency.format(item.targetNominal),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Volume SPPT', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          '${item.realisasiSppt}/${item.targetSppt} SPPT',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Insentif / Fee', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          _currency.format(item.totalFee),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedalBadge(String emoji, Color bg, Color border) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  // ==========================================
  // SKELETON & EMPTY STATES
  // ==========================================
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceCard,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 140, height: 14, color: AppColors.surfaceCard),
                        const SizedBox(height: 6),
                        Container(width: 80, height: 10, color: AppColors.surfaceCard),
                      ],
                    ),
                  ),
                  Container(width: 60, height: 20, color: AppColors.surfaceCard),
                ],
              ),
              const SizedBox(height: 16),
              Container(width: double.infinity, height: 8, color: AppColors.surfaceCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.leaderboard_outlined,
                size: 48,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Target Kolektor di Tahun $_selectedTahun',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Admin desa belum menetapkan target penagihan untuk para petugas kolektor pada tahun ini.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
