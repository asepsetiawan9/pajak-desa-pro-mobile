import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class RoleDeniedScreen extends StatelessWidget {
  const RoleDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role.toUpperCase() ?? 'ADMIN / BENDAHARA';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.danger.withOpacity(0.5), width: 2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Akses Terbatas',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      color: AppColors.danger,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Role Anda: $userRole',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi Mobile LENTERA khusus diperuntukkan bagi Kolektor dan Kepala Desa untuk kegiatan penagihan & pemantauan di lapangan.\n\nAkun Super Admin dan Bendahara diimbau menggunakan Portal Web Desktop.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Kembali ke Halaman Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceCard,
                    foregroundColor: AppColors.textPrimary,
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
