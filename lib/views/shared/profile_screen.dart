import 'package:flutter/material.dart';
import 'package:pajak_mobile/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.dangerBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Konfirmasi Keluar Akun',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun LENTERA Mobile? Anda perlu login kembali untuk mengakses data penagihan.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              'Keluar Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 1. Initate Provider Fetch Settings after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<SettingsProvider>(
        context,
        listen: false,
      ).fetchSettings(desaId: auth.user?.desa?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.user;
    final set = settingsProvider.settings;
    final isSuperAdminSystem = user?.isSuperAdminSystem ?? false;
    final isKades = user?.isKepalaDesa ?? false;

    final String roleBadgeText = isSuperAdminSystem
        ? 'ADMIN KECAMATAN (PENGAWASAN)'
        : isKades
        ? 'KEPALA DESA (EKSEKUTIF)'
        : 'KOLEKTOR LAPANGAN PBB-P2';

    final Color roleBadgeColor = isSuperAdminSystem
        ? AppColors.primary
        : isKades
        ? const Color(0xFFD97706)
        : AppColors.primary;

    final Color roleBadgeBg = isSuperAdminSystem
        ? AppColors.primary.withValues(alpha: 0.1)
        : isKades
        ? const Color(0xFFFFFBEB)
        : AppColors.primary.withValues(alpha: 0.1);

    final Color roleBadgeBorder = isSuperAdminSystem
        ? AppColors.primary.withValues(alpha: 0.3)
        : isKades
        ? const Color(0xFFFCD34D)
        : AppColors.primary.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Hero Profile Header Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Banner Background
                  Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isSuperAdminSystem
                          ? const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isKades
                          ? const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : AppColors.primaryGradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(
                            isSuperAdminSystem
                                ? Icons.verified_user_rounded
                                : isKades
                                ? Icons.admin_panel_settings_rounded
                                : Icons.shield_rounded,
                            size: 140,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar & User Info Section
                  Transform.translate(
                    offset: const Offset(0, -45),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: isSuperAdminSystem
                                      ? const Color(0xFFE0F2FE)
                                      : isKades
                                      ? const Color(0xFFFEF3C7)
                                      : AppColors.successBg,
                                  child: Icon(
                                    isSuperAdminSystem
                                        ? Icons.verified_rounded
                                        : isKades
                                        ? Icons.stars_rounded
                                        : Icons.person_pin_rounded,
                                    size: 48,
                                    color: isSuperAdminSystem
                                        ? const Color(0xFF0284C7)
                                        : isKades
                                        ? const Color(0xFFD97706)
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              // Online Status Dot
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(
                                  right: 4,
                                  bottom: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.name ?? 'Pengguna LENTERA',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: roleBadgeBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: roleBadgeBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSuperAdminSystem
                                      ? Icons.account_balance_rounded
                                      : isKades
                                      ? Icons.workspace_premium_rounded
                                      : Icons.badge_rounded,
                                  size: 16,
                                  color: roleBadgeColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  roleBadgeText,
                                  style: TextStyle(
                                    color: roleBadgeColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '@${user?.username ?? 'username'}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${set?.namaDesa ?? 'N/A'}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ', Kecamatan : ${set?.namaKecamatan ?? 'N/A'}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Kabupaten : ${set?.namaKabupaten ?? 'N/A'}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(
                            height: 1,
                            color: AppColors.glassBorder,
                          ),
                          const SizedBox(height: 16),

                          // 3-Column Mini KPI Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniKpiItem(
                                label: 'Hak Akses Role',
                                value: isSuperAdminSystem
                                    ? 'Kecamatan'
                                    : isKades
                                    ? 'Eksekutif'
                                    : 'Kolektor',
                                icon: Icons.security_rounded,
                                iconColor: AppColors.info,
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: AppColors.glassBorder,
                              ),
                              _buildMiniKpiItem(
                                label: 'Cakupan Wilayah',
                                value: isSuperAdminSystem
                                    ? 'Kecamatan'
                                    : (user?.allowedDusuns.isEmpty ?? true
                                          ? 'Semua Dusun'
                                          : '${user!.allowedDusuns.length} Dusun'),
                                icon: Icons.map_rounded,
                                iconColor: AppColors.primary,
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: AppColors.glassBorder,
                              ),
                              _buildMiniKpiItem(
                                label: 'Status Sesi',
                                value: 'Aktif',
                                icon: Icons.check_circle_rounded,
                                iconColor: AppColors.success,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Wilayah Penugasan & Scope Card
            _buildSectionCard(
              title: 'Wilayah Penugasan & Cakupan',
              icon: Icons.location_on_rounded,
              iconColor: AppColors.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSuperAdminSystem
                        ? 'Sebagai Admin Kecamatan, Anda memiliki akses pengawasan & rekapitulasi real-time seluruh desa di wilayah kecamatan.'
                        : isKades
                        ? 'Sebagai Kepala Desa, Anda memiliki akses pemantauan data real-time untuk seluruh dusun di wilayah desa.'
                        : 'Aplikasi disaring secara otomatis hanya untuk menampilkan data SPPT & penerimaan di dusun berikut:',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isSuperAdminSystem ||
                      isKades ||
                      (user?.allowedDusuns.isEmpty ?? true))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isSuperAdminSystem
                                  ? 'Seluruh Desa di Kecamatan ${user?.desa?.namaKecamatan ?? "Kecamatan"}'
                                  : 'Seluruh Wilayah Desa (Akses Penuh / Executive)',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: user!.allowedDusuns.map((dusun) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pin_drop_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dusun $dusun',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Hak Akses & Fitur Aplikasi Card
            _buildSectionCard(
              title: 'Hak Akses & Fitur Aplikasi',
              icon: Icons.verified_user_rounded,
              iconColor: AppColors.info,
              child: Column(
                children: isSuperAdminSystem
                    ? [
                        _buildFeatureTile(
                          icon: Icons.analytics_rounded,
                          title: 'Dashboard Executive Rekap Seluruh Desa',
                          subtitle:
                              'Pantau target PBB, realisasi, & setoran seluruh desa di kecamatan',
                          enabled: true,
                        ),
                        _buildFeatureTile(
                          icon: Icons.bar_chart_rounded,
                          title: 'Monitoring DHKP & Transaksi Lintas Desa',
                          subtitle: 'Pencarian & statistik SPPT lintas desa',
                          enabled: true,
                        ),
                        _buildFeatureTile(
                          icon: Icons.verified_rounded,
                          title: 'Verifikasi Setoran Desa ke Kecamatan',
                          subtitle:
                              'Persetujuan / penolakan setoran kas desa ke kecamatan',
                          enabled: true,
                        ),
                      ]
                    : isKades
                    ? [
                        _buildFeatureTile(
                          icon: Icons.insert_chart_rounded,
                          title: 'Dashboard Rekapitulasi Real-Time',
                          subtitle:
                              'Pantau target, realisasi, & persentase capaian desa',
                          enabled: true,
                        ),
                        _buildFeatureTile(
                          icon: Icons.table_chart_rounded,
                          title: 'Laporan 21 Kolom & Filter Buku I-V',
                          subtitle:
                              'Akses penuh laporan keuangan & klasifikasi buku pajak',
                          enabled: true,
                        ),
                        _buildFeatureTile(
                          icon: Icons.point_of_sale_rounded,
                          title: 'Mode Kasir Penagihan STTS',
                          subtitle:
                              'Khusus role Kolektor Lapangan (Disabled untuk Kades)',
                          enabled: false,
                        ),
                      ]
                    : [
                        _buildFeatureTile(
                          icon: Icons.point_of_sale_rounded,
                          title: 'Kasir Penagihan STTS Instan',
                          subtitle:
                              'Terima pembayaran PBB-P2 & cetak bukti transaksi',
                          enabled: true,
                        ),
                        _buildFeatureTile(
                          icon: Icons.list_alt_rounded,
                          title: 'Data DHKP Dusun Penugasan',
                          subtitle:
                              'Cari & filter SPPT berdasarkan NOP, nama, & status',
                          enabled: true,
                        ),
                        _buildFeatureTile(
                          icon: Icons.history_rounded,
                          title: 'Riwayat Transaksi Setoran STTS',
                          subtitle:
                              'Pantau riwayat setoran & cetak ulang kwitansi',
                          enabled: true,
                        ),
                      ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Koneksi Server REST API Card (Deployed Production Server)
            _buildSectionCard(
              title: 'Koneksi Server REST API',
              icon: Icons.dns_rounded,
              iconColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target Endpoint Host (Server Deployed)',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                authProvider.currentBaseUrl,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Terhubung',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Informasi Aplikasi Card
            _buildSectionCard(
              title: 'Informasi Aplikasi',
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.textMuted,
              child: Column(
                children: [
                  _buildInfoRow('Versi Aplikasi', 'v1.0.0 (Versi Produksi)'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Hak Cipta / Copyright',
                    'CV. Inital Dhiq Skalaloka',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 6. Action Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context, authProvider),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar dari Akun LENTERA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerBg,
                  foregroundColor: AppColors.danger,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Copyright Text
            const Center(
              child: Text(
                'Copyright © 2026 CV. Inital Dhiq Skalaloka. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Safe spacing for Floating Glass Navigation Dock
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniKpiItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: enabled ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    decoration: enabled ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
