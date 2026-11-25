import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../data/models/disease_result.dart';
import '../../../../data/services/backend_api_service.dart';
import '../../../../data/services/disease_history_hive_service.dart';
import '../../../../data/services/gemini_service.dart';

/// Orchestrates crop disease detection.
/// 
/// Requests are sent directly to the dedicated Smart Agri cPanel backend server,
/// which keeps the Gemini API key safe, strictly enforces the 2-images/day limitation,
/// and returns sequential step-by-step guidance in both English and Bangla.
/// 
/// Results are persisted to local Hive storage for 0ms instant offline viewing.
class DiseaseDetectionProvider extends ChangeNotifier {
  DiseaseDetectionProvider({
    BackendApiService? backendApi,
    GeminiService? gemini,
  })  : _backend = backendApi ?? BackendApiService(),
        _gemini = gemini ?? GeminiService() {
    loadCachedHistory();
  }

  final BackendApiService _backend;
  final GeminiService _gemini;

  Uint8List? _bytes;
  String _filename = '';
  DiseaseResult? _result;
  bool _loading = false;
  String? _error;
  String? _errorBn;

  DailyLimitInfo? _limitInfo;
  List<DiseaseResult> _history = [];

  Uint8List? get imageBytes => _bytes;
  String get filename => _filename;
  DiseaseResult? get result => _result;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get errorBn => _errorBn;

  int get remainingScans => _limitInfo?.remaining ?? 2;
  int get dailyLimit => _limitInfo?.limit ?? 2;
  bool get canUpload => remainingScans > 0;
  List<DiseaseResult> get history => _history;

  /// True when the backend server is configured or direct Gemini key is available.
  bool get isCloudConfigured => true;

  String _getEffectiveUserId() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      return firebaseUser.uid;
    }
    return 'local_farmer';
  }

  /// Loads cached scan history and daily quota from local Hive database.
  void loadCachedHistory() {
    try {
      _history = DiseaseHistoryHiveService.instance.getScans();
      final cachedLimit = DiseaseHistoryHiveService.instance.getCachedDailyLimit();
      if (cachedLimit != null) {
        final used = (cachedLimit['used'] ?? 0) as int;
        final remaining = (cachedLimit['remaining'] ?? 2) as int;
        _limitInfo = DailyLimitInfo(
          limit: 2,
          used: used,
          remaining: remaining,
          canUpload: remaining > 0,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[DiseaseDetectionProvider] Error loading cached history: $e');
    }
  }

  /// Refreshes user quota from the dedicated backend server.
  Future<void> refreshQuota() async {
    try {
      final userId = _getEffectiveUserId();
      _limitInfo = await _backend.getDailyLimitStatus(userId);
      _history = DiseaseHistoryHiveService.instance.getScans();
      notifyListeners();
    } catch (e) {
      debugPrint('[DiseaseDetectionProvider] refreshQuota error: $e');
    }
  }

  void setImage(Uint8List? bytes, {String filename = ''}) {
    _bytes = bytes;
    _filename = filename;
    _result = null;
    _error = null;
    _errorBn = null;
    notifyListeners();
  }

  /// Sets a previous result from history for instant display without re-scanning.
  void selectFromHistory(DiseaseResult r) {
    _result = r;
    _bytes = null;
    _error = null;
    _errorBn = null;
    notifyListeners();
  }

  Future<void> detect() async {
    if (_bytes == null) return;
    _loading = true;
    _error = null;
    _errorBn = null;
    notifyListeners();

    final userId = _getEffectiveUserId();

    try {
      // 1. Send to dedicated Smart Agri cPanel backend
      _result = await _backend.detectDisease(
        bytes: _bytes!,
        filename: _filename,
        userId: userId,
      );

      // Refresh quota and history after successful scan
      await refreshQuota();
    } on DailyLimitExceededException catch (e) {
      _error = e.message;
      _errorBn = e.messageBn;
      _limitInfo = DailyLimitInfo(
        limit: e.limit,
        used: e.used,
        remaining: e.remaining,
        canUpload: false,
      );
    } catch (e) {
      debugPrint('[DiseaseDetectionProvider] Backend call error: $e. Attempting direct fallback...');
      // 2. Direct fallback if backend temporarily unreachable
      if (_gemini.isConfigured) {
        try {
          _result = await _gemini.detectDiseaseBytes(_bytes!, filename: _filename);
          await DiseaseHistoryHiveService.instance.saveScan(_result!);
          loadCachedHistory();
        } on GeminiException catch (ge) {
          _error = ge.message;
        } catch (fallbackErr) {
          _error = 'সার্ভারে সংযোগ করা যায়নি: $fallbackErr';
        }
      } else {
        _error = e.toString();
        _errorBn = 'সার্ভার থেকে রোগ বিশ্লেষণ সম্পন্ন করা যায়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void reset() {
    _bytes = null;
    _filename = '';
    _result = null;
    _error = null;
    _errorBn = null;
    notifyListeners();
  }
}
