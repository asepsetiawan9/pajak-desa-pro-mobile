import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../models/dhkp_model.dart';
import '../../models/transaction_item_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dhkp_provider.dart';
import '../../providers/desa_filter_provider.dart';
import 'multi_bayar_modal.dart';
import 'widgets/struk_modal.dart';
import 'widgets/penerimaan_input_tab.dart';
import 'widgets/penerimaan_riwayat_tab.dart';
import 'widgets/penerimaan_multi_action_bar.dart';

class PenerimaanPbbScreen extends StatefulWidget {
  final int initialSubTab; // 0 = Input Pembayaran, 1 = List Penerimaan

  const PenerimaanPbbScreen({super.key, this.initialSubTab = 0});

  @override
  State<PenerimaanPbbScreen> createState() => _PenerimaanPbbScreenState();
}

class _PenerimaanPbbScreenState extends State<PenerimaanPbbScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _inputSearchController = TextEditingController();
  final TextEditingController _listSearchController = TextEditingController();

  // Tab 1 Filter & Selection States
  String _inputSearchQuery = '';
  String _inputStatusFilter = 'BELUM_BAYAR';
  String _inputDusunFilter = 'ALL';
  String _inputSortBy = 'DEFAULT';
  final Set<int> _selectedDhkpIds = {};

  // Tab 2 Filter States
  List<TransactionItemModel> _transactions = [];
  bool _isLoadingTransactions = false;
  String? _transactionError;
  String _listSearchQuery = '';
  String _listPeriodeFilter = 'HARI_INI';
  String _listMetodeFilter = 'ALL';
  String _listDusunFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialSubTab);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dhkp = Provider.of<DhkpProvider>(context, listen: false);
      if (!dhkp.hasFetched) {
        dhkp.fetchDhkp(currentUser: auth.user);
      }
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputSearchController.dispose();
    _listSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _transactionError = null;
    });

    try {
      final desaFilter = Provider.of<DesaFilterProvider>(context, listen: false);
      final Map<String, String> queryParams = {};
      if (!desaFilter.isAllDesa) {
        queryParams['desa_id'] = desaFilter.selectedDesaId;
      }
      final response = await ApiService.get(
        ApiConstants.transactionsEndpoint,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        List rawList = [];
        if (response.data is List) {
          rawList = response.data as List;
        } else if (response.data is Map) {
          final mapObj = response.data as Map;
          if (mapObj['data'] is List) {
            rawList = mapObj['data'] as List;
          }
        }

        final List<TransactionItemModel> parsedList = [];
        for (var item in rawList) {
          if (item is Map) {
            try {
              final Map<String, dynamic> mapData = Map<String, dynamic>.from(item);
              parsedList.add(TransactionItemModel.fromJson(mapData));
            } catch (e) {
              debugPrint('Error parsing transaction item: $e');
            }
          }
        }

        setState(() {
          _transactions = parsedList;
        });
      } else {
        setState(() {
          _transactionError = response.message.isNotEmpty ? response.message : 'Gagal memuat daftar penerimaan PBB-P2';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transactionError = 'Gagal memuat transaksi: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  void _openPayModal(DhkpModel item) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.isKepalaDesa == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Lihat-Saja: Kepala Desa tidak dapat melakukan transaksi pembayaran.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiBayarModal(selectedItems: [item]),
    );

    if (result == true) {
      _fetchTransactions();
      if (!mounted) return;
      final dhkpProvider = Provider.of<DhkpProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await dhkpProvider.fetchDhkp(isRefresh: true, currentUser: authProvider.user);
    }
  }

  void _openMultiBayarModal(List<DhkpModel> selectedItems) async {
    if (selectedItems.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.isKepalaDesa == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Lihat-Saja: Kepala Desa tidak dapat melakukan transaksi pembayaran.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiBayarModal(selectedItems: selectedItems),
    );

    if (result == true) {
      setState(() {
        _selectedDhkpIds.clear();
      });
      _fetchTransactions();
    }
  }

  void _toggleSelectWpSame(List<DhkpModel> candidates, String wpName) {
    final matches = candidates
        .where((c) => !c.isTerbayar && c.namaWp.trim().toLowerCase() == wpName.trim().toLowerCase())
        .map((c) => c.id)
        .toList();
    if (matches.isEmpty) return;

    final allSelected = matches.every((id) => _selectedDhkpIds.contains(id));

    setState(() {
      if (allSelected) {
        _selectedDhkpIds.removeAll(matches);
      } else {
        _selectedDhkpIds.addAll(matches);
      }
    });
  }

  double get _todayTotalAmount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _transactions
        .where((t) => t.createdAt.startsWith(todayStr))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  int get _todaySttsCount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _transactions.where((t) => t.createdAt.startsWith(todayStr)).length;
  }

  double get _todayCashAmount {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _transactions
        .where((t) => t.createdAt.startsWith(todayStr) && t.metode.toUpperCase() == 'TUNAI')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void _showInputFilterBottomSheet(UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Filter & Urutkan SPPT',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text('Status Tagihan SPPT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip(
                        label: 'Belum Bayar (Prioritas)',
                        isSelected: _inputStatusFilter == 'BELUM_BAYAR',
                        activeColor: AppColors.danger,
                        onTap: () => setModalState(() => _inputStatusFilter = 'BELUM_BAYAR'),
                      ),
                      _buildModalChip(
                        label: 'Lunas STTS',
                        isSelected: _inputStatusFilter == 'LUNAS',
                        activeColor: AppColors.success,
                        onTap: () => setModalState(() => _inputStatusFilter = 'LUNAS'),
                      ),
                      _buildModalChip(
                        label: 'Semua Status',
                        isSelected: _inputStatusFilter == 'ALL',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _inputStatusFilter = 'ALL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (user != null && user.allowedDusuns.isNotEmpty) ...[
                    const Text('Wilayah Dusun Penugasan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip(
                          label: 'Semua Dusun',
                          isSelected: _inputDusunFilter == 'ALL',
                          activeColor: AppColors.accent,
                          onTap: () => setModalState(() => _inputDusunFilter = 'ALL'),
                        ),
                        for (var d in user.allowedDusuns)
                          _buildModalChip(
                            label: 'Dusun $d',
                            isSelected: _inputDusunFilter.toUpperCase() == d.toUpperCase(),
                            activeColor: AppColors.accent,
                            onTap: () => setModalState(() => _inputDusunFilter = d),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  const Text('Urutkan Berdasarkan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip(
                        label: 'Bawaan',
                        isSelected: _inputSortBy == 'DEFAULT',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _inputSortBy = 'DEFAULT'),
                      ),
                      _buildModalChip(
                        label: 'Nama WP (A - Z)',
                        isSelected: _inputSortBy == 'NAMA_ASC',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _inputSortBy = 'NAMA_ASC'),
                      ),
                      _buildModalChip(
                        label: 'Nominal Terbesar',
                        isSelected: _inputSortBy == 'NOMINAL_DESC',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _inputSortBy = 'NOMINAL_DESC'),
                      ),
                      _buildModalChip(
                        label: 'Nominal Terkecil',
                        isSelected: _inputSortBy == 'NOMINAL_ASC',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _inputSortBy = 'NOMINAL_ASC'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _inputSearchQuery = '';
                              _inputSearchController.clear();
                              _inputStatusFilter = 'BELUM_BAYAR';
                              _inputDusunFilter = 'ALL';
                              _inputSortBy = 'DEFAULT';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset Filter'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Terapkan'),
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

  void _showListFilterBottomSheet(UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 22),
                          SizedBox(width: 8),
                          Text('Filter Transaksi Setoran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  const Text('Periode Tanggal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip(
                        label: 'Hari Ini',
                        isSelected: _listPeriodeFilter == 'HARI_INI',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _listPeriodeFilter = 'HARI_INI'),
                      ),
                      _buildModalChip(
                        label: '7 Hari Terakhir',
                        isSelected: _listPeriodeFilter == '7_HARI',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _listPeriodeFilter = '7_HARI'),
                      ),
                      _buildModalChip(
                        label: 'Bulan Ini',
                        isSelected: _listPeriodeFilter == 'BULAN_INI',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _listPeriodeFilter = 'BULAN_INI'),
                      ),
                      _buildModalChip(
                        label: 'Semua Periode',
                        isSelected: _listPeriodeFilter == 'ALL',
                        activeColor: AppColors.primary,
                        onTap: () => setModalState(() => _listPeriodeFilter = 'ALL'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip(
                        label: 'Semua Metode',
                        isSelected: _listMetodeFilter == 'ALL',
                        activeColor: AppColors.accent,
                        onTap: () => setModalState(() => _listMetodeFilter = 'ALL'),
                      ),
                      _buildModalChip(
                        label: 'Tunai (Kolektor)',
                        isSelected: _listMetodeFilter == 'TUNAI',
                        activeColor: AppColors.accent,
                        onTap: () => setModalState(() => _listMetodeFilter = 'TUNAI'),
                      ),
                      _buildModalChip(
                        label: 'Transfer Bank',
                        isSelected: _listMetodeFilter == 'TRANSFER',
                        activeColor: AppColors.accent,
                        onTap: () => setModalState(() => _listMetodeFilter = 'TRANSFER'),
                      ),
                      _buildModalChip(
                        label: 'QRIS / Digital',
                        isSelected: _listMetodeFilter == 'QRIS',
                        activeColor: AppColors.accent,
                        onTap: () => setModalState(() => _listMetodeFilter = 'QRIS'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (user != null && user.allowedDusuns.isNotEmpty) ...[
                    const Text('Dusun Penugasan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip(
                          label: 'Semua Dusun',
                          isSelected: _listDusunFilter == 'ALL',
                          activeColor: AppColors.primary,
                          onTap: () => setModalState(() => _listDusunFilter = 'ALL'),
                        ),
                        for (var d in user.allowedDusuns)
                          _buildModalChip(
                            label: 'Dusun $d',
                            isSelected: _listDusunFilter.toUpperCase() == d.toUpperCase(),
                            activeColor: AppColors.primary,
                            onTap: () => setModalState(() => _listDusunFilter = d),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _listPeriodeFilter = 'HARI_INI';
                              _listMetodeFilter = 'ALL';
                              _listDusunFilter = 'ALL';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset Filter'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Terapkan'),
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

  Widget _buildModalChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showTransactionStrukModal(TransactionItemModel item) {
    StrukModal.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dhkpProvider = Provider.of<DhkpProvider>(context);
    final user = authProvider.user;

    final selectedItems = dhkpProvider.items.where((e) => _selectedDhkpIds.contains(e.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penerimaan PBB-P2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Perbarui Data',
            onPressed: () {
              Provider.of<DhkpProvider>(context, listen: false).fetchDhkp(isRefresh: true, currentUser: user);
              _fetchTransactions();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.point_of_sale_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Input Pembayaran'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Daftar Penerimaan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              PenerimaanInputTab(
                user: user,
                searchController: _inputSearchController,
                searchQuery: _inputSearchQuery,
                statusFilter: _inputStatusFilter,
                dusunFilter: _inputDusunFilter,
                sortBy: _inputSortBy,
                selectedDhkpIds: _selectedDhkpIds,
                todayTotalAmount: _todayTotalAmount,
                todaySttsCount: _todaySttsCount,
                todayCashAmount: _todayCashAmount,
                transactions: _transactions,
                onSearchChanged: (val) => setState(() => _inputSearchQuery = val.trim()),
                onClearSearch: () {
                  _inputSearchController.clear();
                  setState(() => _inputSearchQuery = '');
                },
                onOpenFilterSheet: () => _showInputFilterBottomSheet(user),
                onResetFilter: () {
                  setState(() {
                    _inputSearchQuery = '';
                    _inputSearchController.clear();
                    _inputStatusFilter = 'BELUM_BAYAR';
                    _inputDusunFilter = 'ALL';
                    _inputSortBy = 'DEFAULT';
                  });
                },
                onRemoveStatusFilter: (val) => setState(() => _inputStatusFilter = val),
                onRemoveDusunFilter: (val) => setState(() => _inputDusunFilter = val),
                onRemoveSortFilter: (val) => setState(() => _inputSortBy = val),
                onResetSelection: () => setState(() => _selectedDhkpIds.clear()),
                onToggleItemSelect: (item) {
                  setState(() {
                    if (_selectedDhkpIds.contains(item.id)) {
                      _selectedDhkpIds.remove(item.id);
                    } else {
                      _selectedDhkpIds.add(item.id);
                    }
                  });
                },
                onToggleSelectWpSame: _toggleSelectWpSame,
                onOpenPayModal: _openPayModal,
                onShowStrukModal: _showTransactionStrukModal,
                onRefresh: () async {
                  await dhkpProvider.fetchDhkp(isRefresh: true, currentUser: user);
                  await _fetchTransactions();
                },
              ),
              PenerimaanRiwayatTab(
                user: user,
                searchController: _listSearchController,
                searchQuery: _listSearchQuery,
                periodeFilter: _listPeriodeFilter,
                metodeFilter: _listMetodeFilter,
                dusunFilter: _listDusunFilter,
                transactions: _transactions,
                isLoading: _isLoadingTransactions,
                error: _transactionError,
                onSearchChanged: (val) => setState(() => _listSearchQuery = val.trim()),
                onClearSearch: () {
                  _listSearchController.clear();
                  setState(() => _listSearchQuery = '');
                },
                onOpenFilterSheet: () => _showListFilterBottomSheet(user),
                onPeriodeChanged: (val) => setState(() => _listPeriodeFilter = val),
                onMetodeChanged: (val) => setState(() => _listMetodeFilter = val),
                onResetFilter: () {
                  _listSearchController.clear();
                  setState(() {
                    _listSearchQuery = '';
                    _listPeriodeFilter = 'HARI_INI';
                    _listMetodeFilter = 'ALL';
                    _listDusunFilter = 'ALL';
                  });
                },
                onRemovePeriodeFilter: (val) => setState(() => _listPeriodeFilter = val),
                onRemoveMetodeFilter: (val) => setState(() => _listMetodeFilter = val),
                onRemoveDusunFilter: (val) => setState(() => _listDusunFilter = val),
                onShowStrukModal: _showTransactionStrukModal,
                onRefresh: _fetchTransactions,
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PenerimaanMultiActionBar(
              selectedDhkpIds: _selectedDhkpIds,
              selectedItems: selectedItems,
              onClearSelection: () => setState(() => _selectedDhkpIds.clear()),
              onPayClick: () => _openMultiBayarModal(selectedItems),
            ),
          ),
        ],
      ),
    );
  }
}
