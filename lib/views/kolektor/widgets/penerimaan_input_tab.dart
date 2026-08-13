import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/dhkp_model.dart';
import '../../../models/transaction_item_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/dhkp_provider.dart';
import 'penerimaan_kpi_cards.dart';

class PenerimaanInputTab extends StatelessWidget {
  final UserModel? user;
  final TextEditingController searchController;
  final String searchQuery;
  final String statusFilter;
  final String dusunFilter;
  final String sortBy;
  final Set<int> selectedDhkpIds;
  final double todayTotalAmount;
  final int todaySttsCount;
  final double todayCashAmount;
  final List<TransactionItemModel> transactions;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilterSheet;
  final VoidCallback onResetFilter;
  final ValueChanged<String> onRemoveStatusFilter;
  final ValueChanged<String> onRemoveDusunFilter;
  final ValueChanged<String> onRemoveSortFilter;
  final VoidCallback onResetSelection;
  final Function(DhkpModel item) onToggleItemSelect;
  final Function(List<DhkpModel> candidates, String wpName) onToggleSelectWpSame;
  final Function(DhkpModel item) onOpenPayModal;
  final Function(TransactionItemModel item) onShowStrukModal;
  final Future<void> Function() onRefresh;

  const PenerimaanInputTab({
    super.key,
    required this.user,
    required this.searchController,
    required this.searchQuery,
    required this.statusFilter,
    required this.dusunFilter,
    required this.sortBy,
    required this.selectedDhkpIds,
    required this.todayTotalAmount,
    required this.todaySttsCount,
    required this.todayCashAmount,
    required this.transactions,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilterSheet,
    required this.onResetFilter,
    required this.onRemoveStatusFilter,
    required this.onRemoveDusunFilter,
    required this.onRemoveSortFilter,
    required this.onResetSelection,
    required this.onToggleItemSelect,
    required this.onToggleSelectWpSame,
    required this.onOpenPayModal,
    required this.onShowStrukModal,
    required this.onRefresh,
  });

  int get _activeFilterCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    if (statusFilter != 'BELUM_BAYAR') count++;
    if (dusunFilter != 'ALL') count++;
    if (sortBy != 'DEFAULT') count++;
    return count;
  }

  String _getSortLabel(String key) {
    switch (key) {
      case 'NAMA_ASC':
        return 'Nama WP (A-Z)';
      case 'NOMINAL_DESC':
        return 'Nominal Terbesar';
      case 'NOMINAL_ASC':
        return 'Nominal Terkecil';
      default:
        return 'Bawaan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dhkpProvider = Provider.of<DhkpProvider>(context);
    final NumberFormat currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Candidates calculation
    List<DhkpModel> candidates = List.from(dhkpProvider.items);

    if (user != null && user!.isKolektor && user!.allowedDusuns.isNotEmpty) {
      final allowed = user!.allowedDusuns.map((d) => d.trim().toLowerCase()).toList();
      candidates = candidates.where((r) => allowed.contains(r.dusun.trim().toLowerCase())).toList();
    }

    if (dusunFilter != 'ALL') {
      candidates = candidates.where((r) => r.dusun.trim().toUpperCase() == dusunFilter.toUpperCase()).toList();
    }

    if (statusFilter == 'BELUM_BAYAR') {
      candidates = candidates.where((r) => !r.isTerbayar).toList();
    } else if (statusFilter == 'LUNAS') {
      candidates = candidates.where((r) => r.isTerbayar).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      candidates = candidates.where((r) {
        return r.namaWp.toLowerCase().contains(q) ||
            r.nop.toLowerCase().contains(q) ||
            r.dusun.toLowerCase().contains(q);
      }).toList();
    }

    if (sortBy == 'NAMA_ASC') {
      candidates.sort((a, b) => a.namaWp.toLowerCase().compareTo(b.namaWp.toLowerCase()));
    } else if (sortBy == 'NOMINAL_DESC') {
      candidates.sort((a, b) => b.pbbTerutang.compareTo(a.pbbTerutang));
    } else if (sortBy == 'NOMINAL_ASC') {
      candidates.sort((a, b) => a.pbbTerutang.compareTo(b.pbbTerutang));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: selectedDhkpIds.isNotEmpty ? 195 : 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PenerimaanKpiCards(
              todayTotalAmount: todayTotalAmount,
              todaySttsCount: todaySttsCount,
              todayCashAmount: todayCashAmount,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari NOP, Nama WP, Dusun...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: onClearSearch,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Stack(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _activeFilterCount > 0 ? AppColors.primary : AppColors.surfaceCard,
                        foregroundColor: _activeFilterCount > 0 ? Colors.white : AppColors.textPrimary,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: onOpenFilterSheet,
                    ),
                    if (_activeFilterCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_activeFilterCount > 0) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('Reset Filter'),
                      avatar: const Icon(Icons.refresh_rounded, size: 14),
                      backgroundColor: AppColors.dangerBg,
                      labelStyle: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                      onPressed: onResetFilter,
                    ),
                    const SizedBox(width: 8),
                    if (statusFilter != 'BELUM_BAYAR')
                      Chip(
                        label: Text('Status: ${statusFilter == 'ALL' ? 'Semua' : statusFilter}'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        onDeleted: () => onRemoveStatusFilter('BELUM_BAYAR'),
                      ),
                    if (dusunFilter != 'ALL') ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text('Dusun $dusunFilter'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        onDeleted: () => onRemoveDusunFilter('ALL'),
                      ),
                    ],
                    if (sortBy != 'DEFAULT') ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text('Urutan: ${_getSortLabel(sortBy)}'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        onDeleted: () => onRemoveSortFilter('DEFAULT'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar SPPT Wajib Pajak (${candidates.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (selectedDhkpIds.isNotEmpty)
                  InkWell(
                    onTap: onResetSelection,
                    child: const Text(
                      'Reset Pilihan',
                      style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    statusFilter == 'BELUM_BAYAR' ? 'Siap Bayar' : 'Semua Tagihan',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (dhkpProvider.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (candidates.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        searchQuery.isNotEmpty
                            ? 'Tidak ada SPPT cocok dengan pencarian "$searchQuery"'
                            : 'Semua SPPT pada filter ini telah LUNAS!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final item = candidates[index];
                  final isSelected = selectedDhkpIds.contains(item.id);
                  final sameWpCount = candidates
                      .where((c) => !c.isTerbayar && c.namaWp.trim().toLowerCase() == item.namaWp.trim().toLowerCase())
                      .length;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (item.isTerbayar ? AppColors.success.withValues(alpha: 0.3) : AppColors.glassBorder),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : null,
                    child: InkWell(
                      onTap: !item.isTerbayar ? () => onToggleItemSelect(item) : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (!item.isTerbayar) ...[
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isSelected,
                                            activeColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            onChanged: (_) => onToggleItemSelect(item),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          item.namaWp,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!item.isTerbayar && sameWpCount > 1) ...[
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => onToggleSelectWpSame(candidates, item.namaWp),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.people_alt_rounded, size: 10, color: AppColors.primary),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '$sameWpCount NOP',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.isTerbayar ? AppColors.successBg : AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: item.isTerbayar ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                  child: Text(
                                    item.isTerbayar ? 'LUNAS STTS' : 'BELUM BAYAR',
                                    style: TextStyle(
                                      color: item.isTerbayar ? AppColors.success : AppColors.danger,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'NOP: ${item.nop}',
                              style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dusun ${item.dusun} • RT ${item.rt ?? '-'}/RW ${item.rw ?? '-'}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PBB Terutang (Pokok)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                    Text(
                                      currency.format(item.pbbTerutang),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                        SizedBox(width: 6),
                                        Text('Terpilih (Kolektif)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  )
                                else if (!item.isTerbayar)
                                  ElevatedButton.icon(
                                    onPressed: () => onOpenPayModal(item),
                                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                                    label: const Text('Bayar STTS'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final matchTrx = transactions.firstWhere(
                                        (t) => t.nop == item.nop,
                                        orElse: () => TransactionItemModel(
                                          id: 0,
                                          kodeTransaksi: 'STTS-${item.id}',
                                          nop: item.nop,
                                          namaWp: item.namaWp,
                                          dusun: item.dusun,
                                          amount: item.pbbTerutang,
                                          metode: 'TUNAI',
                                          createdAt: '',
                                          status: 'SUCCESS',
                                        ),
                                      );
                                      onShowStrukModal(matchTrx);
                                    },
                                    icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                    label: const Text('Lihat Struk'),
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
          ],
        ),
      ),
    );
  }
}
