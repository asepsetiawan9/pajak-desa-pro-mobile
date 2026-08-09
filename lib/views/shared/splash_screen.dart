import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'main_navigation_screen.dart';
import 'role_denied_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Give a brief smooth visual splash delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (authProvider.isAccessDeniedRole) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleDeniedScreen()),
      );
    } else if (authProvider.isLoggedIn && authProvider.user != null) {
      final user = authProvider.user!;
      if (user.isKolektor || user.isKepalaDesa) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RoleDeniedScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 25,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Lentera Pajak Mobile',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Layanan Elektronik Terpadu Pajak Daerah',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 48),
                const SpinKitFadingCube(
                  color: AppColors.primary,
                  size: 32.0,
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Copyright © 2026 CV. Inital Dhiq Skalaloka',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
