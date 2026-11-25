import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Local settings such as API keys and the server address.
///
/// Values are read from [assetPath], which git ignores, so the app picks them
/// up however it is started. A value passed with `--dart-define` takes
/// priority over the file.
class Env {
  Env._();

  static const String assetPath = 'assets/env/app.env';

  static Map<String, String> _file = const {};

  /// Reads the local settings file. Call once before any key is used.
  static Future<void> load({AssetBundle? bundle}) async {
    try {
      final text = await (bundle ?? rootBundle).loadString(
        assetPath,
        cache: false,
      );
      _file = parse(text);
    } catch (_) {
      _file = const {};
      debugPrint('[Env] $assetPath not found. See "Setup" in README.md.');
    }
  }

  /// [defined] is the `--dart-define` value, empty when none was passed.
  static String value(String key, String defined, {String fallback = ''}) {
    if (defined.isNotEmpty) return defined;
    final fromFile = _file[key] ?? '';
    return fromFile.isNotEmpty ? fromFile : fallback;
  }

  /// Parses `KEY=VALUE` lines. Blank lines and `#` comments are skipped.
  @visibleForTesting
  static Map<String, String> parse(String text) {
    final result = <String, String>{};
    for (final raw in text.split('\n')) {
      final line = raw.replaceAll('﻿', '').trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final split = line.indexOf('=');
      if (split <= 0) continue;
      var value = line.substring(split + 1).trim();
      if (value.length >= 2 &&
          (value.startsWith('"') && value.endsWith('"') ||
              value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      result[line.substring(0, split).trim()] = value;
    }
    return result;
  }
}
