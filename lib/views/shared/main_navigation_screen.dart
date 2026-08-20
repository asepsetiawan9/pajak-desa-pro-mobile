import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../kolektor/kolektor_dashboard.dart';
import '../kolektor/dhkp_list_screen.dart';
import '../kolektor/penerimaan_pbb_screen.dart';
import '../kepaladesa/kades_dashboard.dart';
import '../kepaladesa/kades_report_screen.dart';
import '../kepaladesa/kades_setoran_screen.dart';
import '../admin_kecamatan/admin_dashboard.dart';
import '../admin_kecamatan/monitoring_screen.dart';
import '../admin_kecamatan/setoran_screen.dart';
import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'custom_bottom_nav.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authProvider.user;

    final isKolektor = user?.isKolektor ?? true;
    final isSuperAdminSystem = user?.isSuperAdminSystem ?? false;

    // Configure Pages & Nav Items per Role
    final List<Widget> pages;
    final List<NavItemData> navItems;

    if (isSuperAdminSystem) {
      // Admin Kecamatan — Dashboard, Monitoring, Setoran, Profil
      pages = [
        AdminDashboard(onNavigateTab: _onTabSelected),
        const MonitoringScreen(),
        const SetoranScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        NavItemData(
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          label: 'Dashboard',
        ),
        NavItemData(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          label: 'Monitoring',
        ),
        NavItemData(
          icon: Icons.verified_outlined,
          activeIcon: Icons.verified_rounded,
          label: 'Verif Setor',
        ),
        NavItemData(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
        ),
      ];
    } else if (isKolektor) {
      // Kolektor — Beranda, Penerimaan, Data DHKP, Profil
      pages = [
        KolektorDashboard(onNavigateTab: _onTabSelected),
        const PenerimaanPbbScreen(),
        const DhkpListScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        NavItemData(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Beranda',
        ),
        NavItemData(
          icon: Icons.point_of_sale_outlined,
          activeIcon: Icons.point_of_sale_rounded,
          label: 'Penerimaan',
        ),
        NavItemData(
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          label: 'Data DHKP',
        ),
        NavItemData(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
        ),
      ];
    } else {
      // Kepala Desa — Dashboard, Setoran, Rekap Dusun, DHKP, Profil
      pages = [
        KadesDashboard(onNavigateTab: _onTabSelected),
        const KadesSetoranScreen(),
        const KadesReportScreen(),
        const DhkpListScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        NavItemData(
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          label: 'Dashboard',
        ),
        NavItemData(
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
          label: 'Pengeluaran',
        ),
        NavItemData(
          icon: Icons.table_chart_outlined,
          activeIcon: Icons.table_chart_rounded,
          label: 'Rekap Dusun',
        ),
        NavItemData(
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          label: 'DHKP',
        ),
        NavItemData(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
        ),
      ];
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex.clamp(0, pages.length - 1),
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex.clamp(0, pages.length - 1),
        onTap: _onTabSelected,
        items: navItems,
      ),
    );
  }
}
