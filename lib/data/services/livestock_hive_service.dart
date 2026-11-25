import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/animal.dart';
import '../models/livestock_daily_summary.dart';
import '../models/livestock_daily_suggestion.dart';

/// Dedicated Local Hive Database Service exclusively for Livestock and Poultry.
///
/// Provides instant offline-first hydration and persists:
///   1. Livestock/Poultry Groups ([Animal])
///   2. Activities & Scheduled Checklists ([LivestockActivity])
///   3. Daily Production Summaries ([LivestockDailySummary] - eggs, milk, feed, deaths)
///   4. AI Daily Suggestions ([LivestockDailySuggestion])
///   5. Daily Sync Timestamps and change event markers
class LivestockHiveService {
  LivestockHiveService._();
  static final LivestockHiveService instance = LivestockHiveService._();

  static const String _animalsBoxName = 'livestock_animals_box';
  static const String _activitiesBoxName = 'livestock_activities_box';
  static const String _summariesBoxName = 'livestock_summaries_box';
  static const String _suggestionsBoxName = 'livestock_suggestions_box';
  static const String _metaBoxName = 'livestock_meta_box';

  Box? _animalsBox;
  Box? _activitiesBox;
  Box? _summariesBox;
  Box? _suggestionsBox;
  Box? _metaBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initializes Hive storage and opens all dedicated livestock boxes.
  Future<void> init() async {
    if (_initialized && _animalsBox?.isOpen == true) return;
    try {
      _animalsBox = await Hive.openBox(_animalsBoxName);
      _activitiesBox = await Hive.openBox(_activitiesBoxName);
      _summariesBox = await Hive.openBox(_summariesBoxName);
      _suggestionsBox = await Hive.openBox(_suggestionsBoxName);
      _metaBox = await Hive.openBox(_metaBoxName);
      _initialized = true;
      debugPrint('[LivestockHiveService] Hive boxes initialized successfully.');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error initializing Hive: $e');
    }
  }

  // ==========================================
  // Animals (Livestock / Poultry Groups)
  // ==========================================

  /// Saves a list of animals into the local Hive database.
  Future<void> saveAnimals(List<Animal> animals) async {
    if (!_initialized || _animalsBox == null) return;
    try {
      final map = <String, String>{};
      for (final a in animals) {
        map[a.id] = jsonEncode(a.toMap());
      }
      await _animalsBox!.clear();
      await _animalsBox!.putAll(map);
      await recordChangeEvent('saveAnimals');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveAnimals: $e');
    }
  }

  /// Upserts a single animal in Hive.
  Future<void> saveAnimal(Animal animal) async {
    if (!_initialized || _animalsBox == null) return;
    try {
      await _animalsBox!.put(animal.id, jsonEncode(animal.toMap()));
      await recordChangeEvent('saveAnimal_${animal.id}');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveAnimal: $e');
    }
  }

  /// Deletes an animal and cleans up its child data from Hive.
  Future<void> deleteAnimal(String animalId) async {
    if (!_initialized || _animalsBox == null) return;
    try {
      await _animalsBox!.delete(animalId);
      await _activitiesBox?.delete(animalId);
      await _summariesBox?.delete(animalId);
      await _suggestionsBox?.delete(animalId);
      await recordChangeEvent('deleteAnimal_$animalId');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error deleteAnimal: $e');
    }
  }

  /// Retrieves all cached livestock/poultry groups from Hive.
  List<Animal> getAnimals() {
    if (!_initialized || _animalsBox == null) return [];
    try {
      final list = <Animal>[];
      for (final key in _animalsBox!.keys) {
        final raw = _animalsBox!.get(key);
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            list.add(Animal.fromMap(Map<String, dynamic>.from(decoded)));
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint('[LivestockHiveService] Error getAnimals: $e');
      return [];
    }
  }

  /// Retrieves a single animal by ID from Hive.
  Animal? getAnimal(String animalId) {
    if (!_initialized || _animalsBox == null) return null;
    try {
      final raw = _animalsBox!.get(animalId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Animal.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('[LivestockHiveService] Error getAnimal: $e');
    }
    return null;
  }

  // ==========================================
  // Activities & Tasks
  // ==========================================

  /// Saves activities for a specific animal into Hive.
  Future<void> saveActivities(
    String animalId,
    List<LivestockActivity> activities,
  ) async {
    if (!_initialized || _activitiesBox == null) return;
    try {
      final jsonList = activities.map((a) => a.toMap()).toList();
      await _activitiesBox!.put(animalId, jsonEncode(jsonList));
      await recordChangeEvent('saveActivities_$animalId');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveActivities: $e');
    }
  }

  /// Upserts or toggles a single activity in Hive for an animal.
  Future<void> saveActivity(LivestockActivity activity) async {
    if (!_initialized || _activitiesBox == null) return;
    try {
      final current = getActivities(activity.animalId);
      final idx = current.indexWhere((a) => a.id == activity.id);
      if (idx >= 0) {
        current[idx] = activity;
      } else {
        current.add(activity);
      }
      await saveActivities(activity.animalId, current);
      await recordChangeEvent('saveActivity_${activity.id}');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveActivity: $e');
    }
  }

  /// Retrieves all cached activities for an animal from Hive.
  List<LivestockActivity> getActivities(String animalId) {
    if (!_initialized || _activitiesBox == null) return [];
    try {
      final raw = _activitiesBox!.get(animalId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map(
                (e) => LivestockActivity.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[LivestockHiveService] Error getActivities: $e');
    }
    return [];
  }

  // ==========================================
  // Daily Summaries
  // ==========================================

  /// Saves daily summaries for an animal into Hive.
  Future<void> saveDailySummaries(
    String animalId,
    List<LivestockDailySummary> summaries,
  ) async {
    if (!_initialized || _summariesBox == null) return;
    try {
      final jsonList = summaries.map((s) => s.toMap()).toList();
      await _summariesBox!.put(animalId, jsonEncode(jsonList));
      await recordChangeEvent('saveDailySummaries_$animalId');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveDailySummaries: $e');
    }
  }

  /// Upserts a single daily summary into Hive.
  Future<void> saveDailySummary(LivestockDailySummary summary) async {
    if (!_initialized || _summariesBox == null) return;
    try {
      final current = getDailySummaries(summary.animalId);
      final idx = current.indexWhere((s) => s.dateKey == summary.dateKey);
      if (idx >= 0) {
        current[idx] = summary;
      } else {
        current.add(summary);
      }
      await saveDailySummaries(summary.animalId, current);
      await recordChangeEvent('saveDailySummary_${summary.dateKey}');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveDailySummary: $e');
    }
  }

  /// Retrieves daily summaries for an animal from Hive.
  List<LivestockDailySummary> getDailySummaries(String animalId) {
    if (!_initialized || _summariesBox == null) return [];
    try {
      final raw = _summariesBox!.get(animalId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map(
                (e) => LivestockDailySummary.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[LivestockHiveService] Error getDailySummaries: $e');
    }
    return [];
  }

  // ==========================================
  // AI Daily Suggestions
  // ==========================================

  /// Saves AI daily suggestions for an animal into Hive.
  Future<void> saveDailySuggestions(
    String animalId,
    List<LivestockDailySuggestion> suggestions,
  ) async {
    if (!_initialized || _suggestionsBox == null) return;
    try {
      final jsonList = suggestions.map((s) => s.toMap()).toList();
      await _suggestionsBox!.put(animalId, jsonEncode(jsonList));
      await recordChangeEvent('saveDailySuggestions_$animalId');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveDailySuggestions: $e');
    }
  }

  /// Upserts a single AI daily suggestion in Hive.
  Future<void> saveDailySuggestion(LivestockDailySuggestion suggestion) async {
    if (!_initialized || _suggestionsBox == null) return;
    try {
      final current = getDailySuggestions(suggestion.animalId);
      final idx = current.indexWhere((s) => s.dateKey == suggestion.dateKey);
      if (idx >= 0) {
        current[idx] = suggestion;
      } else {
        current.insert(0, suggestion);
      }
      await saveDailySuggestions(suggestion.animalId, current);
      await recordChangeEvent('saveDailySuggestion_${suggestion.dateKey}');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error saveDailySuggestion: $e');
    }
  }

  /// Retrieves AI daily suggestions for an animal from Hive.
  List<LivestockDailySuggestion> getDailySuggestions(String animalId) {
    if (!_initialized || _suggestionsBox == null) return [];
    try {
      final raw = _suggestionsBox!.get(animalId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map(
                (e) => LivestockDailySuggestion.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[LivestockHiveService] Error getDailySuggestions: $e');
    }
    return [];
  }

  // ==========================================
  // Daily Sync & Change Event Tracking
  // ==========================================

  /// Checks if a daily sync with Firebase Firestore is needed for today.
  bool isDailySyncNeededToday() {
    if (!_initialized || _metaBox == null) return true;
    final lastSyncStr = _metaBox!.get('last_daily_sync_date');
    if (lastSyncStr is String) {
      final todayKey = LivestockDailySummary.dateKeyFor(DateTime.now());
      return lastSyncStr != todayKey;
    }
    return true;
  }

  /// Marks today as synced in the local Hive metadata.
  Future<void> recordDailySyncCompleted() async {
    if (!_initialized || _metaBox == null) return;
    final todayKey = LivestockDailySummary.dateKeyFor(DateTime.now());
    await _metaBox!.put('last_daily_sync_date', todayKey);
    await _metaBox!.put('last_sync_timestamp', DateTime.now().toIso8601String());
  }

  /// Records an immediate change event marker (e.g. task completed, death recorded).
  Future<void> recordChangeEvent(String eventName) async {
    if (!_initialized || _metaBox == null) return;
    try {
      await _metaBox!.put('last_change_event', eventName);
      await _metaBox!.put('last_change_at', DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Clears all local livestock Hive boxes upon user logout.
  Future<void> clearAll() async {
    try {
      await _animalsBox?.clear();
      await _activitiesBox?.clear();
      await _summariesBox?.clear();
      await _suggestionsBox?.clear();
      await _metaBox?.clear();
      debugPrint('[LivestockHiveService] Cleared all local Hive livestock data.');
    } catch (e) {
      debugPrint('[LivestockHiveService] Error clearAll: $e');
    }
  }
}
