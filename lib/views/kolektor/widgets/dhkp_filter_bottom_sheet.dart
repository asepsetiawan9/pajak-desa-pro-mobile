import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/dhkp_provider.dart';

class DhkpFilterBottomSheet extends StatelessWidget {
  final DhkpProvider provider;
  final dynamic user;
  final List<String> allowedDusuns;
  final TextEditingController searchController;

  const DhkpFilterBottomSheet({
    super.key,
    required this.provider,
    required this.user,
    required this.allowedDusuns,
    required this.searchController,
  });

  static void show({
    required BuildContext context,
    required DhkpProvider provider,
    required dynamic user,
    required List<String> allowedDusuns,
    required TextEditingController searchController,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DhkpFilterBottomSheet(
        provider: provider,
        user: user,
        allowedDusuns: allowedDusuns,
        searchController: searchController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> effectiveDusuns = allowedDusuns.isNotEmpty
        ? allowedDusuns
        : (provider.allRows
            .map((r) => r.dusun.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort());

    return StatefulBuilder(
      builder: (context, setModalState) {
        final activeCount = provider.activeFilterCount;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag indicator handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filter & Pengurutan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount Filter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorder, height: 24),

              // Section 1: Status Pembayaran
              const Text(
                'Status Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildModalStatusCard('ALL', 'Semua', Icons.all_inclusive_rounded, provider, setModalState),
                  const SizedBox(width: 8),
                  _buildModalStatusCard('belum_bayar', 'Belum Bayar', Icons.pending_actions_rounded, provider, setModalState),
                  const SizedBox(width: 8),
                  _buildModalStatusCard('terbayar', 'Terbayar', Icons.task_alt_rounded, provider, setModalState),
                ],
              ),
              const SizedBox(height: 20),

              // Section 2: Domisili Wajib Pajak
              const Text(
                'Domisili Wajib Pajak',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildModalDomisiliCard('ALL', 'Semua', Icons.people_alt_rounded, provider, setModalState),
                  const SizedBox(width: 8),
                  _buildModalDomisiliCard('DALAM_DESA', 'Dalam Desa', Icons.home_rounded, provider, setModalState),
                  const SizedBox(width: 8),
                  _buildModalDomisiliCard('LUAR_DESA', 'Luar Desa', Icons.commute_rounded, provider, setModalState),
                ],
              ),
              const SizedBox(height: 20),

              // Section 2: Wilayah Dusun
              if (effectiveDusuns.isNotEmpty) ...[
                const Text(
                  'Wilayah Dusun',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildModalDusunChip('ALL', 'Semua Dusun', provider, setModalState),
                    for (final dusun in effectiveDusuns)
                      _buildModalDusunChip(dusun, 'Dusun $dusun', provider, setModalState),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Section 4: Urutkan Data (Sorting)
              const Text(
                'Urutkan Data',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildModalSortChip('default', 'Bawaan', Icons.sort_rounded, provider, setModalState),
                  _buildModalSortChip('nama_asc', 'Nama (A - Z)', Icons.sort_by_alpha_rounded, provider, setModalState),
                  _buildModalSortChip('nama_desc', 'Nama (Z - A)', Icons.sort_by_alpha_rounded, provider, setModalState),
                  _buildModalSortChip('nominal_desc', 'Nominal Terbesar', Icons.arrow_downward_rounded, provider, setModalState),
                  _buildModalSortChip('nominal_asc', 'Nominal Terkecil', Icons.arrow_upward_rounded, provider, setModalState),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons Footer
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        searchController.clear();
                        provider.resetFilters(currentUser: user);
                        setModalState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reset Filter', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalStatusCard(
    String val,
    String label,
    IconData icon,
    DhkpProvider provider,
    StateSetter setModalState,
  ) {
    final isSelected = provider.selectedStatus == val;
    return Expanded(
      child: InkWell(
        onTap: () {
          provider.setSelectedStatus(val, currentUser: user);
          setModalState(() {});
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDomisiliCard(
    String val,
    String label,
    IconData icon,
    DhkpProvider provider,
    StateSetter setModalState,
  ) {
    final isSelected = provider.selectedDomisili == val;
    return Expanded(
      child: InkWell(
        onTap: () {
          provider.setSelectedDomisili(val, currentUser: user);
          setModalState(() {});
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDusunChip(
    String val,
    String label,
    DhkpProvider provider,
    StateSetter setModalState,
  ) {
    final isSelected = provider.selectedDusun == val;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          provider.setSelectedDusun(val, currentUser: user);
          setModalState(() {});
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildModalSortChip(
    String val,
    String label,
    IconData icon,
    DhkpProvider provider,
    StateSetter setModalState,
  ) {
    final isSelected = provider.sortBy == val;
    return FilterChip(
      selected: isSelected,
      avatar: Icon(icon, size: 14, color: isSelected ? AppColors.primary : AppColors.textMuted),
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          provider.setSortBy(val, currentUser: user);
          setModalState(() {});
        }
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
