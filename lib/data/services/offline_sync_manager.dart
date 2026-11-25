import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'crops_hive_service.dart';
import 'fish_hive_service.dart';
import 'livestock_hive_service.dart';
import 'chat_hive_service.dart';
import 'disease_history_hive_service.dart';
import 'firestore_sync_service.dart';
import 'network_monitor_service.dart';

/// Central manager for local Hive storage and bidirectional online Firestore synchronization.
class OfflineSyncManager extends ChangeNotifier {
  OfflineSyncManager._();
  static final OfflineSyncManager instance = OfflineSyncManager._();

  final FirestoreSyncService _firestoreSync = FirestoreSyncService();
  final NetworkMonitorService _networkMonitor = NetworkMonitorService.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _initialized = false;

  /// Initializes all dedicated local Hive databases and starts network listeners.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize all Hive services
    await CropsHiveService.instance.init();
    await FishHiveService.instance.init();
    await LivestockHiveService.instance.init();
    await ChatHiveService.instance.init();
    await DiseaseHistoryHiveService.instance.init();

    // Listen to network changes for auto-sync when online
    _networkMonitor.onConnectionChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('[OfflineSyncManager] Internet restored: starting auto-sync...');
        syncAllNow();
      }
    });
  }

  /// Pushes any pending offline local Hive updates to Cloud Firestore
  /// and updates local caches.
  Future<void> syncAllNow() async {
    if (_isSyncing) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_networkMonitor.isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('[OfflineSyncManager] Pushing local Hive data to Cloud Firestore...');

      // 1. Sync Crops
      final localCrops = CropsHiveService.instance.getCrops();
      for (final crop in localCrops) {
        await _firestoreSync.upsertCrop(crop);
      }

      // 2. Sync Fish Ponds
      final localPonds = FishHiveService.instance.getPonds();
      for (final pond in localPonds) {
        await _firestoreSync.upsertFishPond(pond);
      }

      // 3. Sync Livestock
      final localAnimals = LivestockHiveService.instance.getAnimals();
      for (final animal in localAnimals) {
        await _firestoreSync.upsertLivestock(animal);
      }

      _lastSyncTime = DateTime.now();
      debugPrint('[OfflineSyncManager] Full Hive-Firestore sync completed at $_lastSyncTime');
    } catch (e) {
      debugPrint('[OfflineSyncManager] Error during sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clears all local Hive storage when user logs out.
  Future<void> clearAllLocalData() async {
    await CropsHiveService.instance.clearAll();
    await FishHiveService.instance.clearAll();
    await LivestockHiveService.instance.clearAll();
    await ChatHiveService.instance.clearAll();
  }
}
