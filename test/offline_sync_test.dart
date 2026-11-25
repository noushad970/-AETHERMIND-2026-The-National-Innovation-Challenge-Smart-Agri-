import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ai_agri_assistant/data/models/crop.dart';
import 'package:ai_agri_assistant/data/models/fish_pond.dart';
import 'package:ai_agri_assistant/data/services/crops_hive_service.dart';
import 'package:ai_agri_assistant/data/services/fish_hive_service.dart';
import 'package:ai_agri_assistant/data/services/chat_hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await CropsHiveService.instance.init();
    await FishHiveService.instance.init();
    await ChatHiveService.instance.init();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Hive Offline Storage & Sync Tests', () {
    test('CropsHiveService saves, retrieves, and deletes crops offline', () async {
      final cropsService = CropsHiveService.instance;

      final testCrop = Crop(
        id: 'crop_123',
        userId: 'user_1',
        cropType: 'Rice',
        variety: 'BRRI Dhan 28',
        landAreaDecimal: 50.0,
        totalGrowthDays: 140,
        plantingDate: DateTime(2026, 3, 1),
        estimatedHarvestDate: DateTime(2026, 7, 20),
      );

      await cropsService.saveCrop(testCrop);
      final retrieved = cropsService.getCrop('crop_123');
      expect(retrieved, isNotNull);
      expect(retrieved!.variety, 'BRRI Dhan 28');
      expect(retrieved.landAreaDecimal, 50.0);

      final allCrops = cropsService.getCrops();
      expect(allCrops.length, 1);

      await cropsService.deleteCrop('crop_123');
      expect(cropsService.getCrop('crop_123'), isNull);
    });

    test('FishHiveService saves and retrieves fish ponds offline', () async {
      final fishService = FishHiveService.instance;

      final testPond = FishPond(
        id: 'pond_456',
        userId: 'user_1',
        speciesId: 'ruhi',
        speciesName: 'রুই মাছ',
        pondName: 'উত্তর পুকুর',
        fingerlingCount: 500,
        deadCount: 10,
        pondAreaDecimals: 20.0,
        targetHarvestDays: 180,
        stockingDate: DateTime(2026, 2, 1),
      );

      await fishService.savePond(testPond);
      final retrieved = fishService.getPond('pond_456');
      expect(retrieved, isNotNull);
      expect(retrieved!.pondName, 'উত্তর পুকুর');
      expect(retrieved.fingerlingCount, 500);
      expect(retrieved.liveCount, 490);

      final allPonds = fishService.getPonds();
      expect(allPonds.length, 1);
    });
  });
}
