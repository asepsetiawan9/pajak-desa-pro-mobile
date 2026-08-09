import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../kolektor/kolektor_dashboard.dart';
import '../kolektor/dhkp_list_screen.dart';
import '../kolektor/penerimaan_pbb_screen.dart';
import '../kepaladesa/kades_dashboard.dart';
import '../kepaladesa/kades_report_screen.dart';
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
    final user = authProvider.user;

    final isKolektor = user?.isKolektor ?? true;

    // Configure Pages & Nav Items per Role
    final List<Widget> pages = isKolektor
        ? [
            KolektorDashboard(onNavigateTab: _onTabSelected),
            const PenerimaanPbbScreen(),
            const DhkpListScreen(),
            const ProfileScreen(),
          ]
        : [
            const KadesDashboard(),
            const KadesReportScreen(),
            const DhkpListScreen(),
            const ProfileScreen(),
          ];

    final List<NavItemData> navItems = isKolektor
        ? const [
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
          ]
        : const [
            NavItemData(
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
              label: 'Dashboard',
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
