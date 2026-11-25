import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How lively the app interface should be.
///
/// * [animated] – live backgrounds, card animations, pulsing badges.
/// * [staticMode] – same layout and content, but no looping animations.
///   Recommended for low-end phones: it uses much less CPU/GPU and battery.
enum AnimationMode { animated, staticMode }

/// Stores the user's animated / static interface choice.
///
/// The choice is persisted with `shared_preferences`. [hasChosen] is false
/// until the user has picked a mode once (the first-login chooser uses it).
class AnimationModeProvider extends ChangeNotifier {
  AnimationModeProvider({bool loadOnCreate = true}) {
    if (loadOnCreate) {
      _loadFromPrefs();
    } else {
      _loaded = true;
    }
  }

  static const String prefKey = 'ui_animation_mode';
  static const String _valueAnimated = 'animated';
  static const String _valueStatic = 'static';

  AnimationMode _mode = AnimationMode.animated;
  bool _loaded = false;
  bool _hasChosen = false;

  AnimationMode get mode => _mode;
  bool get isAnimated => _mode == AnimationMode.animated;
  bool get isStatic => _mode == AnimationMode.staticMode;

  /// True once the saved preference has been read from disk.
  bool get isLoaded => _loaded;

  /// True once the user has explicitly picked a mode.
  bool get hasChosen => _hasChosen;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved == _valueStatic) {
        _mode = AnimationMode.staticMode;
        _hasChosen = true;
      } else if (saved == _valueAnimated) {
        _mode = AnimationMode.animated;
        _hasChosen = true;
      }
    } catch (_) {
      // Keep defaults if storage is unavailable.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Saves [mode] and marks the choice as made.
  Future<void> setMode(AnimationMode mode) async {
    if (_mode == mode && _hasChosen) return;
    _mode = mode;
    _hasChosen = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefKey,
        mode == AnimationMode.staticMode ? _valueStatic : _valueAnimated,
      );
    } catch (_) {}
  }
}

extension AnimationModeContext on BuildContext {
  /// Whether looping animations should run. Rebuilds the caller when the
  /// user changes the mode. Safe to call from `build` and
  /// `didChangeDependencies`.
  ///
  /// Also false when the OS "remove animations" accessibility setting is on.
  bool get animationsEnabled {
    try {
      final on = Provider.of<AnimationModeProvider>(this).isAnimated;
      if (!on) return false;
      return !(MediaQuery.maybeDisableAnimationsOf(this) ?? false);
    } catch (_) {
      return true;
    }
  }
}
