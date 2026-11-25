import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused }

class BanglaTtsService {
  factory BanglaTtsService() => _instance;
  BanglaTtsService._internal() {
    _initFuture = _initTts();
  }

  static final BanglaTtsService _instance = BanglaTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  Future<void>? _initFuture;
  bool _initialized = false;

  TtsState _state = TtsState.stopped;
  TtsState get state => _state;
  bool get isSpeaking => _state == TtsState.playing;

  final ValueNotifier<TtsState> stateNotifier = ValueNotifier(TtsState.stopped);
  String? _currentlySpeakingText;
  String? get currentlySpeakingText => _currentlySpeakingText;

  bool isSpeakingText(String text) {
    if (_state != TtsState.playing) return false;
    final clean = cleanMarkdownText(text);
    return _currentlySpeakingText == clean;
  }

  Future<void> _initTts() async {
    try {
      if (Platform.isAndroid) {
        // Prefer Google TTS engine for superior Bangla phonetics
        try {
          final engines = await _flutterTts.getEngines;
          if (engines is List && engines.contains('com.google.android.tts')) {
            await _flutterTts.setEngine('com.google.android.tts');
          }
        } catch (e) {
          developer.log('Engine selection error: $e', name: 'BanglaTtsService');
        }

        await _flutterTts.awaitSynthCompletion(true);
        await _flutterTts.awaitSpeakCompletion(true);
      } else if (Platform.isIOS) {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }

      await _flutterTts.setSpeechRate(0.45); // Clear & slow for elderly/farmers
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Best effort to select Bangla voice engine
      try {
        final languages = await _flutterTts.getLanguages;
        if (languages is List) {
          if (languages.contains('bn-BD') || languages.contains('bn_BD')) {
            await _flutterTts.setLanguage('bn-BD');
          } else if (languages.contains('bn-IN') || languages.contains('bn_IN')) {
            await _flutterTts.setLanguage('bn-IN');
          } else if (languages.contains('bn')) {
            await _flutterTts.setLanguage('bn');
          } else {
            await _flutterTts.setLanguage('bn-BD');
          }
        } else {
          await _flutterTts.setLanguage('bn-BD');
        }
      } catch (_) {
        await _flutterTts.setLanguage('bn');
      }

      _flutterTts.setStartHandler(() {
        _state = TtsState.playing;
        stateNotifier.value = TtsState.playing;
      });

      _flutterTts.setCompletionHandler(() {
        _state = TtsState.stopped;
        stateNotifier.value = TtsState.stopped;
        _currentlySpeakingText = null;
      });

      _flutterTts.setCancelHandler(() {
        _state = TtsState.stopped;
        stateNotifier.value = TtsState.stopped;
        _currentlySpeakingText = null;
      });

      _flutterTts.setErrorHandler((msg) {
        developer.log('TTS Error: $msg', name: 'BanglaTtsService');
        _state = TtsState.stopped;
        stateNotifier.value = TtsState.stopped;
        _currentlySpeakingText = null;
      });

      _initialized = true;
    } catch (e) {
      developer.log('Failed to init BanglaTtsService: $e', name: 'BanglaTtsService');
    }
  }

  Future<void> _ensureReady() async {
    if (!_initialized && _initFuture != null) {
      await _initFuture;
    }
  }

  /// Speaks the given Bangla text aloud. If the exact same text is currently playing, it stops.
  Future<void> speak(String text) async {
    final cleanText = cleanMarkdownText(text);
    if (cleanText.trim().isEmpty) return;

    if (_state == TtsState.playing && _currentlySpeakingText == cleanText) {
      await stop();
      return;
    }

    await stop(); // stop any active speech first
    await _ensureReady();

    _currentlySpeakingText = cleanText;
    _state = TtsState.playing;
    stateNotifier.value = TtsState.playing;

    try {
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setSpeechRate(0.45);
      final result = await _flutterTts.speak(cleanText);
      developer.log('TTS speak result: $result for text length ${cleanText.length}', name: 'BanglaTtsService');
    } catch (e) {
      developer.log('Tts speak error: $e', name: 'BanglaTtsService');
      _state = TtsState.stopped;
      stateNotifier.value = TtsState.stopped;
      _currentlySpeakingText = null;
    }
  }

  /// Stops current speech output.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      developer.log('Tts stop error: $e', name: 'BanglaTtsService');
    } finally {
      _state = TtsState.stopped;
      stateNotifier.value = TtsState.stopped;
      _currentlySpeakingText = null;
    }
  }

  /// Utility function to strip markdown symbols (`**`, `#`, `*`, `_`, `[`, `]`, `(`, `)`)
  /// so voice output reads clean, human-like speech.
  static String cleanMarkdownText(String text) {
    return text
        .replaceAll(RegExp(r'\*\*|\*|#+|__|_|`|>'), ' ')
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)\s*'), r'\1')
        .replaceAll(RegExp(r'\n+'), '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
