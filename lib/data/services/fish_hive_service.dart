import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/fish_pond.dart';
import '../models/fish_activity.dart';
import '../models/fish_daily_summary.dart';
import '../models/fish_daily_suggestion.dart';

/// Dedicated Local Hive Database Service for Fish Ponds & Aquaculture.
/// Ensures 0ms offline response and seamless background synchronization.
class FishHiveService {
  FishHiveService._();
  static final FishHiveService instance = FishHiveService._();

  static const String _pondsBoxName = 'fish_ponds_box';
  static const String _activitiesBoxName = 'fish_activities_box';
  static const String _summariesBoxName = 'fish_summaries_box';
  static const String _suggestionsBoxName = 'fish_suggestions_box';
  static const String _metaBoxName = 'fish_meta_box';

  Box? _pondsBox;
  Box? _activitiesBox;
  Box? _summariesBox;
  Box? _suggestionsBox;
  Box? _metaBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized && _pondsBox?.isOpen == true) return;
    try {
      _pondsBox = await Hive.openBox(_pondsBoxName);
      _activitiesBox = await Hive.openBox(_activitiesBoxName);
      _summariesBox = await Hive.openBox(_summariesBoxName);
      _suggestionsBox = await Hive.openBox(_suggestionsBoxName);
      _metaBox = await Hive.openBox(_metaBoxName);
      _initialized = true;
      debugPrint('[FishHiveService] Hive boxes initialized successfully.');
    } catch (e) {
      debugPrint('[FishHiveService] Error initializing Hive: $e');
    }
  }

  // --- Fish Ponds ---

  Future<void> savePonds(List<FishPond> ponds) async {
    if (!_initialized || _pondsBox == null) return;
    try {
      final map = <String, String>{};
      for (final p in ponds) {
        map[p.id] = jsonEncode(p.toMap());
      }
      await _pondsBox!.clear();
      await _pondsBox!.putAll(map);
      await _recordChangeEvent('savePonds');
    } catch (e) {
      debugPrint('[FishHiveService] Error savePonds: $e');
    }
  }

  Future<void> savePond(FishPond pond) async {
    if (!_initialized || _pondsBox == null) return;
    try {
      await _pondsBox!.put(pond.id, jsonEncode(pond.toMap()));
      await _recordChangeEvent('savePond_${pond.id}');
    } catch (e) {
      debugPrint('[FishHiveService] Error savePond: $e');
    }
  }

  Future<void> deletePond(String pondId) async {
    if (!_initialized || _pondsBox == null) return;
    try {
      await _pondsBox!.delete(pondId);
      await _activitiesBox?.delete(pondId);
      await _summariesBox?.delete(pondId);
      await _suggestionsBox?.delete(pondId);
      await _recordChangeEvent('deletePond_$pondId');
    } catch (e) {
      debugPrint('[FishHiveService] Error deletePond: $e');
    }
  }

  List<FishPond> getPonds() {
    if (!_initialized || _pondsBox == null) return [];
    try {
      final list = <FishPond>[];
      for (final key in _pondsBox!.keys) {
        final raw = _pondsBox!.get(key);
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            list.add(FishPond.fromMap(Map<String, dynamic>.from(decoded)));
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint('[FishHiveService] Error getPonds: $e');
      return [];
    }
  }

  FishPond? getPond(String pondId) {
    if (!_initialized || _pondsBox == null) return null;
    try {
      final raw = _pondsBox!.get(pondId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return FishPond.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('[FishHiveService] Error getPond: $e');
    }
    return null;
  }

  // --- Activities ---

  Future<void> saveActivities(String pondId, List<FishActivity> activities) async {
    if (!_initialized || _activitiesBox == null) return;
    try {
      final jsonList = activities.map((a) => a.toMap()).toList();
      await _activitiesBox!.put(pondId, jsonEncode(jsonList));
      await _recordChangeEvent('saveActivities_$pondId');
    } catch (e) {
      debugPrint('[FishHiveService] Error saveActivities: $e');
    }
  }

  List<FishActivity> getActivities(String pondId) {
    if (!_initialized || _activitiesBox == null) return [];
    try {
      final raw = _activitiesBox!.get(pondId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => FishActivity.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[FishHiveService] Error getActivities: $e');
    }
    return [];
  }

  // --- Summaries ---

  Future<void> saveDailySummary(FishDailySummary summary) async {
    if (!_initialized || _summariesBox == null) return;
    try {
      final list = getDailySummaries(summary.fishPondId);
      final idx = list.indexWhere((s) => s.id == summary.id);
      if (idx >= 0) {
        list[idx] = summary;
      } else {
        list.add(summary);
      }
      final jsonList = list.map((s) => s.toMap()).toList();
      await _summariesBox!.put(summary.fishPondId, jsonEncode(jsonList));
      await _recordChangeEvent('saveDailySummary_${summary.id}');
    } catch (e) {
      debugPrint('[FishHiveService] Error saveDailySummary: $e');
    }
  }

  List<FishDailySummary> getDailySummaries(String pondId) {
    if (!_initialized || _summariesBox == null) return [];
    try {
      final raw = _summariesBox!.get(pondId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map(
                (e) => FishDailySummary.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[FishHiveService] Error getDailySummaries: $e');
    }
    return [];
  }

  // --- Suggestions ---

  Future<void> saveDailySuggestion(FishDailySuggestion suggestion) async {
    if (!_initialized || _suggestionsBox == null) return;
    try {
      await _suggestionsBox!.put(
        '${suggestion.fishPondId}_${suggestion.id}',
        jsonEncode(suggestion.toMap()),
      );
    } catch (e) {
      debugPrint('[FishHiveService] Error saveDailySuggestion: $e');
    }
  }

  FishDailySuggestion? getDailySuggestion(String pondId, String dateKey) {
    if (!_initialized || _suggestionsBox == null) return null;
    try {
      final raw = _suggestionsBox!.get('${pondId}_$dateKey');
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return FishDailySuggestion.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('[FishHiveService] Error getDailySuggestion: $e');
    }
    return null;
  }

  Future<void> _recordChangeEvent(String eventName) async {
    if (!_initialized || _metaBox == null) return;
    try {
      await _metaBox!.put('last_change_event', eventName);
      await _metaBox!.put('last_change_at', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _pondsBox?.clear();
      await _activitiesBox?.clear();
      await _summariesBox?.clear();
      await _suggestionsBox?.clear();
      await _metaBox?.clear();
    } catch (_) {}
  }
}
