import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../models/crop.dart';
import '../models/crop_activity.dart';
import '../repositories/bd_crops_repository.dart';

/// Generates a comprehensive cultivation timeline for any crop or plant type.
/// Each entry is a [CropActivity] tied to a specific milestone day from planting.
class CropTemplateService {
  CropTemplateService._();
  static const _uuid = Uuid();

  /// Returns total number of growth days for the given crop type.
  static int growthDaysFor(String cropType) {
    final entry = _findCatalogEntry(cropType);
    if (entry != null && entry.durationDays > 0) {
      return entry.durationDays;
    }
    return AppConstants.defaultCropGrowthDays[cropType] ?? 90;
  }

  /// Whether this crop is grown as an orchard (counts trees instead of land).
  static bool isOrchard(String cropType) {
    final entry = _findCatalogEntry(cropType);
    if (entry != null && (entry.category == 'Trees' || entry.category == 'Fruits')) {
      final name = entry.nameEn.toLowerCase();
      if (name.contains('watermelon') || name.contains('melon')) return false;
      return true;
    }
    final lower = cropType.toLowerCase();
    return lower.contains('mango') ||
        lower.contains('banana') ||
        lower.contains('coconut') ||
        lower.contains('guava') ||
        lower.contains('papaya') ||
        lower.contains('lemon') ||
        lower.contains('litchi') ||
        lower.contains('dragon') ||
        lower.contains('jackfruit') ||
        lower.contains('malta') ||
        lower.contains('orange') ||
        lower.contains('tree');
  }

  /// Build the cultivation timeline for a crop.
  static List<CropActivity> buildActivities({
    required String cropId,
    required String cropType,
    required DateTime plantingDate,
    int? totalGrowthDays,
  }) {
    final days = totalGrowthDays ?? growthDaysFor(cropType);
    final timeline = _timelineFor(cropType, days);
    return timeline
        .map(
          (entry) => CropActivity(
            id: _uuid.v4(),
            cropId: cropId,
            title: entry.titleEn,
            titleBn: entry.titleBn,
            description: entry.descriptionEn,
            descriptionBn: entry.descriptionBn,
            dayFromPlanting: entry.day,
            scheduledDate: plantingDate.add(Duration(days: entry.day - 1)),
            category: entry.category,
          ),
        )
        .toList();
  }

  /// Build a [Crop] from user input with full predefined tasks.
  static Crop buildCrop({
    required String userId,
    required String cropType,
    required String variety,
    required DateTime plantingDate,
    required double landAreaDecimal,
    int? numberOfTrees,
    String notes = '',
  }) {
    final cropId = _uuid.v4();
    final days = growthDaysFor(cropType);
    final activities = buildActivities(
      cropId: cropId,
      cropType: cropType,
      plantingDate: plantingDate,
      totalGrowthDays: days,
    );
    return Crop(
      id: cropId,
      userId: userId,
      cropType: cropType,
      variety: variety,
      plantingDate: plantingDate,
      landAreaDecimal: landAreaDecimal,
      totalGrowthDays: days,
      estimatedHarvestDate: plantingDate.add(Duration(days: days)),
      numberOfTrees: numberOfTrees,
      notes: notes,
      activities: activities,
    );
  }

  static dynamic _findCatalogEntry(String crop) {
    final q = crop.trim().toLowerCase();
    for (final c in BdCropsRepository.allCrops) {
      if (c.id.toLowerCase() == q ||
          c.nameEn.toLowerCase() == q ||
          c.nameBn.toLowerCase() == q) {
        return c;
      }
    }
    for (final c in BdCropsRepository.allCrops) {
      if (q.contains(c.nameEn.toLowerCase()) ||
          q.contains(c.nameBn.toLowerCase()) ||
          c.nameEn.toLowerCase().contains(q) ||
          c.nameBn.toLowerCase().contains(q)) {
        return c;
      }
    }
    return null;
  }

  static List<_TemplateEntry> _timelineFor(String crop, int totalDays) {
    final lower = crop.toLowerCase();

    // 1. Rice / Paddy (Boro, Aman, Aus)
    if (lower.contains('rice') || lower.contains('paddy') || lower.contains('dhan')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Land Preparation & Basal Fertilizer',
          titleBn: 'জমি তৈরি ও প্রাথমিক সার প্রয়োগ',
          descriptionEn: 'Plow and level field 3-4 times. Apply TSP, MOP, Gypsum, and cow dung during final plowing.',
          descriptionBn: '৩-৪ টি গভীর চাষ ও মই দিয়ে জমি সমান করুন। শেষ চাষে টিএসপি, পটাশ, জিপসাম ও গোবর সার প্রয়োগ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 5,
          titleEn: 'Seedling Care & Uprooting',
          titleBn: 'বীজতলা পরিচর্যা ও চারা তোলা',
          descriptionEn: 'Carefully uproot healthy seedlings from the nursery without damaging root systems.',
          descriptionBn: 'সুস্থ ও সতেজ চারা সাবধানে তুলুন যাতে মূল ক্ষতিগ্রস্ত না হয়।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 8,
          titleEn: 'Transplanting into Main Field',
          titleBn: 'মূল জমিতে চারা রোপণ',
          descriptionEn: 'Transplant 2-3 seedlings per hill at 20 cm row-to-row and 15 cm plant-to-plant spacing.',
          descriptionBn: 'সারি থেকে সারি ২০ সেমি এবং গোছা থেকে গোছা ১৫ সেমি দূরত্বে ২-৩টি চারা রোপণ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 15,
          titleEn: 'First Irrigation & Weeding',
          titleBn: '১ম সেচ ও আগাছা দমন',
          descriptionEn: 'Maintain 2-3 cm standing water and clear first batch of weeds with a weeder or hand pulling.',
          descriptionBn: 'জমিতে ২-৩ সেমি পানি রাখুন এবং প্রথম নিড়ানি দিয়ে আগাছা পরিষ্কার করুন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 22,
          titleEn: '1st Urea Top-Dressing',
          titleBn: '১ম কিস্তি ইউরিয়া সার উপরিপ্রয়োগ',
          descriptionEn: 'Broadcast 1st installment of Urea fertilizer at early tillering stage.',
          descriptionBn: 'কুশি আসার শুরুতে ১ম কিস্তির ইউরিয়া সার ছিটিয়ে দিন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 35,
          titleEn: 'Stem Borer & Leaf Roller Scouting',
          titleBn: 'মাজরা পোকা ও পাতা মোড়ানো পোকা পর্যবেক্ষণ',
          descriptionEn: 'Install light traps and set up bamboo perches for birds across the paddy field.',
          descriptionBn: 'ক্ষেতে আলোর ফাঁদ ও পার্চিং (ডাল পোতা) পদ্ধতি ব্যবহার করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 45,
          titleEn: '2nd Urea & Potash Top-Dressing',
          titleBn: '২য় কিস্তি ইউরিয়া ও পটাশ সার প্রয়োগ',
          descriptionEn: 'Apply 2nd installment of Urea and 5kg MOP per bigha at peak tillering stage.',
          descriptionBn: 'কুশি বৃদ্ধির চূড়ান্ত পর্যায়ে ২য় কিস্তির ইউরিয়া ও বিঘাপ্রতি ৫ কেজি এমওপি সার দিন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 60,
          titleEn: 'Blast & Sheath Blight Prevention',
          titleBn: 'ব্লাস্ট ও খোলপচা রোগ প্রতিরোধ',
          descriptionEn: 'Spray Tricyclazole or Nativo if humid or foggy weather prevails.',
          descriptionBn: 'আবহাওয়া স্যাঁতসেঁতে থাকলে ট্রাইসাইক্লাজোল বা নাটিভো স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 75,
          titleEn: 'Booting & Flowering Irrigation',
          titleBn: 'কাইচ থোড় ও ফুল ফোটার সেচ',
          descriptionEn: 'Keep 4-5 cm constant water depth in the field. Prevent water stress completely.',
          descriptionBn: 'জমিতে ক্রমাগত ৪-৫ সেমি পানি ধরে রাখুন। কোনোভাবেই পানির ঘাটতি হতে দেওয়া যাবে না।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 95,
          titleEn: 'Dough Stage & Water Drainage',
          titleBn: 'দুধ ও শক্ত দানা গঠন ও পানি নিষ্কাশন',
          descriptionEn: 'Check grain filling. Drain field water 10-12 days before planned harvest.',
          descriptionBn: 'দানা শক্ত হওয়া শুরু হলে কাটার ১০-১২ দিন আগে জমির পানি নিষ্কাশন করুন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: (totalDays - 5).clamp(100, totalDays),
          titleEn: 'Maturity Check (80% Golden Grain)',
          titleBn: 'ধান ৮০% পাকা পরীক্ষা',
          descriptionEn: 'Prepare harvest tools and threshing yard once 80% of panicle grains turn golden yellow.',
          descriptionBn: 'শীষের ৮০% ধান সোনালী রঙ ধারণ করলে কাটার প্রস্তুতি নিন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvesting & Threshing',
          titleBn: 'ফসল কর্তন ও মাড়াই',
          descriptionEn: 'Harvest paddy in dry weather, thresh, and dry grains to 12% moisture before storing.',
          descriptionBn: 'শুকনো আবহাওয়ায় ধান কেটে মাড়াই করুন এবং ১২% আর্দ্রতায় শুকিয়ে সংরক্ষণ করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 2. Wheat
    if (lower.contains('wheat') || lower.contains('gom')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Land Preparation & Basal Fertilizer',
          titleBn: 'জমি চাষ ও প্রাথমিক সার প্রয়োগ',
          descriptionEn: 'Plow 4-5 times to achieve fine tilth. Incorporate cow dung, TSP, MOP, and gypsum.',
          descriptionBn: '৪-৫টি চাষ ও মই দিয়ে মাটি ঝুরঝুরে করুন। গোবর, টিএসপি, এমওপি ও জিপসাম সার দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 3,
          titleEn: 'Line Sowing of Treated Seeds',
          titleBn: 'সারিবদ্ধভাবে শোধিত বীজ বপন',
          descriptionEn: 'Sow treated seeds 4-5 cm deep in lines 20 cm apart.',
          descriptionBn: '২০ সেমি দূরত্বে সারিতে ৪-৫ সেমি গভীরে শোধিত বীজ বপন করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 18,
          titleEn: '1st Irrigation (Crown Root Initiation - CRI)',
          titleBn: '১ম সেচ - মুকুট শিকড় গজানো ধাপ',
          descriptionEn: 'Apply crucial first irrigation between 17-21 days after sowing.',
          descriptionBn: 'বপনের ১৭-২১ দিনের মধ্যে অতি গুরুত্বপূর্ণ ১ম সেচ প্রদান করুন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 25,
          titleEn: '1st Urea Top-Dressing',
          titleBn: '১ম কিস্তি ইউরিয়া প্রয়োগ',
          descriptionEn: 'Apply 1st dose of Urea top-dressing when soil reaches proper workable moisture.',
          descriptionBn: 'সেচের পর জমিতে জো আসলে ১ম কিস্তির ইউরিয়া সার প্রয়োগ করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 40,
          titleEn: 'Weeding & Broadleaf Control',
          titleBn: 'আগাছা নিড়ানি ও চওড়া পাতা দমন',
          descriptionEn: 'Remove weeds manually or apply approved broadleaf selective herbicide.',
          descriptionBn: 'হাত দিয়ে আগাছা উপড়ে ফেলুন বা অনুমোদিত আগাছানাশক স্প্রে করুন।',
          category: 'weed',
        ),
        const _TemplateEntry(
          day: 55,
          titleEn: '2nd Irrigation (Tillering Stage)',
          titleBn: '২য় সেচ - কুশি গজানো পর্যায়',
          descriptionEn: 'Apply second irrigation to maximize productive tillers and head size.',
          descriptionBn: 'অতিরিক্ত কুশি ও শীষের সংখ্যা বাড়াতে ২য় সেচ দিন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 70,
          titleEn: 'Rust & Aphid Inspection',
          titleBn: 'জাবপোকা ও মরিচা রোগ পরীক্ষা',
          descriptionEn: 'Check undersides of leaves for yellow/brown rust spots or aphids; spray Tilt if seen.',
          descriptionBn: 'পাতার নিচে হলুদ মরিচা দাগ বা জাবপোকা দেখলে টিল্ট বা ছত্রাকনাশক স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 85,
          titleEn: '3rd Irrigation (Grain Filling Stage)',
          titleBn: '৩য় সেচ - শিষ ও দানা গঠন',
          descriptionEn: 'Ensure optimum soil moisture for full grain development.',
          descriptionBn: 'দানা পুষ্ট হওয়ার জন্য জমিতে রস নিশ্চিত করতে শেষ সেচ দিন।',
          category: 'irrigation',
        ),
        _TemplateEntry(
          day: (totalDays - 8).clamp(95, totalDays),
          titleEn: 'Crop Maturity & Moisture Check',
          titleBn: 'গাছ শুকানো ও আর্দ্রতা পরীক্ষা',
          descriptionEn: 'Inspect crop when plants and spikes turn bright golden yellow.',
          descriptionBn: 'গাছ ও শিষ উজ্জ্বল সোনালী হলুদ হলে কাটার প্রস্তুতি নিন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Wheat Harvest & Safe Storage',
          titleBn: 'গম কর্তন ও ঝাড়াই-মাড়াই',
          descriptionEn: 'Harvest on a bright sunny day, dry grains thoroughly, and store in airtight bins.',
          descriptionBn: 'রৌদ্রোজ্জ্বল দিনে গম কেটে রোদে শুকিয়ে বায়ুরোধী পাত্রে সংরক্ষণ করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 3. Maize / Corn
    if (lower.contains('maize') || lower.contains('corn') || lower.contains('bhutta')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Ridge & Furrow Preparation',
          titleBn: 'জমি তৈরি ও বেড তৈরি',
          descriptionEn: 'Make ridges 60 cm apart. Apply organic manure, DAP, and Boron fertilizer.',
          descriptionBn: '৬০ সেমি দূরত্বে ভেলি বা আইল তৈরি করুন। গোবর, ডিএপি ও বোরন সার প্রয়োগ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 3,
          titleEn: 'Sowing on Ridge Slope',
          titleBn: 'বীজ বপন',
          descriptionEn: 'Sow one seed per spot every 20-25 cm along ridge slopes at 3-4 cm depth.',
          descriptionBn: 'আইলের ঢালে ২০-২৫ সেমি পর পর একটি করে পুষ্ট বীজ বপন করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 15,
          titleEn: '1st Irrigation & Thinning',
          titleBn: '১ম সেচ ও চারা পাতলাকরণ',
          descriptionEn: 'Provide furrow irrigation and thin out weak or overcrowded seedlings.',
          descriptionBn: 'নালা দিয়ে হালকা সেচ দিন এবং দুর্বল চারা উঠিয়ে ফেলুন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 25,
          titleEn: '1st Urea & Zinc Application',
          titleBn: '১ম কিস্তি ইউরিয়া ও জিংক প্রয়োগ',
          descriptionEn: 'Apply fertilizer in bands 5 cm away from stems and cover with soil.',
          descriptionBn: 'গাছের গোড়া থেকে ৫ সেমি দূরে সার দিয়ে মাটি চাপা দিন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 40,
          titleEn: 'Earthing Up & Inter-Cultivation',
          titleBn: 'গাছের গোড়ায় মাটি তোলা ও নিড়ানি',
          descriptionEn: 'Draw soil up around stalks to anchor plants against wind lodging.',
          descriptionBn: 'গাছ যাতে বাতাসে হেলে না পড়ে সেজন্য গোড়ায় মাটি তুলে দিন।',
          category: 'weed',
        ),
        const _TemplateEntry(
          day: 55,
          titleEn: 'Fall Armyworm & Borer Scouting',
          titleBn: 'ফল আর্মিওয়ার্ম ও মাজরা পোকা দমন',
          descriptionEn: 'Scout whorls and new leaves for shot-hole damage; apply biopesticide or Spinetoram.',
          descriptionBn: 'গাছের পাতা ও ডগায় ফুটো বা কীড়া দেখলে জৈব বালাইনাশক স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 70,
          titleEn: 'Tasseling & Silking Irrigation',
          titleBn: 'মোচা আসার সেচ',
          descriptionEn: 'Ensure critical irrigation during male tassel shedding and silk emergence.',
          descriptionBn: 'গাছে পুরুষ ফুল ও সিল্ক বের হওয়ার সময় পর্যাপ্ত সেচ নিশ্চিত করুন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 95,
          titleEn: 'Kernel Filling & Hardness Check',
          titleBn: 'দানার পূর্ণতা পরীক্ষা',
          descriptionEn: 'Peel back husk slightly to evaluate kernel fill and starch line progression.',
          descriptionBn: 'মোচার খোসা সামান্য সরিয়ে দানার পরিপুষ্টতা ও শক্ত ভাব পরীক্ষা করুন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvest Ripe Cobs & Shelling',
          titleBn: 'পাকা মোচা সংগ্রহ ও মাড়াই',
          descriptionEn: 'Harvest when husks turn straw brown and black layer forms at kernel base.',
          descriptionBn: 'মোচার খোসা খড়ের মতো বাদামী হলে মোচা সংগ্রহ করে শুকান।',
          category: 'harvest',
        ),
      ];
    }

    // 4. Tomato
    if (lower.contains('tomato')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Seedbed Preparation & Organic Mix',
          titleBn: 'বেড তৈরি ও জৈব সার মিশ্রণ',
          descriptionEn: 'Build raised beds with ample tricho-compost, TSP, and well-rotted manure.',
          descriptionBn: 'উঁচু বেড তৈরি করে পর্যাপ্ত ট্রাইকো-কম্পোস্ট ও টিএসপি মিশিয়ে নিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 5,
          titleEn: 'Transplanting Seedlings',
          titleBn: 'চারা রোপণ',
          descriptionEn: 'Transplant healthy 25-day-old seedlings late afternoon at 60x50 cm spacing.',
          descriptionBn: 'বিকালের দিকে ৬০x৫০ সেমি দূরত্বে চারা রোপণ করে পানি দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 12,
          titleEn: 'Staking & 1st Irrigation',
          titleBn: 'খুঁটি দেওয়া ও ১ম সেচ',
          descriptionEn: 'Erect bamboo stakes to support upright growth and irrigate root zone gently.',
          descriptionBn: 'গাছ সোজা রাখতে বাঁশের খুঁটি দিন এবং গোড়ায় হালকা সেচ দিন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 22,
          titleEn: 'Side-Shoot Pruning & Balanced Nutrition',
          titleBn: '১ম কিস্তি সার ও শাখা ছাঁটাই',
          descriptionEn: 'Prune basal suckers/side shoots and side-dress with balanced NPK fertilizer.',
          descriptionBn: 'গাছের গোড়ার অপ্রয়োজনীয় সাকার বা কুশি ভেঙে দিন এবং এনপিকে সার দিন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 35,
          titleEn: 'Leaf Curl & Whitefly Management',
          titleBn: 'পাতা কোঁকড়ানো ও সাদামাছি দমন',
          descriptionEn: 'Install yellow sticky traps and spray neem oil or Imidacloprid against whiteflies.',
          descriptionBn: 'সাদামাছি দমনে হলুদ আঠালো ফাঁদ ও নিম তেলের স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 50,
          titleEn: 'Fruit Booster & Boron Spray',
          titleBn: 'পটাশ সার ও ফল বৃদ্ধির স্প্রে',
          descriptionEn: 'Foliar spray chelated potassium and boron to prevent blossom end rot and boost size.',
          descriptionBn: 'ফলের আকার ও উজ্জ্বলতা বাড়াতে পটাশ ও বোরন স্প্রে করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 68,
          titleEn: 'First Ripe Tomato Picking',
          titleBn: '১ম পাকা টমেটো সংগ্রহ',
          descriptionEn: 'Carefully harvest breaker-stage or pink ripe fruits with calyx attached.',
          descriptionBn: 'হালকা লালচে রঙের পাকা টমেটো বোঁটাসহ সাবধানে তুলুন।',
          category: 'harvest',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Final Harvest & Grading',
          titleBn: 'চূড়ান্ত ফল সংগ্রহ ও গ্রেডিং',
          descriptionEn: 'Complete final picking, sort by size/grade, and clear crop residues.',
          descriptionBn: 'নিয়মিত বিরতিতে ফল সংগ্রহ করে আকার অনুযায়ী গ্রেডিং করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 5. Potato
    if (lower.contains('potato') || lower.contains('alu')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Furrow Making & Basal Manuring',
          titleBn: 'গভীর চাষ ও ভেলি তৈরি',
          descriptionEn: 'Prepare fine loose soil and make 60 cm furrows with basal fertilizers.',
          descriptionBn: 'মাটি ভালোভাবে ঝুরঝুরে করে ৬০ সেমি দূরত্বে নালা তৈরি করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 3,
          titleEn: 'Planting Sprouted Seed Tubers',
          titleBn: 'অঙ্কুরিত বীজ আলু রোপণ',
          descriptionEn: 'Place sprouted seed tubers eye-upwards every 20 cm along furrows.',
          descriptionBn: 'চোখ উপরের দিকে রেখে ২০ সেমি পর পর বীজ আলু রোপণ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 15,
          titleEn: 'Sprout Emergence & Light Irrigation',
          titleBn: 'চারা গজানো পরীক্ষা ও হালকা সেচ',
          descriptionEn: 'Inspect even sprout emergence and provide gentle furrow irrigation.',
          descriptionBn: 'মাটিতে পরিমিত রস নিশ্চিত করতে নালা দিয়ে হালকা সেচ দিন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 25,
          titleEn: '1st Earthing Up & Top-Dressing',
          titleBn: '১ম ভেলি তোলা ও ইউরিয়া সার',
          descriptionEn: 'Mound loose soil around stems to shelter young tubers from sunlight exposure.',
          descriptionBn: 'গাছের গোড়ায় মাটি তুলে দিন যাতে আলু রোদে সবুজ না হয়।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 42,
          titleEn: 'Late Blight Preventive Spray',
          titleBn: 'নাবি ধসা (লেট ব্লাইট) প্রতিরোধক স্প্রে',
          descriptionEn: 'Apply protective Mancozeb / Ridomil Gold spray during cold, foggy weather.',
          descriptionBn: 'কুয়াশাচ্ছন্ন আবহাওয়ায় ম্যানকোজেব জাতীয় ছত্রাকনাশক স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 58,
          titleEn: '2nd Earthing Up & Bulking Moisture',
          titleBn: '২য় ভেলি তোলা ও আলুর বৃদ্ধি সেচ',
          descriptionEn: 'Build high ridges and ensure steady soil moisture for tuber expansion.',
          descriptionBn: 'আলু বড় হওয়ার জন্য প্রয়োজনীয় আর্দ্রতা বজায় রাখুন।',
          category: 'irrigation',
        ),
        _TemplateEntry(
          day: (totalDays - 12).clamp(70, totalDays),
          titleEn: 'Dehaulming / Haulm Cutting',
          titleBn: 'হালম কাটা বা গাছ কাটা',
          descriptionEn: 'Cut vegetative vines at ground level 10-12 days before harvest to cure skin.',
          descriptionBn: 'আলুর খোসা শক্ত করার জন্য উত্তোলনের ১০-১২ দিন আগে মাটির উপরের গাছ কেটে দিন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Potato Digging & Shade Curing',
          titleBn: 'আলু উত্তোলন ও ছায়ায় কিউরিং',
          descriptionEn: 'Dig tubers on a dry morning and cure in well-ventilated shaded room.',
          descriptionBn: 'শুকনো দিনে আলু তুলে ছায়াযুক্ত স্থানে রেখে কিউরিং সম্পন্ন করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 6. Onion / Garlic
    if (lower.contains('onion') || lower.contains('pyaj') || lower.contains('garlic') || lower.contains('roshun')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Land Preparation & Raised Bed',
          titleBn: 'জমি চাষ ও বেড তৈরি',
          descriptionEn: 'Prepare pulverized level soil. Mix TSP, MOP, Gypsum, and Sulfur powder.',
          descriptionBn: 'মাটি খুব মিহি করে সমান করুন। টিএসপি, পটাশ, জিপসাম ও সালফার মিশিয়ে দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 4,
          titleEn: 'Seedling / Clove Planting',
          titleBn: 'চারা বা কোয়া রোপণ',
          descriptionEn: 'Plant seedlings or healthy cloves in rows at 10x10 cm spacing.',
          descriptionBn: '১০x১০ সেমি দূরত্বে সারিবদ্ধভাবে রোপণ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 15,
          titleEn: 'First Weeding & Light Irrigation',
          titleBn: '১ম নিড়ানি ও হালকা সেচ',
          descriptionEn: 'Keep beds clean of weeds and supply light irrigation to facilitate rooting.',
          descriptionBn: 'আগাছামুক্ত রাখুন এবং শিকড়ের বৃদ্ধির জন্য হালকা পানি দিন।',
          category: 'weed',
        ),
        const _TemplateEntry(
          day: 30,
          titleEn: 'Urea & Sulfur Top-Dressing',
          titleBn: '১ম কিস্তি ইউরিয়া ও সালফার উপরিপ্রয়োগ',
          descriptionEn: 'Top-dress Nitrogen and Sulfur to enhance pungency and bulb quality.',
          descriptionBn: 'সালফার পেঁয়াজ/রসুনের ঝাঁঝ ও রোগ প্রতিরোধ ক্ষমতা বাড়ায়।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 50,
          titleEn: 'Purple Blotch & Thrips Control',
          titleBn: 'পার্পল ব্লচ বা বেগুনী দাগ রোগ দমন',
          descriptionEn: 'Spray Rovral or Ridomil Gold if purple spots appear on leaves.',
          descriptionBn: 'পাতায় বেগুনী দাগ দেখলে রোভরাল বা রিডোমিল গোল্ড স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 75,
          titleEn: 'Bulb Enlargement Moisture Control',
          titleBn: 'বাল্ব স্ফীতি পর্যায় ও সেচ নিয়ন্ত্রণ',
          descriptionEn: 'Maintain moderate soil moisture while avoiding waterlogging.',
          descriptionBn: 'মাটি অতিরিক্ত ভিজিয়ে রাখা যাবে না, জল নিষ্কাশন ব্যবস্থা রাখুন।',
          category: 'irrigation',
        ),
        _TemplateEntry(
          day: (totalDays - 10).clamp(80, totalDays),
          titleEn: 'Neck Fall Stage & Irrigation Stoppage',
          titleBn: 'গাছের ঘাড় ভাঙা ও সেচ বন্ধ',
          descriptionEn: 'Cease all irrigation once 60-70% of tops naturally fall over.',
          descriptionBn: 'পাতা হলুদ হয়ে নুয়ে পড়লে সেচ সম্পূর্ণ বন্ধ করুন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvest & Curing in Shade',
          titleBn: 'উত্তোলন ও শুকানো',
          descriptionEn: 'Pull bulbs gently, cure with tops in shade for 3-4 days before trimming.',
          descriptionBn: 'পেঁয়াজ/রসুন তুলে ছায়ায় পাতাসহ ৩-৪ দিন শুকিয়ে সংরক্ষণ করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 7. Chili / Pepper / Brinjal / Eggplant
    if (lower.contains('chili') || lower.contains('morich') || lower.contains('brinjal') || lower.contains('begun')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Pit & Raised Bed Preparation',
          titleBn: 'জমি তৈরি ও গর্ত প্রস্তুত',
          descriptionEn: 'Build raised beds with organic compost, TSP, and basal minerals.',
          descriptionBn: 'গোবর সার ও বেসাল সার দিয়ে raised bed তৈরি করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 6,
          titleEn: 'Transplanting Seedlings',
          titleBn: 'চারা রোপণ',
          descriptionEn: 'Transplant sturdy disease-free seedlings at 50x50 cm spacing.',
          descriptionBn: '৫০x৫০ সেমি দূরত্বে সুস্থ চারা রোপণ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 15,
          titleEn: '1st Irrigation & Weeding',
          titleBn: '১ম সেচ ও আগাছা দমন',
          descriptionEn: 'Apply light irrigation and hand weed around seedling base.',
          descriptionBn: 'হালকা সেচ দিন এবং আগাছা পরিষ্কার করুন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 28,
          titleEn: 'Urea & Potash Side-Dressing',
          titleBn: 'ইউরিয়া ও পটাশ উপরিপ্রয়োগ',
          descriptionEn: 'Side-dress fertilizer slightly away from stems and cover with soil.',
          descriptionBn: 'গোড়া থেকে একটু দূরে সার দিয়ে হালকা মাটি দিন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 45,
          titleEn: 'Shoot & Fruit Borer / Mite Control',
          titleBn: 'মাইট ও ডগা-ফল ছিদ্রকারী পোকা দমন',
          descriptionEn: 'Install pheromone traps and clip off any wilted bore-infested shoot tips.',
          descriptionBn: 'ফেরোমন ফাঁদ বসান এবং আক্রান্ত ডগা কেটে ধ্বংস করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 65,
          titleEn: 'Flowering & Micronutrient Spray',
          titleBn: 'ফুল-ফল ধারণ ও অণুখাদ্য স্প্রে',
          descriptionEn: 'Spray chelated Zinc and Boron to prevent flower drop and fruit deformation.',
          descriptionBn: 'ফুল ঝরা রোধে চিলেটেড জিংক ও বোরন স্প্রে করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 80,
          titleEn: 'First Harvesting',
          titleBn: '১ম ফল তোলা',
          descriptionEn: 'Pick mature fruits regularly to encourage continuous flowering.',
          descriptionBn: 'নিয়মিত বিরতিতে ফল সংগ্রহ করুন যাতে নতুন ফুল আসে।',
          category: 'harvest',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Continuous Picking & Bush Care',
          titleBn: 'পর্যায়ক্রমিক সংগ্রহ ও পরিচর্যা',
          descriptionEn: 'Harvest weekly and maintain vine/bush vigor with post-harvest feeds.',
          descriptionBn: 'প্রতি সপ্তাহে সংগ্রহ করুন এবং গাছ সুস্থ রাখুন।',
          category: 'harvest',
        ),
      ];
    }

    // 8. Mustard / Sesame / Sunflower (Oilseeds)
    if (lower.contains('mustard') || lower.contains('sarisha') || lower.contains('sunflower') || lower.contains('til')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Fine Tilth & Basal Fertilizer',
          titleBn: 'মিহি চাষ ও ভিত্তি সার প্রয়োগ',
          descriptionEn: 'Plow 3-4 times for loose fine soil. Apply cow dung, TSP, MOP, Gypsum, and Boron.',
          descriptionBn: '৩-৪ বার চাষ দিয়ে মাটি ঝুরঝুরে করুন। গোবর, টিএসপি, পটাশ, জিপসাম ও বোরন দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 3,
          titleEn: 'Line Sowing of Oilseeds',
          titleBn: 'সারিতে বীজ বপন',
          descriptionEn: 'Sow small seeds in shallow lines 30 cm apart mixed with dry sand.',
          descriptionBn: '৩০ সেমি দূরত্বের সারিতে পাতলা করে বীজ বপন করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 16,
          titleEn: 'Thinning & 1st Irrigation',
          titleBn: 'গাছ পাতলাকরণ ও ১ম সেচ',
          descriptionEn: 'Thin plants to 8-10 cm intra-row spacing and provide light irrigation.',
          descriptionBn: 'গাছের দূরত্ব ৮-১০ সেমি রেখে অতিরিক্ত চারা তুলে ফেলুন ও হালকা সেচ দিন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 28,
          titleEn: 'Urea Top-Dressing before Flower Initiation',
          titleBn: 'ইউরিয়া সার উপরিপ্রয়োগ',
          descriptionEn: 'Broadcast Urea top-dressing prior to flowering onset.',
          descriptionBn: 'ফুল আসার আগে ইউরিয়া সার উপরিপ্রয়োগ করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 45,
          titleEn: 'Aphid Scouting & Bio-Control',
          titleBn: 'জাবপোকা (এফিড) পর্যবেক্ষণ ও দমন',
          descriptionEn: 'Inspect yellow blossoms for aphid clusters; spray soapy water or Imidacloprid.',
          descriptionBn: 'হলুদ ফুলে জাবপোকা দেখলে সাবান পানি বা ইমিডাক্লোপ্রিড স্প্রে করুন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 65,
          titleEn: 'Pod & Grain Filling Inspection',
          titleBn: 'শুটি বা দানা পরিপুষ্টকরণ',
          descriptionEn: 'Check pod development and oil seed density.',
          descriptionBn: 'শুটির গঠন ও দানার ঘনত্ব পরীক্ষা করুন।',
          category: 'general',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvesting & Sun Drying',
          titleBn: 'ফসল কর্তন ও শুকানো',
          descriptionEn: 'Harvest early morning when 75-80% pods turn yellow, dry in sun, and thresh.',
          descriptionBn: '৭৫-৮০% শুটি হলুদ হলে সকালে কেটে রোদে শুকিয়ে মাড়াই করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 9. Jute / Cotton (Fiber & Cash Crops)
    if (lower.contains('jute') || lower.contains('pat') || lower.contains('cotton')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Deep Tillage & Basal Fertilizer',
          titleBn: 'গভীর চাষ ও জমি সমতলকরণ',
          descriptionEn: 'Plow 4-5 times deeply. Incorporate TSP and MOP during final pass.',
          descriptionBn: '৪-৫টি চাষ দিন এবং টিএসপি ও পটাশ সার শেষ চাষে প্রয়োগ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 3,
          titleEn: 'Row Sowing of Seeds',
          titleBn: 'সারিবদ্ধ বীজ বপন',
          descriptionEn: 'Sow seeds 2-3 cm deep in rows spaced 30 cm apart.',
          descriptionBn: '৩০ সেমি দূরত্বে সারিতে বীজ বপন করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 18,
          titleEn: '1st Weeding & Plant Thinning (Nirani)',
          titleBn: '১ম নিড়ানি ও চারা পাতলাকরণ',
          descriptionEn: 'Weed field and thin plants to maintain 7-10 cm spacing between plants.',
          descriptionBn: 'গাছ থেকে গাছের দূরত্ব ৭-১০ সেমি বজায় রেখে নিড়ানি দিন।',
          category: 'weed',
        ),
        const _TemplateEntry(
          day: 32,
          titleEn: '1st Urea Top-Dressing',
          titleBn: '১ম কিস্তি ইউরিয়া সার প্রয়োগ',
          descriptionEn: 'Apply 1st dose of Urea when adequate soil moisture is present.',
          descriptionBn: 'মাটিতে পর্যাপ্ত রস থাকা অবস্থায় ইউরিয়া সার দিন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 50,
          titleEn: 'Hairy Caterpillar & Yellow Mite Control',
          titleBn: 'বিছা পোকা ও হলুদ মাকড় দমন',
          descriptionEn: 'Inspect undersides of leaves and destroy egg masses; spray pesticide if needed.',
          descriptionBn: 'পাতার উল্টো পিঠে পর্যবেক্ষণ করুন এবং প্রয়োজনমতো বালাইনাশক দিন।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 70,
          titleEn: '2nd Urea Top-Dressing & Drainage',
          titleBn: '২য় কিস্তি ইউরিয়া ও পানি নিষ্কাশন',
          descriptionEn: 'Boost stalk height with final Urea application and ensure quick drainage.',
          descriptionBn: 'গাছের উচ্চতা বৃদ্ধির জন্য ইউরিয়া দিন এবং জলাবদ্ধতা দূর করুন।',
          category: 'fertilizer',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvest & Clean Water Retting',
          titleBn: 'পাট কর্তন ও জাগ দেওয়া',
          descriptionEn: 'Harvest at 50% flowering stage, tie bundles, and ret in clean slow-moving water.',
          descriptionBn: '৫০% গাছে ফুল আসলে পাট কেটে পরিষ্কার পানিতে জাগ দিন।',
          category: 'harvest',
        ),
      ];
    }

    // 10. Pulses (Lentil / Masur, Chickpea, Mungbean, Blackgram, Grasspea)
    if (lower.contains('lentil') || lower.contains('masur') || lower.contains('chickpea') || lower.contains('mung') || lower.contains('mug') || lower.contains('khesari') || lower.contains('dal')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Rhizobium Inoculation & Land Prep',
          titleBn: 'জমি চাষ ও অণুজীব সার প্রয়োগ',
          descriptionEn: 'Prepare loose seedbed. Inoculate seeds with Rhizobium bio-fertilizer and apply TSP.',
          descriptionBn: 'মাটি তৈরি করে রাইজোবিয়াম অণুজীব সার ও টিএসপি মিশিয়ে নিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 3,
          titleEn: 'Line Sowing of Pulses',
          titleBn: 'বীজ বপন',
          descriptionEn: 'Sow seeds in lines 25-30 cm apart at uniform 3-4 cm depth.',
          descriptionBn: '২৫-৩০ সেমি দূরত্বের সারিতে বীজ বপন করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 18,
          titleEn: 'Weeding & Drainage Management',
          titleBn: 'আগাছা দমন ও হালকা সেচ',
          descriptionEn: 'Keep plot weed-free and protect root zone against stagnant water.',
          descriptionBn: 'জমির আগাছা পরিষ্কার করুন এবং অতিরিক্ত পানি নিষ্কাশন নিশ্চিত করুন।',
          category: 'weed',
        ),
        const _TemplateEntry(
          day: 35,
          titleEn: 'Foliar DAP / Urea Spray',
          titleBn: 'ইউরিয়া স্প্রে ও ফুল আসার প্রস্তুতি',
          descriptionEn: 'Spray 2% DAP or Urea foliar solution to support lush branching.',
          descriptionBn: 'গাছের বৃদ্ধির জন্য হালকা ২% ডিএপি বা ইউরিয়া স্প্রে করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 50,
          titleEn: 'Pod Borer & Rust Scouting',
          titleBn: 'শুটি ছিদ্রকারী পোকা ও মরিচা রোগ দমন',
          descriptionEn: 'Install pheromone traps for Helicoverpa pod borer and scout pods.',
          descriptionBn: 'শুটিতে পোকার আক্রমণ প্রতিরোধে ফেরোমন ফাঁদ ব্যবহার করুন।',
          category: 'pest',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvest Ripe Pods & Threshing',
          titleBn: 'শুটি সংগ্রহ ও মাড়াই',
          descriptionEn: 'Harvest when 80% pods turn brown/black, sun-dry, and thresh.',
          descriptionBn: '৮০% শুটি কালচে/বাদামী হলে কেটে রোদে শুকিয়ে মাড়াই করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 11. Vegetables (Cabbage, Cauliflower, Carrot, Radish, Gourd, Okra, Cucumber, Spinach)
    if (lower.contains('cabbage') || lower.contains('cauliflower') || lower.contains('carrot') || lower.contains('radish') || lower.contains('gourd') || lower.contains('okra') || lower.contains('cucumber') || lower.contains('shak') || lower.contains('shobji')) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Raised Bed & Compost Preparation',
          titleBn: 'জমি তৈরি ও বেড তৈরি',
          descriptionEn: 'Construct raised beds with abundant tricho-compost and balanced basal nutrients.',
          descriptionBn: 'উঁচু বেড তৈরি করুন। ট্রাইকো-কম্পোস্ট ও সুষম সার দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 4,
          titleEn: 'Planting / Direct Sowing',
          titleBn: 'চারা রোপণ বা বীজ বপন',
          descriptionEn: 'Plant seedlings or sow seeds adhering to recommended variety spacing.',
          descriptionBn: 'জাত অনুযায়ী নির্দিষ্ট দূরত্ব বজায় রেখে রোপণ করুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 12,
          titleEn: '1st Irrigation & Light Weeding',
          titleBn: '১ম সেচ ও হালকা নিড়ানি',
          descriptionEn: 'Maintain uniform root moisture and remove early germinating weeds.',
          descriptionBn: 'মাটির রস বজায় রাখুন ও আগাছা দমন করুন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 22,
          titleEn: 'Urea & Potash Side-Dressing',
          titleBn: 'ইউরিয়া ও পটাশ সার উপরিপ্রয়োগ',
          descriptionEn: 'Top-dress with nitrogen and potash to stimulate robust canopy growth.',
          descriptionBn: 'গাছের দ্রুত বৃদ্ধির জন্য সুষম সার উপরিপ্রয়োগ করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 35,
          titleEn: 'Pest & Fungal Disease Scouting',
          titleBn: 'কীটপতঙ্গ ও ছত্রাক পরীক্ষা',
          descriptionEn: 'Inspect foliage for caterpillars, beetles, or leaf spots.',
          descriptionBn: 'লেদা পোকা ও পাতার দাগ রোগ পর্যবেক্ষণ করুন।',
          category: 'pest',
        ),
        _TemplateEntry(
          day: (totalDays * 0.7).round().clamp(20, totalDays - 5),
          titleEn: 'Head / Fruit Development Moisture',
          titleBn: 'ফল/সবজি বৃদ্ধি পরিচর্যা',
          descriptionEn: 'Provide regular light irrigation during rapid curd/head/fruit development.',
          descriptionBn: 'নিয়মিত পরিমিত সেচ প্রদান করুন।',
          category: 'irrigation',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvest Fresh Tender Vegetables',
          titleBn: 'পরিপুষ্ট সবজি সংগ্রহ',
          descriptionEn: 'Harvest crisp, fresh vegetables early morning for prime market value.',
          descriptionBn: 'সতেজ ও কচি অবস্থায় সবজি সংগ্রহ করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 12. Fruit Trees / Orchards (Mango, Banana, Guava, Papaya, Lemon, Litchi, Dragon, Malta)
    if (isOrchard(crop)) {
      return [
        const _TemplateEntry(
          day: 1,
          titleEn: 'Pit Preparation & Organic Manuring',
          titleBn: 'মাদল বা গর্ত তৈরি ও সার প্রয়োগ',
          descriptionEn: 'Dig 1x1m pits. Mix well-rotted cow dung, bone meal, TSP, and ash; rest for 10 days.',
          descriptionBn: '১x১ মিটার গর্ত করে গোবর, হাড়ের গুঁড়া, টিএসপি ও ছাই মিশিয়ে ১০ দিন রাখুন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 8,
          titleEn: 'Planting Grafted Sapling & Staking',
          titleBn: 'কলম বা সুস্থ চারা রোপণ',
          descriptionEn: 'Plant sapling keeping root-ball intact, firm soil, and tie securely to a bamboo stake.',
          descriptionBn: 'মাটির বল অক্ষত রেখে সোজাভাবে চারা রোপণ করে খুঁটি বেঁধে দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 18,
          titleEn: 'Ring Basin Irrigation',
          titleBn: 'রিং বেসিন সেচ ও মাটি আর্দ্রকরণ',
          descriptionEn: 'Construct a ring channel around canopy drip-line and irrigate thoroughly.',
          descriptionBn: 'গাছের গোড়া থেকে দূরে রিং নালা তৈরি করে পানি দিন।',
          category: 'irrigation',
        ),
        const _TemplateEntry(
          day: 45,
          titleEn: 'Basal Weeding & Canopy Pruning',
          titleBn: '১ম জৈব সার ও ডাল ছাঁটাই',
          descriptionEn: 'Clear weeds under basin and prune unwanted rootstock suckers.',
          descriptionBn: 'গোড়ায় নতুন আগাছা পরিষ্কার করুন এবং অবাঞ্ছিত কুশি ছেঁটে দিন।',
          category: 'general',
        ),
        const _TemplateEntry(
          day: 90,
          titleEn: 'Stem Borer & Mealybug Protection',
          titleBn: 'কাণ্ড ছিদ্রকারী পোকা ও মিলিবাগ দমন',
          descriptionEn: 'Paint trunk with lime-copper sulfate paste to prevent borer and scale attacks.',
          descriptionBn: 'গাছের কাণ্ডে চুন ও তুতের পেস্ট লাগান।',
          category: 'pest',
        ),
        const _TemplateEntry(
          day: 180,
          titleEn: 'Seasonal Balanced Nutrition',
          titleBn: 'মৌসুমি সুষম সার প্রয়োগ',
          descriptionEn: 'Apply pre/post-monsoon organic manure and NPK ring under canopy.',
          descriptionBn: 'বর্ষার শুরুতে ও শেষে ক্যানোপির নিচে সার প্রয়োগ করুন।',
          category: 'fertilizer',
        ),
        const _TemplateEntry(
          day: 270,
          titleEn: 'Blossom & Flowering Protection',
          titleBn: 'মুকুল বা ফুল আসার পরিচর্যা',
          descriptionEn: 'Spray protective fungicide and bio-insecticide at blossom swell.',
          descriptionBn: 'ফুল আসার সময় ছত্রাকনাশক ও কীটনাশক স্প্রে করুন।',
          category: 'pest',
        ),
        _TemplateEntry(
          day: totalDays,
          titleEn: 'Harvest Mature Fruits & Grading',
          titleBn: 'পরিপুষ্ট ফল সংগ্রহ ও গ্রেডিং',
          descriptionEn: 'Harvest ripe fruits with stalk attached and sort in cool shaded shelter.',
          descriptionBn: 'বোঁটাসহ সাবধানে পাকা ফল পেড়ে ঠাণ্ডা ছায়ায় গ্রেডিং করুন।',
          category: 'harvest',
        ),
      ];
    }

    // 13. Dynamic Proportional Timeline built from Catalog Guidelines
    final entry = _findCatalogEntry(crop);
    if (entry != null && entry.guidelines.isNotEmpty) {
      final list = <_TemplateEntry>[];
      list.add(const _TemplateEntry(
        day: 1,
        titleEn: 'Land Preparation & Basal Fertilizer',
        titleBn: 'জমি তৈরি ও প্রাথমিক সার প্রয়োগ',
        descriptionEn: 'Plow land and incorporate balanced basal fertilizers into soil.',
        descriptionBn: 'মাটি চাষ দিয়ে সুষম বেসাল সার মিশিয়ে জমি প্রস্তুত করুন।',
        category: 'general',
      ));
      
      for (final g in entry.guidelines) {
        final midDay = ((g.dayStart + g.dayEnd) / 2).round().clamp(2, totalDays - 1);
        list.add(_TemplateEntry(
          day: g.dayStart.clamp(2, totalDays),
          titleEn: '${g.stageNameEn} (${g.stageNameBn})',
          titleBn: '${g.stageNameBn} (${g.stageNameEn})',
          descriptionEn: g.keyActivitiesEn.isNotEmpty ? g.keyActivitiesEn : g.keyActivitiesBn,
          descriptionBn: g.keyActivitiesBn,
          category: 'general',
        ));
        if (g.waterAdviceBn.isNotEmpty && g.waterAdviceBn.length > 5) {
          list.add(_TemplateEntry(
            day: (g.dayStart + 3).clamp(3, totalDays - 2),
            titleEn: 'Irrigation & Water Management (${g.stageNameEn})',
            titleBn: 'সেচ ও পানি ব্যবস্থাপনা (${g.stageNameBn})',
            descriptionEn: g.waterAdviceEn.isNotEmpty ? g.waterAdviceEn : g.waterAdviceBn,
            descriptionBn: g.waterAdviceBn,
            category: 'irrigation',
          ));
        }
        if (g.fertilizerAdviceBn.isNotEmpty && g.fertilizerAdviceBn.length > 5) {
          list.add(_TemplateEntry(
            day: midDay,
            titleEn: 'Fertilizer Application (${g.stageNameEn})',
            titleBn: 'সার প্রয়োগ (${g.stageNameBn})',
            descriptionEn: g.fertilizerAdviceEn.isNotEmpty ? g.fertilizerAdviceEn : g.fertilizerAdviceBn,
            descriptionBn: g.fertilizerAdviceBn,
            category: 'fertilizer',
          ));
        }
        if (g.pestPreventionBn.isNotEmpty && g.pestPreventionBn.length > 5) {
          list.add(_TemplateEntry(
            day: (g.dayEnd - 3).clamp(midDay + 1, totalDays - 1),
            titleEn: 'Pest & Disease Prevention (${g.stageNameEn})',
            titleBn: 'বালাই দমন ও রোগবালাই প্রতিরোধ (${g.stageNameBn})',
            descriptionEn: g.pestPreventionEn.isNotEmpty ? g.pestPreventionEn : g.pestPreventionBn,
            descriptionBn: g.pestPreventionBn,
            category: 'pest',
          ));
        }
      }

      list.add(_TemplateEntry(
        day: totalDays,
        titleEn: 'Harvest & Post-Harvest Storage',
        titleBn: 'ফসল কর্তন ও সংগ্রহ',
        descriptionEn: 'Harvest mature crop and store in clean, dry, well-ventilated storage.',
        descriptionBn: 'পরিপুষ্ট ফসল সংগ্রহ করে পরিষ্কার ও শুকনো স্থানে সংরক্ষণ করুন।',
        category: 'harvest',
      ));

      // Remove duplicate days and sort chronologically
      final seenDays = <int>{};
      final uniqueList = <_TemplateEntry>[];
      for (final item in list) {
        if (!seenDays.contains(item.day)) {
          seenDays.add(item.day);
          uniqueList.add(item);
        }
      }
      uniqueList.sort((a, b) => a.day.compareTo(b.day));
      return uniqueList;
    }

    // Default Proportional
    pct(n) => (n * totalDays / 90).round().clamp(1, totalDays);
    return [
      const _TemplateEntry(
        day: 1,
        titleEn: 'Land Preparation & Basal Fertilizer',
        titleBn: 'জমি তৈরি ও প্রাথমিক সার',
        descriptionEn: 'Deep plowing and balanced basal fertilization.',
        descriptionBn: 'গভীর চাষ ও সুষম সার প্রয়োগ।',
        category: 'general',
      ),
      _TemplateEntry(
        day: pct(4),
        titleEn: 'Sowing / Transplanting Seedlings',
        titleBn: 'বপন বা চারা রোপণ',
        descriptionEn: 'Planting at correct row-to-row and plant spacing.',
        descriptionBn: 'সারিতে সঠিক দূরত্বে রোপণ।',
        category: 'general',
      ),
      _TemplateEntry(
        day: pct(12),
        titleEn: '1st Irrigation & Rooting Care',
        titleBn: '১ম সেচ ও আর্দ্রতা নিশ্চিতকরণ',
        descriptionEn: 'Essential irrigation for vigorous root establishment.',
        descriptionBn: 'শিকড়ের বৃদ্ধির জন্য সেচ।',
        category: 'irrigation',
      ),
      _TemplateEntry(
        day: pct(20),
        titleEn: 'Weeding & Soil Aeration',
        titleBn: 'আগাছা নিড়ানি',
        descriptionEn: 'Clear unwanted weeds and aerate topsoil.',
        descriptionBn: 'আগাছা পরিষ্কার ও মাটি আলগা করা।',
        category: 'weed',
      ),
      _TemplateEntry(
        day: pct(30),
        titleEn: '1st Top-Dressing Fertilizer',
        titleBn: '১ম কিস্তি সার প্রয়োগ',
        descriptionEn: 'Top-dress nitrogen and essential nutrients.',
        descriptionBn: 'ইউরিয়া ও সুষম সার প্রয়োগ।',
        category: 'fertilizer',
      ),
      _TemplateEntry(
        day: pct(45),
        titleEn: 'Pest & Disease Scouting',
        titleBn: 'বালাই ও পোকা দমন',
        descriptionEn: 'Inspect stems and foliage for symptoms.',
        descriptionBn: 'পাতা ও কাণ্ড পর্যবেক্ষণ।',
        category: 'pest',
      ),
      _TemplateEntry(
        day: pct(60),
        titleEn: '2nd Top-Dressing & Fruit Care',
        titleBn: '২য় কিস্তি সার ও সেচ',
        descriptionEn: 'Support flowering and fruit setting.',
        descriptionBn: 'ফুল ও ফল ধারণের পরিচর্যা।',
        category: 'fertilizer',
      ),
      _TemplateEntry(
        day: pct(78),
        titleEn: 'Maturity & Ripening Inspection',
        titleBn: 'পরিপুষ্টতা পরীক্ষা',
        descriptionEn: 'Monitor signs of full crop ripening.',
        descriptionBn: 'ফসল পাকার লক্ষণ পর্যবেক্ষণ।',
        category: 'general',
      ),
      _TemplateEntry(
        day: totalDays,
        titleEn: 'Harvest & Storage',
        titleBn: 'ফসল কর্তন ও সংরক্ষণ',
        descriptionEn: 'Harvest mature yield and store safely.',
        descriptionBn: 'ফসল সংগ্রহ ও সংরক্ষণ।',
        category: 'harvest',
      ),
    ];
  }
}

class _TemplateEntry {
  const _TemplateEntry({
    required this.day,
    required this.titleEn,
    required this.titleBn,
    required this.descriptionEn,
    required this.descriptionBn,
    required this.category,
  });
  final int day;
  final String titleEn;
  final String titleBn;
  final String descriptionEn;
  final String descriptionBn;
  final String category;
}
