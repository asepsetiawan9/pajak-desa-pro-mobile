class ApiConstants {
  // Preset Server Options
  static const String defaultLocalAndroidEmulator = 'http://10.0.2.2:8000/api/v1';
  static const String defaultLocalDesktop = 'http://127.0.0.1:8000/api/v1';
  static const String defaultProductionVps = 'http://backend.barudua.initd.web.id/api/v1';
  static const String defaultBaseUrl = defaultProductionVps;

  // Key for local storage
  static const String customBaseUrlKey = 'custom_api_base_url';

  // API Endpoints — Authentication
  static const String loginEndpoint = '/auth/login';
  static const String meEndpoint = '/auth/me';
  static const String logoutEndpoint = '/auth/logout';

  // API Endpoints — DHKP & SPPT
  static const String dhkpEndpoint = '/dhkp';
  static const String summaryMetricsEndpoint = '/dhkp/summary';

  // API Endpoints — Transactions
  static const String transactionsEndpoint = '/transactions';

  // API Endpoints — Reports
  static const String report21ColumnEndpoint = '/reports/21-column';

  // API Endpoints — Multi-Desa Management
  static const String desasEndpoint = '/desas';

  // API Endpoints — Setoran ke Kecamatan
  static const String setoranKecamatanEndpoint = '/setoran-kecamatan';
  static const String setoranKecamatanSummaryEndpoint = '/setoran-kecamatan/summary';

  // API Endpoints — Settings
  static const String settingsEndpoint = '/settings';

  // API Endpoints — Audit Logs
  static const String auditLogsEndpoint = '/audit-logs';
}
