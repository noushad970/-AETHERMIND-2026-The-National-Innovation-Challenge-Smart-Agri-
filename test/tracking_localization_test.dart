import 'package:flutter_test/flutter_test.dart';
import 'package:ai_agri_assistant/data/models/crop_activity.dart';
import 'package:ai_agri_assistant/data/models/crop.dart';
import 'package:ai_agri_assistant/data/services/crop_template_service.dart';
import 'package:ai_agri_assistant/features/livestock/data/livestock_activity_templates.dart';
import 'package:ai_agri_assistant/features/fish_tracker/data/fish_activity_templates.dart';

void main() {
  group('Tracking Localization Tests', () {
    test('CropActivity returns correct localized titles and descriptions', () {
      final activity = CropActivity(
        id: 'c1',
        cropId: 'rice_1',
        title: 'Initial Basal Fertilizer',
        titleBn: 'প্রাথমিক সার প্রয়োগ',
        description: 'Apply TSP, MOP and Gypsum.',
        descriptionBn: 'টিএসপি, এমওপি ও জিপসাম সার দিন।',
        dayFromPlanting: 1,
        scheduledDate: DateTime.now(),
      );

      expect(activity.getTitle(false), equals('Initial Basal Fertilizer'));
      expect(activity.getTitle(true), equals('প্রাথমিক সার প্রয়োগ'));
      expect(activity.getDescription(false), equals('Apply TSP, MOP and Gypsum.'));
      expect(activity.getDescription(true), equals('টিএসপি, এমওপি ও জিপসাম সার দিন।'));
    });

    test('CropTemplateService generates bilingual tasks for Rice', () {
      final now = DateTime.now();
      final activities = CropTemplateService.buildActivities(
        cropId: 'rice_crop',
        cropType: 'rice',
        plantingDate: now,
        totalGrowthDays: 120,
      );

      expect(activities.isNotEmpty, isTrue);
      for (final a in activities) {
        expect(a.title.isNotEmpty, isTrue);
        expect(a.titleBn.isNotEmpty, isTrue);
        expect(a.getTitle(true), equals(a.titleBn));
        expect(a.getTitle(false), equals(a.title));
      }
    });

    test('Crop growth stage returns localized stage in Bangla and English', () {
      final now = DateTime.now();
      final crop = Crop(
        id: 'crop1',
        userId: 'user1',
        cropType: 'rice',
        variety: 'BRRI dhan 28',
        plantingDate: now.subtract(const Duration(days: 10)),
        estimatedHarvestDate: now.add(const Duration(days: 90)),
        totalGrowthDays: 100,
        landAreaDecimal: 50.0,
        activities: [],
      );

      final stageEn = crop.getCurrentGrowthStage(false);
      final stageBn = crop.getCurrentGrowthStage(true);

      expect(stageEn.isNotEmpty, isTrue);
      expect(stageBn.isNotEmpty, isTrue);
      expect(stageEn, isNot(equals(stageBn)));
    });

    test('LivestockActivityTemplates generates bilingual tasks for Cattle and Poultry', () {
      final now = DateTime.now();
      final poultryActs = LivestockActivityTemplates.build(
        animalId: 'chick_1',
        species: 'Broiler Chicken (ব্রয়লার মুরগি)',
        purpose: 'meat',
        startDate: now,
      );

      expect(poultryActs.isNotEmpty, isTrue);
      for (final a in poultryActs) {
        expect(a.title.isNotEmpty, isTrue);
        expect(a.titleBn.isNotEmpty, isTrue);
        expect(a.getTitle(true), equals(a.titleBn));
        expect(a.getTitle(false), equals(a.title));
      }
    });

    test('FishActivityTemplates generates bilingual tasks for pond culture', () {
      final now = DateTime.now();
      final fishActs = FishActivityTemplates.generateForPond(
        fishPondId: 'pond_1',
        speciesId: 'tilapia',
        stockingDate: now,
        targetHarvestDays: 120,
      );

      expect(fishActs.isNotEmpty, isTrue);
      for (final a in fishActs) {
        expect(a.title.isNotEmpty, isTrue);
        expect(a.titleBn.isNotEmpty, isTrue);
        expect(a.getTitle(true), equals(a.titleBn));
        expect(a.getTitle(false), equals(a.title));
      }
    });
  });
}
