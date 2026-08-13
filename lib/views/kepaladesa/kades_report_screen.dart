import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/auth_provider.dart';

class KadesReportScreen extends StatefulWidget {
  const KadesReportScreen({super.key});

  @override
  State<KadesReportScreen> createState() => _KadesReportScreenState();
}

class _KadesReportScreenState extends State<KadesReportScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _details = [];
  Map<String, dynamic>? _summary;
  String _filterBuku = 'SEMUA';

  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.get(
      ApiConstants.report21ColumnEndpoint,
      queryParams: {'buku': _filterBuku},
    );

    if (res.success && res.data != null) {
      setState(() {
        final data = res.data;
        if (data is Map) {
          _details = data['details'] is List ? data['details'] : [];
          _summary = data['summary'] is Map ? Map<String, dynamic>.from(data['summary']) : null;
        } else if (data is List) {
          _details = data;
          _summary = null;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekap Laporan 21 Kolom',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              '${user?.desa?.namaDesa ?? "Desa"} · Evaluasi PBB-P2 Per Dusun (2026)',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.9), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchReport,
            tooltip: 'Perbarui Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _fetchReport,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card Header
                        if (_summary != null) _buildSummaryHeaderCard(),

                        const SizedBox(height: 20),

                        // Section Title & Filter Pills
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Matriks Capaian Dusun',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${_details.length} Dusun',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('SEMUA', 'Semua Buku'),
                              _buildFilterChip('BUKU_1', 'Buku I (s.d 100rb)'),
                              _buildFilterChip('BUKU_2', 'Buku II (100rb - 500rb)'),
                              _buildFilterChip('BUKU_3', 'Buku III (500rb - 2jt)'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // List Dusun Cards
                        if (_details.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Belum ada data laporan realisasi.', style: TextStyle(color: AppColors.textMuted)),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _details.length,
                            itemBuilder: (context, index) {
                              final item = _details[index];
                              return _buildDusunReportCard(item, index);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterBuku == key;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        pressElevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        onSelected: (val) {
          if (_filterBuku != key) {
            setState(() {
              _filterBuku = key;
            });
            _fetchReport();
          }
        },
      ),
    );
  }

  Widget _buildSummaryHeaderCard() {
    final totalTarget = double.tryParse((_summary!['total_pokok_ketetapan'])?.toString() ?? '0') ?? 0;
    final totalRealisasi = double.tryParse((_summary!['total_pokok_realisasi'])?.toString() ?? '0') ?? 0;
    final totalSisa = double.tryParse((_summary!['total_pokok_sisa'])?.toString() ?? '0') ?? 0;
    final totalPersen = double.tryParse((_summary!['persen_pokok_total'])?.toString() ?? '0') ?? 0;
    final totalSpptRealisasi = _summary!['total_sppt_realisasi'] ?? 0;
    final totalSppt = _summary!['total_sppt_ketetapan'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL REALISASI DESA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currency.format(totalRealisasi),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  children: [
                    Text(
                      '${totalPersen.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Tercapai',
                      style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (totalPersen / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
            ),
          ),

          const SizedBox(height: 16),

          // Sub Stats Row
          Row(
            children: [
              Expanded(
                child: _buildHeaderSubStat(
                  'Total Pagu Desa',
                  _currency.format(totalTarget),
                  '$totalSppt SPPT',
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _buildHeaderSubStat(
                  'Sisa Terutang',
                  _currency.format(totalSisa),
                  '${totalSppt - totalSpptRealisasi} SPPT Belum',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSubStat(String label, String value, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(sub, style: const TextStyle(fontSize: 9, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildDusunReportCard(Map<String, dynamic> item, int index) {
    final dusun = item['dusun'] ?? 'Dusun ${index + 1}';
    final targetPokok = double.tryParse((item['pokok_ketetapan'])?.toString() ?? '0') ?? 0;
    final realisasiPokok = double.tryParse((item['pokok_realisasi'])?.toString() ?? '0') ?? 0;
    final sisaPokok = double.tryParse((item['pokok_sisa'])?.toString() ?? '0') ?? 0;
    final persen = double.tryParse((item['persen_pokok'])?.toString() ?? '0') ?? 0;
    final spptRealisasi = item['sppt_realisasi'] ?? 0;
    final spptTotal = item['sppt_ketetapan'] ?? 0;

    final isHigh = persen >= 70;
    final isMid = persen >= 40 && persen < 70;

    final statusColor = isHigh
        ? AppColors.primary
        : isMid
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dusun $dusun',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$spptRealisasi dari $spptTotal SPPT Lunas',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${persen.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (persen / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.inputBorder.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),

            const SizedBox(height: 14),

            // 3 Column Stat Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Pagu Target',
                      _currency.format(targetPokok),
                      AppColors.textPrimary,
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.cardBorder),
                  Expanded(
                    child: _buildMetricItem(
                      'Realisasi',
                      _currency.format(realisasiPokok),
                      AppColors.primary,
                    ),
                  ),
                  Container(width: 1, height: 28, color: AppColors.cardBorder),
                  Expanded(
                    child: _buildMetricItem(
                      'Sisa Terutang',
                      _currency.format(sisaPokok),
                      AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Gagal memuat data laporan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
