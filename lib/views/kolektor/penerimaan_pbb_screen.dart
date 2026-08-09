import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';
import '../../models/dhkp_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dhkp_provider.dart';
import 'multi_bayar_modal.dart';

class TransactionItemModel {
  final int id;
  final String kodeTransaksi;
  final String nop;
  final String namaWp;
  final String dusun;
  final double amount;
  final double denda;
  final double pokok;
  final String metode;
  final String createdAt;
  final String status;
  final String? operatorName;

  TransactionItemModel({
    required this.id,
    required this.kodeTransaksi,
    required this.nop,
    required this.namaWp,
    required this.dusun,
    required this.amount,
    this.denda = 0,
    this.pokok = 0,
    required this.metode,
    required this.createdAt,
    required this.status,
    this.operatorName,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    String opName = 'Kolektor Lapangan';
    if (json['operator'] != null && json['operator'] is Map) {
      opName = json['operator']['name'] ?? opName;
    } else if (json['operator_name'] != null) {
      opName = json['operator_name'].toString();
    }

    double tot = (json['total_bayar'] ?? json['amount'] ?? json['pbb_terutang'] ?? 0).toDouble();
    double dnd = (json['denda'] ?? 0).toDouble();
    double pk = (json['pbb_terutang'] ?? (tot - dnd)).toDouble();

    return TransactionItemModel(
      id: json['id'] ?? 0,
      kodeTransaksi: json['kode_transaksi'] ?? json['nomor_stts'] ?? 'STTS-${json['id']}',
      nop: json['nop'] ?? '-',
      namaWp: json['nama_wp'] ?? json['wp_nama'] ?? 'Wajib Pajak',
      dusun: json['dusun'] ?? '-',
      amount: tot,
      denda: dnd,
      pokok: pk,
      metode: json['metode_pembayaran'] ?? json['metode'] ?? 'TUNAI',
      createdAt: json['created_at'] ?? json['tanggal_transaksi'] ?? '',
      status: json['status'] ?? 'SUCCESS',
      operatorName: opName,
    );
  }
}

class PenerimaanPbbScreen extends StatefulWidget {
  final int initialSubTab; // 0 = Input Pembayaran, 1 = List Penerimaan

  const PenerimaanPbbScreen({super.key, this.initialSubTab = 0});

  @override
  State<PenerimaanPbbScreen> createState() => _PenerimaanPbbScreenState();
}

class _PenerimaanPbbScreenState extends State<PenerimaanPbbScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final TextEditingController _inputSearchController = TextEditingController();
  final TextEditingController _listSearchController = TextEditingController();

  // Tab 1 (Input Pembayaran) Filter States
  String _inputSearchQuery = '';
  String _inputStatusFilter = 'BELUM_BAYAR'; // 'BELUM_BAYAR', 'LUNAS', 'ALL'
  String _inputDusunFilter = 'ALL';
  String _inputSortBy = 'DEFAULT'; // 'DEFAULT', 'NAMA_ASC', 'NOMINAL_DESC', 'NOMINAL_ASC'
  final Set<int> _selectedDhkpIds = {};

  // Tab 2 (List Penerimaan) Filter States
  List<TransactionItemModel> _transactions = [];
  bool _isLoadingTransactions = false;
  String? _transactionError;
  String _listSearchQuery = '';
  String _listPeriodeFilter = 'HARI_INI'; // 'HARI_INI', '7_HARI', 'BULAN_INI', 'ALL'
  String _listMetodeFilter = 'ALL'; // 'ALL', 'TUNAI', 'TRANSFER', 'QRIS'
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

    final response = await ApiService.get(ApiConstants.transactionsEndpoint);

    if (!mounted) return;

    if (response.success && response.data != null) {
      final List rawList = response.data is List
          ? response.data
          : (response.data['data'] is List ? response.data['data'] : []);

      setState(() {
        _transactions = rawList.map((e) => TransactionItemModel.fromJson(e)).toList();
        _isLoadingTransactions = false;
      });
    } else {
      setState(() {
        _transactionError = response.message.isNotEmpty ? response.message : 'Gagal memuat daftar penerimaan PBB-P2';
        _isLoadingTransactions = false;
      });
    }
  }

  void _openPayModal(DhkpModel item) async {
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

  // Active filter count for Tab 1
  int get _inputActiveFilterCount {
    int count = 0;
    if (_inputSearchQuery.isNotEmpty) count++;
    if (_inputStatusFilter != 'BELUM_BAYAR') count++;
    if (_inputDusunFilter != 'ALL') count++;
    if (_inputSortBy != 'DEFAULT') count++;
    return count;
  }

  // Active filter count for Tab 2
  int get _listActiveFilterCount {
    int count = 0;
    if (_listSearchQuery.isNotEmpty) count++;
    if (_listPeriodeFilter != 'HARI_INI') count++;
    if (_listMetodeFilter != 'ALL') count++;
    if (_listDusunFilter != 'ALL') count++;
    return count;
  }

  // Transaction Date & Custom Helper Filter
  List<TransactionItemModel> get _filteredTransactions {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    return _transactions.where((t) {
      // 1. Search Query Filter
      if (_listSearchQuery.isNotEmpty) {
        final q = _listSearchQuery.toLowerCase();
        final match = t.namaWp.toLowerCase().contains(q) ||
            t.nop.toLowerCase().contains(q) ||
            t.kodeTransaksi.toLowerCase().contains(q) ||
            t.dusun.toLowerCase().contains(q);
        if (!match) return false;
      }

      // 2. Dusun Filter
      if (_listDusunFilter != 'ALL') {
        if (t.dusun.trim().toUpperCase() != _listDusunFilter.trim().toUpperCase()) {
          return false;
        }
      }

      // 3. Metode Pembayaran Filter
      if (_listMetodeFilter != 'ALL') {
        if (t.metode.toUpperCase() != _listMetodeFilter.toUpperCase()) {
          return false;
        }
      }

      // 4. Periode Tanggal Filter
      if (_listPeriodeFilter == 'HARI_INI') {
        if (!t.createdAt.startsWith(todayStr)) {
          return false;
        }
      } else if (_listPeriodeFilter == '7_HARI') {
        try {
          final dt = DateTime.parse(t.createdAt);
          final diff = now.difference(dt).inDays;
          if (diff > 7) return false;
        } catch (_) {}
      } else if (_listPeriodeFilter == 'BULAN_INI') {
        final currentMonthStr = DateFormat('yyyy-MM').format(now);
        if (!t.createdAt.startsWith(currentMonthStr)) return false;
      }

      return true;
    }).toList();
  }

  // Summary Metrics calculation
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

  // Modal Sheet Filter untuk Sub-Tab 1 (Input Pembayaran)
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

                  // 1. Status Tagihan
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

                  // 2. Dusun Penugasan Filter
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

                  // 3. Urutkan Berdasarkan
                  const Text('Urutkan Berdasarkan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip(
                        label: 'Default',
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

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
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
                            setState(() {}); // Apply state change
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

  // Modal Sheet Filter untuk Sub-Tab 2 (List Penerimaan PBB-P2)
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
                          Text(
                            'Filter Penerimaan PBB-P2',
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

                  // 1. Periode Waktu
                  const Text('Periode Setoran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
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

                  // 2. Metode Pembayaran
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

                  // 3. Dusun Filter
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Bukti Setoran STTS',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'LUNAS STTS',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // STTS Digital Receipt Ticket Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PEMERINTAH KABUPATEN / DESA',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'LENTERA - SURAT TANDA TERIMA SETORAN (STTS)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1, color: AppColors.glassBorder),
                    const SizedBox(height: 12),
                    _buildStrukRow('No. STTS Transaksi', item.kodeTransaksi),
                    _buildStrukRow('Nama Wajib Pajak', item.namaWp),
                    _buildStrukRow('NOP PBB-P2', item.nop),
                    _buildStrukRow('Wilayah Dusun', 'Dusun ${item.dusun}'),
                    _buildStrukRow('Waktu Bayar', item.createdAt.isNotEmpty ? item.createdAt : DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())),
                    _buildStrukRow('Metode Setoran', item.metode),
                    _buildStrukRow('Petugas Kolektor', item.operatorName ?? 'Kolektor Lapangan'),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.glassBorder),
                    const SizedBox(height: 8),
                    _buildStrukRow('PBB Pokok Terutang', _currency.format(item.pokok > 0 ? item.pokok : item.amount)),
                    if (item.denda > 0) _buildStrukRow('Denda / Sanksi', _currency.format(item.denda)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL SETORAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          _currency.format(item.amount),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mengunduh / Menyimpan Struk Resi STTS...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Bagikan Struk'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Struk Bukti Pembayaran STTS telah dicetak via Bluetooth/Thermal Printer.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Cetak Struk'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
  }

  Widget _buildStrukRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
                      Text('List Penerimaan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sub-Tab 1: Input Pembayaran (Kasir STTS)
          _buildInputPembayaranTab(user),

          // Sub-Tab 2: List Penerimaan PBB-P2
          _buildListPenerimaanTab(user),
        ],
      ),
    );
  }

  // ==========================================
  // SUB-TAB 1: INPUT PEMBAYARAN (KASIR STTS)
  // ==========================================
  Widget _buildInputPembayaranTab(UserModel? user) {
    final dhkpProvider = Provider.of<DhkpProvider>(context);

    // Apply local search & filters for Input Pembayaran candidates
    List<DhkpModel> candidates = List.from(dhkpProvider.items);

    if (user != null && user.isKolektor && user.allowedDusuns.isNotEmpty) {
      final allowed = user.allowedDusuns.map((d) => d.trim().toLowerCase()).toList();
      candidates = candidates.where((r) => allowed.contains(r.dusun.trim().toLowerCase())).toList();
    }

    if (_inputDusunFilter != 'ALL') {
      candidates = candidates.where((r) => r.dusun.trim().toUpperCase() == _inputDusunFilter.toUpperCase()).toList();
    }

    if (_inputStatusFilter == 'BELUM_BAYAR') {
      candidates = candidates.where((r) => !r.isTerbayar).toList();
    } else if (_inputStatusFilter == 'LUNAS') {
      candidates = candidates.where((r) => r.isTerbayar).toList();
    }

    if (_inputSearchQuery.isNotEmpty) {
      final q = _inputSearchQuery.toLowerCase();
      candidates = candidates.where((r) {
        return r.namaWp.toLowerCase().contains(q) ||
            r.nop.toLowerCase().contains(q) ||
            r.dusun.toLowerCase().contains(q);
      }).toList();
    }

    // Client sorting
    if (_inputSortBy == 'NAMA_ASC') {
      candidates.sort((a, b) => a.namaWp.toLowerCase().compareTo(b.namaWp.toLowerCase()));
    } else if (_inputSortBy == 'NOMINAL_DESC') {
      candidates.sort((a, b) => b.pbbTerutang.compareTo(a.pbbTerutang));
    } else if (_inputSortBy == 'NOMINAL_ASC') {
      candidates.sort((a, b) => a.pbbTerutang.compareTo(b.pbbTerutang));
    }

    final selectedItems = dhkpProvider.items.where((e) => _selectedDhkpIds.contains(e.id)).toList();
    final selectedTotal = selectedItems.fold(0.0, (sum, e) => sum + e.pbbTerutang);

    final refreshWidget = RefreshIndicator(
      onRefresh: () async {
        await dhkpProvider.fetchDhkp(isRefresh: true, currentUser: user);
        await _fetchTransactions();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: _selectedDhkpIds.isNotEmpty ? 195 : 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Header Card Hari Ini
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PENERIMAAN SETORAN HARI INI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Icon(Icons.today_rounded, color: Colors.white70, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency.format(_todayTotalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$_todaySttsCount STTS Terbayar',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.payments_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tunai: ${_currency.format(_todayCashAmount)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Bottom Sheet Trigger
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputSearchController,
                    onChanged: (val) {
                      setState(() {
                        _inputSearchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari NOP, Nama WP, Dusun...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: _inputSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _inputSearchController.clear();
                                setState(() {
                                  _inputSearchQuery = '';
                                });
                              },
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
                        backgroundColor: _inputActiveFilterCount > 0 ? AppColors.primary : AppColors.surfaceCard,
                        foregroundColor: _inputActiveFilterCount > 0 ? Colors.white : AppColors.textPrimary,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () => _showInputFilterBottomSheet(user),
                    ),
                    if (_inputActiveFilterCount > 0)
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
                            '$_inputActiveFilterCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Active Filter Tags Row
            if (_inputActiveFilterCount > 0) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('Reset Filter'),
                      avatar: const Icon(Icons.refresh_rounded, size: 14),
                      backgroundColor: AppColors.dangerBg,
                      labelStyle: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                      onPressed: () {
                        setState(() {
                          _inputSearchQuery = '';
                          _inputSearchController.clear();
                          _inputStatusFilter = 'BELUM_BAYAR';
                          _inputDusunFilter = 'ALL';
                          _inputSortBy = 'DEFAULT';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    if (_inputStatusFilter != 'BELUM_BAYAR')
                      Chip(
                        label: Text('Status: ${_inputStatusFilter == 'ALL' ? 'Semua' : _inputStatusFilter}'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        onDeleted: () => setState(() => _inputStatusFilter = 'BELUM_BAYAR'),
                      ),
                    if (_inputDusunFilter != 'ALL') ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text('Dusun $_inputDusunFilter'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        onDeleted: () => setState(() => _inputDusunFilter = 'ALL'),
                      ),
                    ],
                    if (_inputSortBy != 'DEFAULT') ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text('Urutan: $_inputSortBy'),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        onDeleted: () => setState(() => _inputSortBy = 'DEFAULT'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Header Row List Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar SPPT Wajib Pajak (${candidates.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (_selectedDhkpIds.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _selectedDhkpIds.clear()),
                    child: const Text(
                      'Reset Pilihan',
                      style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Text(
                    _inputStatusFilter == 'BELUM_BAYAR' ? 'Siap Bayar' : 'Semua Tagihan',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // List Candidates SPPT
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
                        _inputSearchQuery.isNotEmpty
                            ? 'Tidak ada SPPT cocok dengan pencarian "$_inputSearchQuery"'
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
                  final isSelected = _selectedDhkpIds.contains(item.id);
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
                      onTap: !item.isTerbayar
                          ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDhkpIds.remove(item.id);
                                } else {
                                  _selectedDhkpIds.add(item.id);
                                }
                              });
                            }
                          : null,
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
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedDhkpIds.add(item.id);
                                                } else {
                                                  _selectedDhkpIds.remove(item.id);
                                                }
                                              });
                                            },
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
                                          onTap: () => _toggleSelectWpSame(candidates, item.namaWp),
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
                                      _currency.format(item.pbbTerutang),
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
                                    onPressed: () => _openPayModal(item),
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
                                      final matchTrx = _transactions.firstWhere(
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
                                      _showTransactionStrukModal(matchTrx);
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

    return Stack(
      children: [
        refreshWidget,
        if (_selectedDhkpIds.isNotEmpty)
          Positioned(
            left: 14,
            right: 14,
            bottom: 110,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.85, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A), // Dark Slate Navy
                          Color(0xFF064E3B), // Deep Emerald
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.45),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selectedDhkpIds.clear()),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_selectedDhkpIds.length} NOP TERPILIH',
                                      style: const TextStyle(
                                        color: Color(0xFF34D399),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currency.format(selectedTotal),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openMultiBayarModal(selectedItems),
                          icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                          label: Text(
                            'BAYAR (${_selectedDhkpIds.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ==========================================
  // SUB-TAB 2: LIST PENERIMAAN PBB-P2
  // ==========================================
  Widget _buildListPenerimaanTab(UserModel? user) {
    final filtered = _filteredTransactions;
    final totalAmount = filtered.fold(0.0, (sum, t) => sum + t.amount);

    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      color: AppColors.primary,
      child: Column(
        children: [
          // Filter & Summary Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Field & Filter Sheet Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _listSearchController,
                        onChanged: (val) {
                          setState(() {
                            _listSearchQuery = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari Kode STTS, NOP, Nama WP...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                          suffixIcon: _listSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _listSearchController.clear();
                                    setState(() {
                                      _listSearchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _showListFilterBottomSheet(user),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _listActiveFilterCount > 0 ? AppColors.primary : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _listActiveFilterCount > 0 ? AppColors.primary : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 20,
                              color: _listActiveFilterCount > 0 ? Colors.white : AppColors.textPrimary,
                            ),
                            if (_listActiveFilterCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_listActiveFilterCount',
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

                // Quick Periode Segmented Switcher
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
                          isSelected: _listPeriodeFilter == 'HARI_INI',
                          activeColor: AppColors.primary,
                          onTap: () => setState(() => _listPeriodeFilter = 'HARI_INI'),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: '7 Hari',
                          isSelected: _listPeriodeFilter == '7_HARI',
                          activeColor: AppColors.primary,
                          onTap: () => setState(() => _listPeriodeFilter = '7_HARI'),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Bulan Ini',
                          isSelected: _listPeriodeFilter == 'BULAN_INI',
                          activeColor: AppColors.primary,
                          onTap: () => setState(() => _listPeriodeFilter = 'BULAN_INI'),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Semua',
                          isSelected: _listPeriodeFilter == 'ALL',
                          activeColor: AppColors.primary,
                          onTap: () => setState(() => _listPeriodeFilter = 'ALL'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Metode Pembayaran Chips Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Metode: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: _listMetodeFilter == 'ALL',
                        activeColor: AppColors.accent,
                        onTap: () => setState(() => _listMetodeFilter = 'ALL'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Tunai',
                        isSelected: _listMetodeFilter == 'TUNAI',
                        activeColor: AppColors.accent,
                        onTap: () => setState(() => _listMetodeFilter = 'TUNAI'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Transfer',
                        isSelected: _listMetodeFilter == 'TRANSFER',
                        activeColor: AppColors.accent,
                        onTap: () => setState(() => _listMetodeFilter = 'TRANSFER'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'QRIS',
                        isSelected: _listMetodeFilter == 'QRIS',
                        activeColor: AppColors.accent,
                        onTap: () => setState(() => _listMetodeFilter = 'QRIS'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Active Filter Tags Bar (Show removable tags if filter active)
                if (_listActiveFilterCount > 0) ...[
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
                                if (_listPeriodeFilter != 'HARI_INI')
                                  _buildActiveTag(
                                    label: 'Periode: ${_listPeriodeFilter.replaceAll('_', ' ')}',
                                    onRemove: () => setState(() => _listPeriodeFilter = 'HARI_INI'),
                                  ),
                                if (_listMetodeFilter != 'ALL')
                                  _buildActiveTag(
                                    label: 'Metode: $_listMetodeFilter',
                                    onRemove: () => setState(() => _listMetodeFilter = 'ALL'),
                                  ),
                                if (_listDusunFilter != 'ALL')
                                  _buildActiveTag(
                                    label: 'Dusun $_listDusunFilter',
                                    onRemove: () => setState(() => _listDusunFilter = 'ALL'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _listSearchController.clear();
                            setState(() {
                              _listSearchQuery = '';
                              _listPeriodeFilter = 'HARI_INI';
                              _listMetodeFilter = 'ALL';
                              _listDusunFilter = 'ALL';
                            });
                          },
                          child: const Text('Reset', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Summary Row Count & Amount
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
                      _currency.format(totalAmount),
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

          // List Items
          Expanded(
            child: _isLoadingTransactions
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _transactionError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                              const SizedBox(height: 12),
                              Text(_transactionError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchTransactions,
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
                                  _listSearchQuery.isNotEmpty
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
                                  onTap: () => _showTransactionStrukModal(item),
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
                                              _currency.format(item.amount),
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
