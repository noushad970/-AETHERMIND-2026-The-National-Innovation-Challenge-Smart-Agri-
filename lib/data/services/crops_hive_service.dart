import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/crop.dart';
import '../models/crop_activity.dart';
import '../models/daily_suggestion.dart';

/// Dedicated Local Hive Database Service for Crops and Agronomy features.
/// Provides instant 0ms offline hydration and offline sync persistence.
class CropsHiveService {
  CropsHiveService._();
  static final CropsHiveService instance = CropsHiveService._();

  static const String _cropsBoxName = 'crops_box';
  static const String _activitiesBoxName = 'crop_activities_box';
  static const String _suggestionsBoxName = 'crop_suggestions_box';
  static const String _metaBoxName = 'crop_meta_box';

  Box? _cropsBox;
  Box? _activitiesBox;
  Box? _suggestionsBox;
  Box? _metaBox;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized && _cropsBox?.isOpen == true) return;
    try {
      _cropsBox = await Hive.openBox(_cropsBoxName);
      _activitiesBox = await Hive.openBox(_activitiesBoxName);
      _suggestionsBox = await Hive.openBox(_suggestionsBoxName);
      _metaBox = await Hive.openBox(_metaBoxName);
      _initialized = true;
      debugPrint('[CropsHiveService] Hive boxes initialized successfully.');
    } catch (e) {
      debugPrint('[CropsHiveService] Error initializing Hive: $e');
    }
  }

  // --- Crops ---

  Future<void> saveCrops(List<Crop> crops) async {
    if (!_initialized || _cropsBox == null) return;
    try {
      final map = <String, String>{};
      for (final c in crops) {
        map[c.id] = jsonEncode(c.toMap());
      }
      await _cropsBox!.clear();
      await _cropsBox!.putAll(map);
      await _recordChangeEvent('saveCrops');
    } catch (e) {
      debugPrint('[CropsHiveService] Error saveCrops: $e');
    }
  }

  Future<void> saveCrop(Crop crop) async {
    if (!_initialized || _cropsBox == null) return;
    try {
      await _cropsBox!.put(crop.id, jsonEncode(crop.toMap()));
      await _recordChangeEvent('saveCrop_${crop.id}');
    } catch (e) {
      debugPrint('[CropsHiveService] Error saveCrop: $e');
    }
  }

  Future<void> deleteCrop(String cropId) async {
    if (!_initialized || _cropsBox == null) return;
    try {
      await _cropsBox!.delete(cropId);
      await _activitiesBox?.delete(cropId);
      await _suggestionsBox?.delete(cropId);
      await _recordChangeEvent('deleteCrop_$cropId');
    } catch (e) {
      debugPrint('[CropsHiveService] Error deleteCrop: $e');
    }
  }

  List<Crop> getCrops() {
    if (!_initialized || _cropsBox == null) return [];
    try {
      final list = <Crop>[];
      for (final key in _cropsBox!.keys) {
        final raw = _cropsBox!.get(key);
        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            list.add(Crop.fromMap(Map<String, dynamic>.from(decoded)));
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint('[CropsHiveService] Error getCrops: $e');
      return [];
    }
  }

  Crop? getCrop(String id) {
    if (!_initialized || _cropsBox == null) return null;
    try {
      final raw = _cropsBox!.get(id);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Crop.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('[CropsHiveService] Error getCrop: $e');
    }
    return null;
  }

  // --- Activities ---

  Future<void> saveActivities(String cropId, List<CropActivity> activities) async {
    if (!_initialized || _activitiesBox == null) return;
    try {
      final jsonList = activities.map((a) => a.toMap()).toList();
      await _activitiesBox!.put(cropId, jsonEncode(jsonList));
      await _recordChangeEvent('saveActivities_$cropId');
    } catch (e) {
      debugPrint('[CropsHiveService] Error saveActivities: $e');
    }
  }

  List<CropActivity> getActivities(String cropId) {
    if (!_initialized || _activitiesBox == null) return [];
    try {
      final raw = _activitiesBox!.get(cropId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => CropActivity.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[CropsHiveService] Error getActivities: $e');
    }
    return [];
  }

  // --- Daily Suggestions ---

  Future<void> saveDailySuggestion(DailySuggestion suggestion) async {
    if (!_initialized || _suggestionsBox == null) return;
    try {
      await _suggestionsBox!.put(
        '${suggestion.cropId}_${suggestion.dateKey}',
        jsonEncode(suggestion.toMap()),
      );
    } catch (e) {
      debugPrint('[CropsHiveService] Error saveDailySuggestion: $e');
    }
  }

  DailySuggestion? getDailySuggestion(String cropId, String dateKey) {
    if (!_initialized || _suggestionsBox == null) return null;
    try {
      final raw = _suggestionsBox!.get('${cropId}_$dateKey');
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return DailySuggestion.fromMap(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('[CropsHiveService] Error getDailySuggestion: $e');
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
      await _cropsBox?.clear();
      await _activitiesBox?.clear();
      await _suggestionsBox?.clear();
      await _metaBox?.clear();
    } catch (_) {}
  }
}
