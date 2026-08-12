import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/dhkp_model.dart';
import '../../providers/dhkp_provider.dart';
import '../../providers/auth_provider.dart';
import 'multi_bayar_modal.dart';

class DhkpListScreen extends StatefulWidget {
  const DhkpListScreen({super.key});

  @override
  State<DhkpListScreen> createState() => _DhkpListScreenState();
}

class _DhkpListScreenState extends State<DhkpListScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dhkp = Provider.of<DhkpProvider>(context, listen: false);
      _searchController.text = dhkp.searchQuery;
      dhkp.fetchDhkp(isRefresh: true, currentUser: auth.user);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dhkp = Provider.of<DhkpProvider>(context, listen: false);
      if (dhkp.hasMore && !dhkp.isLoadingMore && !dhkp.isLoading) {
        dhkp.fetchNextPage(currentUser: auth.user);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openBayarModal(DhkpModel item) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBayarModal(selectedItems: [item]),
    );

    if (res == true) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dhkp = Provider.of<DhkpProvider>(context, listen: false);
      await dhkp.fetchDhkp(isRefresh: true, currentUser: auth.user);
    }
  }

  void _openFilterBottomSheet(
    DhkpProvider provider,
    dynamic user,
    List<String> allowedDusuns,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
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
                  Text(
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
                      _buildModalStatusCard(
                        'ALL',
                        'Semua',
                        Icons.all_inclusive_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                      const SizedBox(width: 8),
                      _buildModalStatusCard(
                        'belum_bayar',
                        'Belum Bayar',
                        Icons.pending_actions_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                      const SizedBox(width: 8),
                      _buildModalStatusCard(
                        'terbayar',
                        'Terbayar',
                        Icons.task_alt_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Wilayah Dusun
                  if (allowedDusuns.isNotEmpty) ...[
                    Text(
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
                        _buildModalDusunChip(
                          'ALL',
                          'Semua Dusun',
                          provider,
                          user,
                          setModalState,
                        ),
                        for (final dusun in allowedDusuns)
                          _buildModalDusunChip(
                            dusun,
                            'Dusun $dusun',
                            provider,
                            user,
                            setModalState,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Section 3: Urutkan Data (Sorting)
                  Text(
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
                      _buildModalSortChip(
                        'default',
                        'Bawaan',
                        Icons.sort_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                      _buildModalSortChip(
                        'nama_asc',
                        'Nama (A - Z)',
                        Icons.sort_by_alpha_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                      _buildModalSortChip(
                        'nama_desc',
                        'Nama (Z - A)',
                        Icons.sort_by_alpha_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                      _buildModalSortChip(
                        'nominal_desc',
                        'Nominal Terbesar',
                        Icons.arrow_downward_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                      _buildModalSortChip(
                        'nominal_asc',
                        'Nominal Terkecil',
                        Icons.arrow_upward_rounded,
                        provider,
                        user,
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Footer
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            provider.resetFilters(currentUser: user);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('Reset Filter'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Terapkan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalStatusCard(
    String value,
    String label,
    IconData icon,
    DhkpProvider provider,
    dynamic user,
    StateSetter setModalState,
  ) {
    final isSelected = provider.selectedStatus == value;
    final color = value == 'terbayar'
        ? AppColors.success
        : value == 'belum_bayar'
        ? AppColors.danger
        : AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: () {
          setModalState(() {
            provider.setSelectedStatus(value, currentUser: user);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : AppColors.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDusunChip(
    String value,
    String label,
    DhkpProvider provider,
    dynamic user,
    StateSetter setModalState,
  ) {
    final isSelected = provider.selectedDusun == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      avatar: Icon(
        Icons.location_on_outlined,
        size: 14,
        color: isSelected ? Colors.white : AppColors.textMuted,
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.cardBorder,
      ),
      onSelected: (_) {
        setModalState(() {
          provider.setSelectedDusun(value, currentUser: user);
        });
      },
    );
  }

  Widget _buildModalSortChip(
    String value,
    String label,
    IconData icon,
    DhkpProvider provider,
    dynamic user,
    StateSetter setModalState,
  ) {
    final isSelected = provider.sortBy == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : AppColors.textMuted,
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: AppColors.info,
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(
        color: isSelected ? AppColors.info : AppColors.cardBorder,
      ),
      onSelected: (_) {
        setModalState(() {
          provider.setSortBy(value, currentUser: user);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dhkpProvider = Provider.of<DhkpProvider>(context);
    final user = authProvider.user;

    final allowedDusuns = user?.allowedDusuns ?? [];

    // Auto-fetch DHKP if data has not been initialised yet
    if (!dhkpProvider.hasFetched && !dhkpProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !dhkpProvider.hasFetched && !dhkpProvider.isLoading) {
          dhkpProvider.fetchDhkp(isRefresh: true, currentUser: user);
        }
      });
    }

    return Column(
      children: [
        // Search & Filter Header Container
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Row + Filter Modal Trigger Button
              SizedBox(height: 25),
              Row(
                children: [
                  // Search Input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.inputBorder.withValues(alpha: 0.5),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: (val) {
                          dhkpProvider.setSearchQuery(val, currentUser: user);
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari NOP atau Nama Wajib Pajak...',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    dhkpProvider.setSearchQuery(
                                      '',
                                      currentUser: user,
                                    );
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Modal Button (With Active Badge Count)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: dhkpProvider.hasActiveFilters
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _openFilterBottomSheet(
                            dhkpProvider,
                            user,
                            allowedDusuns,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: dhkpProvider.hasActiveFilters
                                    ? AppColors.primary
                                    : AppColors.inputBorder.withValues(
                                        alpha: 0.5,
                                      ),
                                width: dhkpProvider.hasActiveFilters ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: dhkpProvider.hasActiveFilters
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                      // Badge Counter Dot
                      if (dhkpProvider.hasActiveFilters)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${dhkpProvider.activeFilterCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Status Tab Switcher
              Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildSegmentedTab('ALL', 'Semua', dhkpProvider, user),
                    _buildSegmentedTab(
                      'belum_bayar',
                      'Belum Bayar',
                      dhkpProvider,
                      user,
                    ),
                    _buildSegmentedTab(
                      'terbayar',
                      'Terbayar',
                      dhkpProvider,
                      user,
                    ),
                  ],
                ),
              ),

              // Dusun Filter Horizontal Scroll (If more than 1 allowed dusuns or Kades view)
              if (allowedDusuns.length > 1) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDusunPill('ALL', 'Semua Dusun', dhkpProvider, user),
                      for (final dusun in allowedDusuns) ...[
                        const SizedBox(width: 8),
                        _buildDusunPill(
                          dusun,
                          'Dusun $dusun',
                          dhkpProvider,
                          user,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Active Filters Indicators & Quick Reset Row
              if (dhkpProvider.hasActiveFilters) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Filter Aktif: ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (dhkpProvider.searchQuery.isNotEmpty) ...[
                        _buildActiveFilterChip(
                          'Search: "${dhkpProvider.searchQuery}"',
                          () {
                            _searchController.clear();
                            dhkpProvider.setSearchQuery('', currentUser: user);
                          },
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (dhkpProvider.selectedStatus != 'ALL') ...[
                        _buildActiveFilterChip(
                          dhkpProvider.selectedStatus == 'terbayar'
                              ? 'Status: Terbayar'
                              : 'Status: Belum Bayar',
                          () => dhkpProvider.setSelectedStatus(
                            'ALL',
                            currentUser: user,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (dhkpProvider.selectedDusun != 'ALL') ...[
                        _buildActiveFilterChip(
                          'Dusun: ${dhkpProvider.selectedDusun}',
                          () => dhkpProvider.setSelectedDusun(
                            'ALL',
                            currentUser: user,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (dhkpProvider.sortBy != 'default') ...[
                        _buildActiveFilterChip(
                          _getSortLabel(dhkpProvider.sortBy),
                          () => dhkpProvider.setSortBy(
                            'default',
                            currentUser: user,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          dhkpProvider.resetFilters(currentUser: user);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            'Reset Semua',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Result Count & Refresh Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
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
                    dhkpProvider.totalRows > 0
                        ? 'Menampilkan ${dhkpProvider.filteredRows.length} dari ${dhkpProvider.totalRows} SPPT'
                        : 'Menampilkan ${dhkpProvider.filteredRows.length} SPPT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: () =>
                    dhkpProvider.fetchDhkp(isRefresh: true, currentUser: user),
                tooltip: 'Muat Ulang Data',
              ),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: dhkpProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : dhkpProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal Memuat Data DHKP',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dhkpProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => dhkpProvider.fetchDhkp(
                            isRefresh: true,
                            currentUser: user,
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : dhkpProvider.filteredRows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Data SPPT Tidak Ditemukan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dhkpProvider.allRows.isEmpty
                              ? 'Belum ada data DHKP tersimpan atau sesi koneksi perlu diperbarui.'
                              : 'Tidak ada data SPPT yang sesuai dengan kriteria pencarian / filter Anda.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            dhkpProvider.resetFilters(currentUser: user);
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: Text(
                            dhkpProvider.allRows.isEmpty
                                ? 'Muat Data DHKP'
                                : 'Reset Filter & Muat Ulang',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => dhkpProvider.fetchDhkp(
                    isRefresh: true,
                    currentUser: user,
                  ),
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: 100,
                    ),
                    itemCount:
                        dhkpProvider.filteredRows.length +
                        (dhkpProvider.hasMore || dhkpProvider.isLoadingMore
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index < dhkpProvider.filteredRows.length) {
                        final item = dhkpProvider.filteredRows[index];
                        return _buildDhkpCard(item);
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: dhkpProvider.isLoadingMore
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Memuat data SPPT berikutnya...',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTab(
    String value,
    String label,
    DhkpProvider provider,
    dynamic user,
  ) {
    final isSelected = provider.selectedStatus == value;
    final color = value == 'terbayar'
        ? AppColors.success
        : value == 'belum_bayar'
        ? AppColors.danger
        : AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setSelectedStatus(value, currentUser: user),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDusunPill(
    String value,
    String label,
    DhkpProvider provider,
    dynamic user,
  ) {
    final isSelected = provider.selectedDusun == value;
    return InkWell(
      onTap: () => provider.setSelectedDusun(value, currentUser: user),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 13,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'nama_asc':
        return 'Urutan: Nama (A-Z)';
      case 'nama_desc':
        return 'Urutan: Nama (Z-A)';
      case 'nominal_desc':
        return 'Urutan: Nominal Terbesar';
      case 'nominal_asc':
        return 'Urutan: Nominal Terkecil';
      default:
        return 'Urutan: Bawaan';
    }
  }

  Widget _buildDhkpCard(DhkpModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status Badge & Dusun Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dusun ${item.dusun} (RT ${item.rt ?? '-'}/RW ${item.rw ?? '-'})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.isTerbayar
                        ? AppColors.successBg
                        : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.isTerbayar
                          ? AppColors.success
                          : AppColors.danger,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isTerbayar
                            ? Icons.check_circle_outlined
                            : Icons.pending_outlined,
                        size: 13,
                        color: item.isTerbayar
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.isTerbayar ? 'TERBAYAR' : 'BELUM BAYAR',
                        style: TextStyle(
                          color: item.isTerbayar
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Wajib Pajak Name
            Text(
              item.namaWp,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),

            // NOP
            Text(
              'NOP: ${item.nop}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            // Details & Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bumi: ${item.luasBumi.toInt()} m² | Bgn: ${item.luasBgn.toInt()} m²',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      // 1. Mengatur jarak bagian dalam (padding) agar teks tidak menempel ke tepi container
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),

                      // 2. Mengatur dekorasi background dan kelengkungan sudut (border radius)
                      decoration: BoxDecoration(
                        // Warna background: Luar Desa (Merah transparan), Dalam Desa (Hijau transparan)
                        color: item.domisili == 'LUAR_DESA'
                            ? Colors.red.withAlpha(
                                30,
                              ) // Angka 30 membuat warna merahnya soft/muda
                            : Colors.green.withAlpha(
                                30,
                              ), // Angka 30 membuat warna hijaunya soft/muda
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // Membuat sudut container melengkung
                      ),

                      // 3. Isi Container berupa teks yang sudah kita buat sebelumnya
                      child: Text(
                        'Domisili: ${item.domisili?.replaceAll('_', ' ') ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.domisili == 'LUAR_DESA'
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight
                              .bold, // Dibuat tebal agar lebih kontras dan mudah dibaca
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      _currency.format(item.pbbTerutang),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                // Pay Button (If unpaid)
                if (!item.isTerbayar)
                  ElevatedButton.icon(
                    onPressed: () => _openBayarModal(item),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Bayar Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
