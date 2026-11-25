/// Numeric and configuration constants.
class AppConstants {
  AppConstants._();

  // Onboarding & Preferences
  static const String hasCompletedOnboardingKey = 'has_completed_onboarding_v1';
  static const String lastLoggedInMobileKey = 'last_logged_in_mobile_v1';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String cropsCollection = 'crops';
  static const String expensesCollection = 'expenses';
  static const String diseaseScansCollection = 'disease_scans';
  static const String chatThreadsCollection = 'chat_threads';
  static const String dailySuggestionsCollection = 'daily_suggestions';
  static const String livestockCollection = 'livestock';
  static const String livestockActivitiesCollection = 'livestock_activities';
  static const String livestockDailySummariesCollection =
      'livestock_daily_summaries';
  static const String livestockDailySuggestionsCollection =
      'livestock_daily_suggestions';
  static const String fishPondsCollection = 'fish_ponds';
  static const String fishActivitiesCollection = 'fish_activities';
  static const String fishDailySummariesCollection = 'fish_daily_summaries';
  static const String fishDailySuggestionsCollection = 'fish_daily_suggestions';
  static const String marketPricesCollection = 'market_prices';

  // Firebase Storage
  static const String diseaseImagesFolder = 'disease_images';

  // Notifications
  static const String reminderChannelId = 'farming_reminders';
  static const String reminderChannelName = 'Farming Reminders';
  static const String reminderChannelDescription =
      'Reminders for crop activities (irrigation, fertilizer, harvest, etc.)';

  // Feeding Alarm Notification Channel (Heads-Up High Priority)
  static const String feedingAlarmChannelId = 'feeding_alarms_channel_v2';
  static const String feedingAlarmChannelName = 'Livestock & Fish Feeding Alarms';
  static const String feedingAlarmChannelDescription =
      'High priority heads-up alarms for fish, chicken, and duck feeding times';

  // API endpoints (Open-Meteo is free, no key needed)
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1';

  // Gemini API key loaded from --dart-define or .env
  // Run: flutter run --dart-define-from-file=.env
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Gemini model name. Override with --dart-define=GEMINI_MODEL=...
  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  // Disease detection
  static const double minDiseaseConfidence = 0.4;

  // Default crop growth days (used when adding a new crop)
  // The actual cultivation stages are computed by [services/crop_template_service.dart].
  static const Map<String, int> defaultCropGrowthDays = {
    'Rice': 90,
    'Wheat': 120,
    'Tomato': 80,
    'Potato': 90,
    'Mango': 1095, // 3 years for orchard tracking
    'Banana': 365,
    'Jute': 120,
    'Maize': 110,
    'Lentil': 110,
    'Onion': 120,
  };

  /// Crops shown in the add-crop dropdown.
  static const List<String> commonCrops = [
    'Rice',
    'Wheat',
    'Tomato',
    'Potato',
    'Mango',
    'Banana',
    'Jute',
    'Maize',
    'Lentil',
    'Onion',
  ];

  /// Activity category identifiers used by [CropActivity.category].
  static const String catIrrigation = 'irrigation';
  static const String catFertilizer = 'fertilizer';
  static const String catPest = 'pest';
  static const String catWeed = 'weed';
  static const String catHarvest = 'harvest';
  static const String catGeneral = 'general';

  // Livestock species shown in the add-animal dropdown.
  // "Poultry chicken" covers broilers (meat) and "Egg chicken" covers
  // layers — same species, different production purpose.
  static const List<String> livestockSpecies = [
    'Poultry chicken',
    'Egg chicken',
    'Duck',
    'Cow',
    'Goat',
    'Sheep',
  ];

  /// Production purpose for an [Animal]. Drives default activity
  /// templates (e.g. layers get daily egg-collection tasks, broilers
  /// get weight-check tasks).
  static const String purposeMeat = 'meat';
  static const String purposeEgg = 'egg';
  static const String purposeDairy = 'dairy';
  static const String purposeMixed = 'mixed';

  /// Returns the default purpose for a species. Users can override it
  /// on the add screen.
  static String defaultPurposeFor(String species) {
    switch (species) {
      case 'Poultry chicken':
        return purposeMeat;
      case 'Egg chicken':
        return purposeEgg;
      case 'Duck':
        return purposeEgg;
      case 'Cow':
        return purposeDairy;
      case 'Goat':
        return purposeDairy;
      case 'Sheep':
        return purposeMeat;
      default:
        return purposeMixed;
    }
  }

  /// Returns true if the species naturally produces eggs (layers
  /// and ducks). Poultry chicken (meat-purpose broilers) is NOT
  /// included because broilers are harvested before laying age —
  /// selecting "egg" for a broiler would be unrealistic.
  static bool isEggProducingSpecies(String species) {
    return species == 'Egg chicken' || species == 'Duck';
  }

  /// Returns true if the species produces milk (cows, goats,
  /// and to a lesser extent sheep). Sheep are NOT included by
  /// default — Bangladesh smallholders rarely milk sheep, and
  /// including them would confuse the milk-recording form.
  static bool isMilkProducingSpecies(String species) {
    return species == 'Cow' || species == 'Goat';
  }

  /// Returns true if [purpose] is sensible for [species]. The
  /// purpose dropdown on the add screen is filtered by this so
  /// users can't pair e.g. a cow with `purpose = egg`.
  static bool isPurposeAllowedForSpecies(String purpose, String species) {
    // Mixed is always allowed — it represents a small mixed
    // flock/herd where the farmer tracks everything together.
    if (purpose == purposeMixed) return true;
    switch (purpose) {
      case purposeEgg:
        return isEggProducingSpecies(species);
      case purposeDairy:
        return isMilkProducingSpecies(species);
      case purposeMeat:
        // Meat is the default universal purpose — every species
        // we support is ultimately kept for meat at end-of-life.
        return true;
      default:
        return false;
    }
  }

  /// The subset of [livestockPurposes] that's realistic for the
  /// given [species]. Drives the add-screen dropdown so users
  /// never see "Egg" as an option for a cow, or "Dairy" for a
  /// chicken. Always includes [purposeMixed] as the catch-all.
  static List<String> allowedPurposesForSpecies(String species) {
    final out = <String>[purposeMeat, purposeMixed];
    if (isEggProducingSpecies(species)) out.add(purposeEgg);
    if (isMilkProducingSpecies(species)) out.add(purposeDairy);
    return out;
  }

  /// Returns true if [category] is sensible to schedule for the
  /// given [species]. Used as defense-in-depth in the activity
  /// templates so a mismatched purpose (e.g. legacy data where
  /// a cow was tagged with `purpose = egg`) still doesn't seed
  /// egg-collection activities.
  static bool isCategoryAllowedForSpecies(String category, String species) {
    switch (category) {
      case lcatEggCollect:
        return isEggProducingSpecies(species);
      case lcatMilk:
        return isMilkProducingSpecies(species);
      default:
        // Feeding, water, cleaning, vaccination, health, weighing
        // are universal — every animal needs them.
        return true;
    }
  }

  /// [LivestockActivity.category] values.
  static const String lcatFeeding = 'feeding';
  static const String lcatWater = 'watering';
  static const String lcatCleaning = 'cleaning';
  static const String lcatVaccination = 'vaccination';
  static const String lcatHealth = 'health';
  static const String lcatEggCollect = 'egg_collect';
  static const String lcatMilk = 'milk';
  static const String lcatWeighing = 'weighing';
  static const String lcatGeneral = 'general';
}
