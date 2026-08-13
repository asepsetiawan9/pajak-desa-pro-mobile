import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dhkp_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/summary_provider.dart';
import 'providers/desa_filter_provider.dart';
import 'providers/setoran_kecamatan_provider.dart';
import 'providers/settings_provider.dart';
import 'views/shared/error_boundary.dart';
import 'views/shared/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Custom Error Boundary Handler for Production Resilience
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(details: details);
  };
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Global Error Captured: ${details.exception}');
  };

  runApp(const PajakMobileApp());
}

class PajakMobileApp extends StatelessWidget {
  const PajakMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DhkpProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
        ChangeNotifierProvider(create: (_) => DesaFilterProvider()),
        ChangeNotifierProvider(create: (_) => SetoranKecamatanProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService.navigatorKey,
        title: 'Lentera Pajak Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
