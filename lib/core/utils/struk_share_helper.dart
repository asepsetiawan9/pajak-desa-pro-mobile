import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/transaction_item_model.dart';
import '../constants/app_colors.dart';

class StrukShareHelper {
  /// Membagikan data transaksi STTS PBB-P2 dalam format teks terstruktur yang rapi.
  static Future<void> shareStrukText({
    required BuildContext context,
    required TransactionItemModel item,
    String namaDesa = 'BARUDUA',
    String kecamatan = 'MALANGBONG',
    String kabupaten = 'GARUT',
  }) async {
    final NumberFormat currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final String waktuStr = item.createdAt.isNotEmpty
        ? item.createdAt
        : DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

    final StringBuffer sb = StringBuffer();
    sb.writeln('========================================');
    sb.writeln('  LENTERA - SURAT TANDA TERIMA SETORAN  ');
    sb.writeln('        PBB-P2 KAB. ${kabupaten.toUpperCase()}        ');
    sb.writeln('  KEC. ${kecamatan.toUpperCase()} - DESA ${namaDesa.toUpperCase()}  ');
    sb.writeln('========================================');
    sb.writeln('No. STTS     : ${item.kodeTransaksi}');
    sb.writeln('Nama WP      : ${item.namaWp}');
    sb.writeln('NOP PBB-P2   : ${item.nop}');
    sb.writeln('Wilayah      : Dusun ${item.dusun}');
    sb.writeln('Waktu Bayar  : $waktuStr');
    sb.writeln('Metode Bayar : ${item.metode}');
    sb.writeln('Petugas      : ${item.operatorName ?? 'Kolektor Lapangan'}');
    sb.writeln('----------------------------------------');
    sb.writeln('PBB Pokok    : ${currency.format(item.pokok > 0 ? item.pokok : item.amount)}');
    if (item.denda > 0) {
      sb.writeln('Denda/Sanksi : ${currency.format(item.denda)}');
    }
    sb.writeln('----------------------------------------');
    sb.writeln('TOTAL SETORAN: ${currency.format(item.amount)}');
    sb.writeln('STATUS       : *** LUNAS ***');
    sb.writeln('========================================');
    sb.writeln('Terima kasih atas partisipasi Anda dalam');
    sb.writeln('pembayaran PBB-P2 untuk pembangunan desa.');
    sb.writeln('LENTERA • Layanan Elektronik Terpadu Pajak');

    // ignore: deprecated_member_use
    await Share.share(
      sb.toString(),
      subject: 'Bukti Pembayaran STTS PBB-P2 - NOP ${item.nop}',
    );
  }

  /// Mengambil tampilan visual modal resi thermal (via RepaintBoundary) dan membagikannya sebagai file gambar PNG.
  static Future<void> shareStrukImage({
    required BuildContext context,
    required GlobalKey repaintKey,
    required TransactionItemModel item,
  }) async {
    try {
      final RenderRepaintBoundary? boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengambil gambaran resi struk. Pastikan modal struk terbuka.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // Capture gambar dengan pixelRatio 3.0 agar hasil gambar tajam dan tidak pecah (300 DPI equivalent)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengonversi gambar resi.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final String safeKode = item.kodeTransaksi.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final String fileName = 'Struk_STTS_$safeKode.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(buffer);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bukti Pembayaran STTS PBB-P2 (LUNAS)\n'
            'NOP: ${item.nop}\n'
            'Nama: ${item.namaWp}\n'
            'Total: ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(item.amount)}',
        subject: 'Resi STTS PBB-P2 ${item.nop}',
      );
    } catch (e) {
      debugPrint('Error sharing struk image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat membagikan gambar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Menampilkan pilihan Bottom Sheet modern untuk berbagi struk (Teks STTS vs Gambar PNG Thermal).
  static void showShareOptionsModal({
    required BuildContext context,
    required TransactionItemModel item,
    required GlobalKey repaintKey,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bagikan Bukti Struk STTS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih metode berbagi resi bukti setoran PBB-P2 Wajib Pajak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
                tileColor: const Color(0xFF1E293B),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                ),
                title: const Text(
                  'Bagikan Teks STTS Resmi',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Format rincian teks lengkap & rapi (Ringan untuk WhatsApp/SMS)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  shareStrukText(context: context, item: item);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
                tileColor: const Color(0xFF1E293B),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_outlined, color: AppColors.success),
                ),
                title: const Text(
                  'Bagikan Gambar Resi PNG',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Visual gambar resi cetak thermal 300 DPI High-Quality PNG',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () {
                  Navigator.pop(ctx);
                  shareStrukImage(context: context, repaintKey: repaintKey, item: item);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
