class ApiConstants {
  // Preset Server Options
  static const String defaultLocalAndroidEmulator = 'http://10.0.2.2:8000/api/v1';
  static const String defaultLocalDesktop = 'http://127.0.0.1:8000/api/v1';
  static const String defaultProductionVps = 'http://backend.barudua.initd.web.id/api/v1';
  static const String defaultBaseUrl = defaultProductionVps;

  // Key for local storage
  static const String customBaseUrlKey = 'custom_api_base_url';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String meEndpoint = '/auth/me';
  static const String logoutEndpoint = '/auth/logout';

  static const String dhkpEndpoint = '/dhkp';
  static const String transactionsEndpoint = '/transactions';
  static const String summaryMetricsEndpoint = '/dhkp/summary';
  static const String report21ColumnEndpoint = '/reports/21-column';
}
