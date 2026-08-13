import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/transaction_item_model.dart';
import '../../../models/user_model.dart';

class PenerimaanRiwayatTab extends StatelessWidget {
  final UserModel? user;
  final TextEditingController searchController;
  final String searchQuery;
  final String periodeFilter;
  final String metodeFilter;
  final String dusunFilter;
  final List<TransactionItemModel> transactions;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilterSheet;
  final ValueChanged<String> onPeriodeChanged;
  final ValueChanged<String> onMetodeChanged;
  final VoidCallback onResetFilter;
  final ValueChanged<String> onRemovePeriodeFilter;
  final ValueChanged<String> onRemoveMetodeFilter;
  final ValueChanged<String> onRemoveDusunFilter;
  final Function(TransactionItemModel item) onShowStrukModal;
  final Future<void> Function() onRefresh;

  const PenerimaanRiwayatTab({
    super.key,
    required this.user,
    required this.searchController,
    required this.searchQuery,
    required this.periodeFilter,
    required this.metodeFilter,
    required this.dusunFilter,
    required this.transactions,
    required this.isLoading,
    required this.error,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilterSheet,
    required this.onPeriodeChanged,
    required this.onMetodeChanged,
    required this.onResetFilter,
    required this.onRemovePeriodeFilter,
    required this.onRemoveMetodeFilter,
    required this.onRemoveDusunFilter,
    required this.onShowStrukModal,
    required this.onRefresh,
  });

  int get _activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (periodeFilter != 'HARI_INI') count++;
    if (metodeFilter != 'ALL') count++;
    if (dusunFilter != 'ALL') count++;
    return count;
  }

  String _getPeriodeLabel(String periodeKey) {
    switch (periodeKey) {
      case 'HARI_INI':
        return 'Hari Ini';
      case '7_HARI':
        return '7 Hari Terakhir';
      case 'BULAN_INI':
        return 'Bulan Ini';
      default:
        return 'Semua Periode';
    }
  }

  List<TransactionItemModel> get _filteredTransactions {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    return transactions.where((t) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final match = t.namaWp.toLowerCase().contains(q) ||
            t.nop.toLowerCase().contains(q) ||
            t.kodeTransaksi.toLowerCase().contains(q) ||
            t.dusun.toLowerCase().contains(q);
        if (!match) return false;
      }

      if (dusunFilter != 'ALL') {
        if (t.dusun.trim().toUpperCase() != dusunFilter.trim().toUpperCase()) {
          return false;
        }
      }

      if (metodeFilter != 'ALL') {
        if (t.metode.toUpperCase() != metodeFilter.toUpperCase()) {
          return false;
        }
      }

      if (periodeFilter == 'HARI_INI') {
        if (!t.createdAt.startsWith(todayStr)) {
          return false;
        }
      } else if (periodeFilter == '7_HARI') {
        try {
          final dt = DateTime.parse(t.createdAt);
          final diff = now.difference(dt).inDays;
          if (diff > 7) return false;
        } catch (_) {}
      } else if (periodeFilter == 'BULAN_INI') {
        final currentMonthStr = DateFormat('yyyy-MM').format(now);
        if (!t.createdAt.startsWith(currentMonthStr)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final filtered = _filteredTransactions;
    final totalAmount = filtered.fold(0.0, (sum, t) => sum + t.amount);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Cari Kode STTS, NOP, Nama WP...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: onClearSearch,
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: onOpenFilterSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0 ? AppColors.primary : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _activeFilterCount > 0 ? AppColors.primary : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 20,
                              color: _activeFilterCount > 0 ? Colors.white : AppColors.textPrimary,
                            ),
                            if (_activeFilterCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Hari Ini',
                          isSelected: periodeFilter == 'HARI_INI',
                          activeColor: AppColors.primary,
                          onTap: () => onPeriodeChanged('HARI_INI'),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: '7 Hari',
                          isSelected: periodeFilter == '7_HARI',
                          activeColor: AppColors.primary,
                          onTap: () => onPeriodeChanged('7_HARI'),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Bulan Ini',
                          isSelected: periodeFilter == 'BULAN_INI',
                          activeColor: AppColors.primary,
                          onTap: () => onPeriodeChanged('BULAN_INI'),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Semua',
                          isSelected: periodeFilter == 'ALL',
                          activeColor: AppColors.primary,
                          onTap: () => onPeriodeChanged('ALL'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Metode: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: metodeFilter == 'ALL',
                        activeColor: AppColors.accent,
                        onTap: () => onMetodeChanged('ALL'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Tunai',
                        isSelected: metodeFilter == 'TUNAI',
                        activeColor: AppColors.accent,
                        onTap: () => onMetodeChanged('TUNAI'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Transfer',
                        isSelected: metodeFilter == 'TRANSFER',
                        activeColor: AppColors.accent,
                        onTap: () => onMetodeChanged('TRANSFER'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'QRIS',
                        isSelected: metodeFilter == 'QRIS',
                        activeColor: AppColors.accent,
                        onTap: () => onMetodeChanged('QRIS'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_activeFilterCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text('Filter Aktif: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (periodeFilter != 'HARI_INI')
                                  _buildActiveTag(
                                    label: 'Periode: ${_getPeriodeLabel(periodeFilter)}',
                                    onRemove: () => onRemovePeriodeFilter('HARI_INI'),
                                  ),
                                if (metodeFilter != 'ALL')
                                  _buildActiveTag(
                                    label: 'Metode: $metodeFilter',
                                    onRemove: () => onRemoveMetodeFilter('ALL'),
                                  ),
                                if (dusunFilter != 'ALL')
                                  _buildActiveTag(
                                    label: 'Dusun $dusunFilter',
                                    onRemove: () => onRemoveDusunFilter('ALL'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onResetFilter,
                          child: const Text('Reset Filter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} Transaksi Setoran',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currency.format(totalAmount),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                              const SizedBox(height: 12),
                              Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: onRefresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, color: AppColors.textMuted.withValues(alpha: 0.5), size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  searchQuery.isNotEmpty
                                      ? 'Tidak ditemukan transaksi setoran cocok'
                                      : 'Belum ada data penerimaan PBB-P2 pada periode ini',
                                  style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.glassBorder),
                                ),
                                child: InkWell(
                                  onTap: () => onShowStrukModal(item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                          ),
                                          child: const Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: AppColors.success,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.namaWp,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'NOP: ${item.nop}',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Dusun ${item.dusun} • ${item.kodeTransaksi}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.accent,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currency.format(item.amount),
                                              style: const TextStyle(
                                                color: AppColors.success,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceCard,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.metode,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTag({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
