import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/setoran_kecamatan_provider.dart';

class BuatSetoranModal extends StatefulWidget {
  final VoidCallback onSuccess;
  final SetoranItem? itemToEdit;

  const BuatSetoranModal({super.key, required this.onSuccess, this.itemToEdit});

  static Future<void> show(BuildContext context, {required VoidCallback onSuccess, SetoranItem? itemToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BuatSetoranModal(onSuccess: onSuccess, itemToEdit: itemToEdit),
    );
  }

  @override
  State<BuatSetoranModal> createState() => _BuatSetoranModalState();
}

class _BuatSetoranModalState extends State<BuatSetoranModal> {
  final _formKey = GlobalKey<FormState>();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  String _kategori = 'SETOR_KECAMATAN';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _nominalController = TextEditingController();
  String _metodeSetoran = 'TRANSFER';
  final TextEditingController _bankTujuanController = TextEditingController(text: 'Bank BJB (Rekening Kas Desa)');
  final TextEditingController _nomorReferensiController = TextEditingController();
  late TextEditingController _penyetorNamaController;
  late TextEditingController _penyetorJabatanController;
  final TextEditingController _catatanDesaController = TextEditingController();

  double _parsedNominal = 0;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final item = widget.itemToEdit;
    if (item != null) {
      _kategori = item.kategori;
      if (item.tanggalSetor != null) {
        try {
          _selectedDate = DateTime.parse(item.tanggalSetor!);
        } catch (_) {}
      }
      _parsedNominal = item.nominal;
      _nominalController.text = item.nominal.toStringAsFixed(0);
      _metodeSetoran = item.metodePembayaran ?? 'TRANSFER';
      _bankTujuanController.text = item.namaBank ?? '';
      _nomorReferensiController.text = item.nomorBukti ?? '';
      _penyetorNamaController = TextEditingController(text: item.namaPenyetor ?? user?.name ?? '');
      _penyetorJabatanController = TextEditingController(text: user?.isKepalaDesa == true ? 'Kepala Desa' : 'Bendahara Desa');
      _catatanDesaController.text = item.keterangan ?? '';
    } else {
      _penyetorNamaController = TextEditingController(text: user?.name ?? '');
      _penyetorJabatanController = TextEditingController(text: user?.isKepalaDesa == true ? 'Kepala Desa' : 'Bendahara Desa');
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _bankTujuanController.dispose();
    _nomorReferensiController.dispose();
    _penyetorNamaController.dispose();
    _penyetorJabatanController.dispose();
    _catatanDesaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onNominalChanged(String val) {
    final cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
    final doubleNominal = double.tryParse(cleanVal) ?? 0;
    setState(() {
      _parsedNominal = doubleNominal;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_parsedNominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal pengeluaran harus lebih besar dari Rp 0'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context, listen: false);

    final bool success;
    if (widget.itemToEdit != null) {
      success = await setoranProvider.updateSetoran(
        id: widget.itemToEdit!.id,
        tanggalSetor: _dateFormat.format(_selectedDate),
        kategori: _kategori,
        nominal: _parsedNominal,
        metodeSetoran: _metodeSetoran,
        bankTujuan: _bankTujuanController.text.trim(),
        nomorReferensi: _nomorReferensiController.text.trim(),
        penyetorNama: _penyetorNamaController.text.trim(),
        penyetorJabatan: _penyetorJabatanController.text.trim(),
        catatanDesa: _catatanDesaController.text.trim(),
        desaId: authProvider.user?.desaId,
      );
    } else {
      success = await setoranProvider.createSetoran(
        tanggalSetor: _dateFormat.format(_selectedDate),
        kategori: _kategori,
        nominal: _parsedNominal,
        metodeSetoran: _metodeSetoran,
        bankTujuan: _bankTujuanController.text.trim(),
        nomorReferensi: _nomorReferensiController.text.trim(),
        penyetorNama: _penyetorNamaController.text.trim(),
        penyetorJabatan: _penyetorJabatanController.text.trim(),
        catatanDesa: _catatanDesaController.text.trim(),
        desaId: authProvider.user?.desaId,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.itemToEdit != null
                      ? 'Catatan pengeluaran berhasil diperbarui!'
                      : 'Catatan pengeluaran berhasil disimpan!',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(setoranProvider.errorMessage ?? 'Gagal menyimpan catatan pengeluaran.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final setoranProvider = Provider.of<SetoranKecamatanProvider>(context);
    final isEditing = widget.itemToEdit != null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note_rounded : Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Catatan Pengeluaran' : 'Catat Pengeluaran Kas Desa',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isEditing ? 'Perbarui data rincian pengeluaran kas' : 'Setoran ke Kecamatan atau Pengeluaran Kegiatan/Operasional',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kategori Pengeluaran Dropdown
              const Text('Kategori Pengeluaran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                ),
                items: const [
                  DropdownMenuItem(value: 'SETOR_KECAMATAN', child: Text('🏛️ Setor PBB ke Kecamatan')),
                  DropdownMenuItem(value: 'KEGIATAN_DESA', child: Text('🎉 Kegiatan Kemasyarakatan / PHBN')),
                  DropdownMenuItem(value: 'OPERASIONAL_DESA', child: Text('⚡ Operasional & Insentif Petugas')),
                  DropdownMenuItem(value: 'ADMINISTRASI', child: Text('📄 Administrasi, ATK & Cetak Resi')),
                  DropdownMenuItem(value: 'LAINNYA', child: Text('🛠️ Pengeluaran Kas Lainnya')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _kategori = val);
                },
              ),
              const SizedBox(height: 6),
              Text(
                _kategori == 'SETOR_KECAMATAN'
                    ? 'ℹ️ Memerlukan verifikasi Admin Kecamatan sebelum memotong saldo.'
                    : '✅ Pengeluaran internal langsung sah memotong Saldo Kas Desa.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kategori == 'SETOR_KECAMATAN' ? AppColors.info : AppColors.success,
                ),
              ),
              const SizedBox(height: 14),

              // Tanggal Setor
              const Text('Tanggal Setor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _displayDateFormat.format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Nominal Input
              const Text('Nominal Setoran (Rp)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                onChanged: _onNominalChanged,
                decoration: InputDecoration(
                  hintText: 'Contoh: 15000000',
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Nominal setoran wajib diisi';
                  return null;
                },
              ),
              if (_parsedNominal > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Terbilang: ${_currencyFormat.format(_parsedNominal)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 14),

              // Metode Setoran & Bank
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Metode Setoran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _metodeSetoran,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank')),
                            DropdownMenuItem(value: 'TUNAI', child: Text('Cash / Tunai')),
                            DropdownMenuItem(value: 'BANK', child: Text('Setor Bank Direct')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _metodeSetoran = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nomor Referensi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nomorReferensiController,
                          decoration: InputDecoration(
                            hintText: 'Opsional (No. Trx)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bank Tujuan
              const Text('Bank / Rekening Tujuan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bankTujuanController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Bank BJB - Rekening Kas Desa',
                  prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                ),
              ),
              const SizedBox(height: 14),

              // Penyetor Nama & Jabatan
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nama Penyetor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _penyetorNamaController,
                          decoration: InputDecoration(
                            hintText: 'Nama Petugas',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jabatan Penyetor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _penyetorJabatanController,
                          decoration: InputDecoration(
                            hintText: 'Mis: Bendahara',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: AppColors.surfaceCard,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Catatan Desa
              const Text('Catatan / Keterangan Desa', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _catatanDesaController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Catatan tambahan setoran (opsional)...',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: setoranProvider.isSubmitting ? null : _handleSubmit,
                  icon: setoranProvider.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isEditing ? Icons.save_rounded : Icons.send_rounded, size: 20),
                  label: Text(
                    setoranProvider.isSubmitting
                        ? 'Menyimpan...'
                        : isEditing
                            ? 'Simpan Perubahan'
                            : 'Simpan Catatan Setoran',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
