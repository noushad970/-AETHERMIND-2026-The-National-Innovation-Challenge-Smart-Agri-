/// App-wide configuration constants. Most build-time values live here so they
/// can be tuned without touching feature code.
class AppConfig {
  AppConfig._();

  static const String appVersion = '1.0.0';
  static const String companyName = 'Smart Agri AI';

  // Feature flags
  static const bool enableBanglaVoice = true;
  static const bool enableFirebaseSync = true;
  static const bool enableOfflineGuides = true;

  // Weather
  static const int weatherForecastDays = 7;
  static const Duration weatherCacheTtl = Duration(hours: 1);

  // Disease detection
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10 MB

  // Chatbot
  static const int maxChatHistoryMessages = 50;
}
