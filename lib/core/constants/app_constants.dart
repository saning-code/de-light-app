/// ─────────────────────────────────────────────────────────────────────────
/// App-wide constants and environment configuration.
///
/// HOW TO SWITCH ENVIRONMENTS:
///   Development : flutter run --dart-define=ENV=dev
///   Staging     : flutter run --dart-define=ENV=staging
///   Production  : flutter run --dart-define=ENV=prod
///               : flutter build apk --dart-define=ENV=prod --release
/// ─────────────────────────────────────────────────────────────────────────

class AppEnv {
  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isDev => _env == 'dev';
  static bool get isStaging => _env == 'staging';
  static bool get isProd => _env == 'prod';

  /// API base URL — set your Railway/Render URL here for production.
  static String get apiBaseUrl {
    switch (_env) {
      case 'prod':
        // ✅ Live API on Render
        return 'https://de-light-api.onrender.com/api/v1';
      case 'staging':
        return 'https://de-light-api-staging.up.railway.app/api/v1';
      case 'dev':
      default:
        // Android emulator → 10.0.2.2 maps to PC localhost
        // Real device on same WiFi → replace with your PC's LAN IP
        // Web (Chrome) → localhost
        return _devUrl;
    }
  }

  static const String _devUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000/api/v1');
}

class AppConstants {
  // ─── API ──────────────────────────────────────────────────────────────────
  static String get baseUrl => AppEnv.apiBaseUrl;

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName = 'De-Light';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Business Manager';

  // ─── Secure Storage Keys ──────────────────────────────────────────────────
  static const String kJwtToken   = 'jwt_token';
  static const String kUserJson   = 'user_json';
  static const String kTenantJson = 'tenant_json';
  static const String kShopJson   = 'shop_json';
  static const String kLastSynced = 'last_synced_at';
  static const String kThemeMode  = 'theme_mode';

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int defaultPerPage = 20;

  // ─── Timeouts ─────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ─── Payment Methods ──────────────────────────────────────────────────────
  static const List<String> paymentMethods = [
    'cash', 'momo', 'card', 'bank', 'credit', 'split',
  ];

  static const Map<String, String> paymentLabels = {
    'cash':   'Cash',
    'momo':   'MTN MoMo / Telecel',
    'card':   'Card',
    'bank':   'Bank Transfer',
    'credit': 'Credit (Pay Later)',
    'split':  'Split Payment',
  };

  static const Map<String, String> paymentIcons = {
    'cash':   '💵',
    'momo':   '📱',
    'card':   '💳',
    'bank':   '🏦',
    'credit': '📋',
    'split':  '✂️',
  };
}
