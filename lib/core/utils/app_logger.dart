import 'dart:developer' as developer;

/// Minimal logger facade. On Flutter, `developer.log` shows up in the
/// IDE's debug console (DevTools, Android Studio Logcat, Xcode
/// console) with a `name:` filter.
class AppLogger {
  AppLogger._();

  static void d(String message, {String name = 'App', Object? extra}) {
    developer.log(message, name: name);
    if (extra != null) developer.log(extra.toString(), name: name);
  }

  static void i(String message, {String name = 'App'}) {
    developer.log(message, name: name, level: 800);
  }

  static void w(String message, {String name = 'App'}) {
    developer.log(message, name: name, level: 900);
  }

  static void e(
    String message, {
    Object? error,
    StackTrace? stack,
    String name = 'App',
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stack,
    );
  }
}
