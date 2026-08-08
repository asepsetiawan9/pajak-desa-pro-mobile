import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_service.dart';

class TransactionItemModel {
  final int id;
  final String kodeTransaksi;
  final String nop;
  final String namaWp;
  final String dusun;
  final double amount;
  final String metode;
  final String createdAt;
  final String status;

  TransactionItemModel({
    required this.id,
    required this.kodeTransaksi,
    required this.nop,
    required this.namaWp,
    required this.dusun,
    required this.amount,
    required this.metode,
    required this.createdAt,
    required this.status,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id'] ?? 0,
      kodeTransaksi: json['kode_transaksi'] ?? json['nomor_stts'] ?? 'STTS-${json['id']}',
      nop: json['nop'] ?? '-',
      namaWp: json['nama_wp'] ?? json['wp_nama'] ?? 'Wajib Pajak',
      dusun: json['dusun'] ?? '-',
      amount: (json['total_bayar'] ?? json['amount'] ?? json['pbb_terutang'] ?? 0).toDouble(),
      metode: json['metode_pembayaran'] ?? 'Tunai',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 'SUCCESS',
    );
  }
}

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final NumberFormat _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final TextEditingController _searchController = TextEditingController();

  List<TransactionItemModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.get(ApiConstants.transactionsEndpoint);

    if (!mounted) return;

    if (response.success && response.data != null) {
      final List rawList = response.data is List
          ? response.data
          : (response.data['data'] is List ? response.data['data'] : []);

      setState(() {
        _transactions = rawList.map((e) => TransactionItemModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message.isNotEmpty ? response.message : 'Gagal memuat riwayat transaksi';
        _isLoading = false;
      });
    }
  }

  List<TransactionItemModel> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      return t.namaWp.toLowerCase().contains(q) ||
          t.nop.toLowerCase().contains(q) ||
          t.kodeTransaksi.toLowerCase().contains(q) ||
          t.dusun.toLowerCase().contains(q);
    }).toList();
  }

  double get _totalCollected {
    return _filteredTransactions.fold(0, (sum, item) => sum + item.amount);
  }

  void _showTransactionDetailModal(TransactionItemModel item) {
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
                  Text(
                    'Bukti Setoran STTS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
              _buildDetailRow('No. Transaksi', item.kodeTransaksi),
              _buildDetailRow('Nama Wajib Pajak', item.namaWp),
              _buildDetailRow('NOP PBB-P2', item.nop),
              _buildDetailRow('Wilayah Dusun', 'Dusun ${item.dusun}'),
              _buildDetailRow('Metode Bayar', item.metode),
              _buildDetailRow('Waktu Transaksi', item.createdAt),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Setoran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Struk Bukti Pembayaran STTS telah dicetak/disimpan.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('Cetak / Bagikan Struk'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi STTS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Perbarui Data',
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search & Summary Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari NOP, Nama WP, Kode STTS, Dusun...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ${filtered.length} Transaksi',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _currency.format(_totalCollected),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
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
                                  Icon(Icons.receipt_long_outlined, color: AppColors.textMuted.withOpacity(0.5), size: 64),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Tidak ada transaksi cocok pencarian'
                                        : 'Belum ada riwayat transaksi setoran STTS',
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
                                    onTap: () => _showTransactionDetailModal(item),
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
                                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
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
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textMuted,
                                                  ),
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
      ),
    );
  }
}
