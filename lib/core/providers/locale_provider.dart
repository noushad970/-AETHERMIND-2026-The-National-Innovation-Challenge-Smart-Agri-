import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { bangla, english }

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _loadFromPrefs();
  }

  static const String _prefKey = 'selected_language';
  AppLanguage _language = AppLanguage.bangla;
  AppLanguage get language => _language;

  Locale get locale => _language == AppLanguage.english
      ? const Locale('en', 'US')
      : const Locale('bn', 'BD');

  bool get isBangla => _language == AppLanguage.bangla;
  bool get isEnglish => _language == AppLanguage.english;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'en') {
        _language = AppLanguage.english;
        notifyListeners();
      } else if (saved == 'bn') {
        _language = AppLanguage.bangla;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, lang == AppLanguage.english ? 'en' : 'bn');
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = _language == AppLanguage.bangla
        ? AppLanguage.english
        : AppLanguage.bangla;
    await setLanguage(next);
  }
}

extension LocalizationExtension on BuildContext {
  bool get isBn {
    try {
      return watch<LocaleProvider>().isBangla;
    } catch (_) {
      return true;
    }
  }

  String tr(String en, String bn) => isBn ? bn : en;
}
