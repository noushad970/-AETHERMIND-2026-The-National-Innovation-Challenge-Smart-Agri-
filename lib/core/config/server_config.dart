/// Dedicated Backend Server Configuration for Smart Agri
/// 
/// Communicates with the cPanel hosted SmartAgriServer backend
/// which securely handles AI processing, API keys, rate limits, and database sync.
class ServerConfig {
  ServerConfig._();

  /// Base URL of your dedicated Smart Agri cPanel backend.
  /// Points to public_html/SmartAgriServer/api
  /// 
  /// You can override this at build or runtime with:
  /// flutter run --dart-define=SERVER_BASE_URL=https://yourdomain.com/SmartAgriServer/api
  static const String baseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: '',
  );

  /// App Secret Header sent to the backend server to authenticate requests.
  /// Matches config.php on the server.
  static const String appSecret = String.fromEnvironment(
    'SMART_AGRI_SECRET',
    defaultValue: '',
  );

  /// Maximum crop disease images allowed per user per day.
  static const int maxDailyDiseaseScans = 2;

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 45);
}
