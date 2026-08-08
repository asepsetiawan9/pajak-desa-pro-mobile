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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'LENTERA',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pajak Desa Pro Mobile',
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
    );
  }
}
