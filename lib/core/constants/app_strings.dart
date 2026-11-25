import 'package:flutter/material.dart';
import '../../core/providers/locale_provider.dart';

/// String constants and dynamic localization helper for Agri AI.
/// Provides full Bangla and English translations across the entire application.
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Agri AI';
  static const String appNameBn = 'এগ্রি এআই (Agri AI)';

  // Helper method to get localized string from context
  static String tr(BuildContext context, String en, String bn) {
    return context.isBn ? bn : en;
  }

  // Auth
  static const String login = 'Login';
  static const String loginBn = 'লগইন';
  static const String register = 'Register';
  static const String registerBn = 'নিবন্ধন';
  static const String userIdOrUsername = 'User ID / Username';
  static const String userIdOrUsernameBn = 'ইউজার আইডি / ইউজারনেম';
  static const String email = 'Email';
  static const String emailBn = 'ইমেইল';
  static const String password = 'Password';
  static const String passwordBn = 'পাসওয়ার্ড';
  static const String confirmPassword = 'Confirm Password';
  static const String confirmPasswordBn = 'পাসওয়ার্ড নিশ্চিত করুন';
  static const String fullName = 'Full Name';
  static const String fullNameBn = 'পূর্ণ নাম';
  static const String forgotPassword = 'Forgot password?';
  static const String forgotPasswordBn = 'পাসওয়ার্ড ভুলে গেছেন?';
  static const String noAccount = "Don't have an account?";
  static const String noAccountBn = 'অ্যাকাউন্ট নেই?';
  static const String haveAccount = 'Already have an account?';
  static const String haveAccountBn = 'ইতিমধ্যে অ্যাকাউন্ট আছে?';
  static const String logout = 'Logout';
  static const String logoutBn = 'লগআউট';
  static const String settings = 'Settings';
  static const String settingsBn = 'সেটিংস ও নিয়ন্ত্রণ';
  static const String exploreAsGuest = 'Explore Features as Guest (Testing)';
  static const String exploreAsGuestBn = 'গেস্ট হিসেবে ফিচার দেখুন (পরীক্ষামূলক)';

  // Fish & Aquaculture tracker
  static const String fishTracker = 'Fish Farming & Live Track';
  static const String fishTrackerBn = 'মৎস্য চাষ ও লাইভ ট্র্যাকিং';

  // Crop tracker
  static const String myCrops = 'My Crops';
  static const String myCropsBn = 'আমার ফসল';
  static const String addCrop = 'Add New Crop';
  static const String addCropBn = 'নতুন ফসল যোগ করুন';
  static const String cropType = 'Crop Type';
  static const String cropTypeBn = 'ফসলের ধরন';
  static const String plantingDate = 'Planting Date';
  static const String plantingDateBn = 'রোপণের তারিখ';
  static const String landArea = 'Land Area (decimal)';
  static const String landAreaDecimal = 'Land Area (decimal)';
  static const String landAreaBn = 'জমির পরিমাণ (শতক)';
  static const String numberOfTrees = 'Number of Trees';
  static const String numberOfTreesBn = 'গাছের সংখ্যা';
  static const String cropVariety = 'Crop Variety (optional)';
  static const String cropVarietyBn = 'ফসলের জাত (ঐচ্ছিক)';
  static const String variety = 'Variety';
  static const String varietyBn = 'জাত';
  static const String daysRemaining = 'Days Remaining';
  static const String daysRemainingBn = 'বাকি দিন';
  static const String currentStage = 'Current Stage';
  static const String currentStageBn = 'বর্তমান পর্যায়';
  static const String activities = 'Activities';
  static const String activitiesBn = 'কার্যক্রম';
  static const String completedActivities = 'Completed Activities';
  static const String completedActivitiesBn = 'সম্পন্ন কার্যক্রম';
  static const String upcomingActivities = 'Upcoming Activities';
  static const String upcomingActivitiesBn = 'আসন্ন কার্যক্রম';
  static const String estimatedHarvest = 'Estimated Harvest';
  static const String estimatedHarvestBn = 'আনুমানিক ফসল কাটার সময়';
  static const String cropHealth = 'Crop Health';
  static const String cropHealthBn = 'ফসলের স্বাস্থ্য';
  static const String markCompleted = 'Mark as Completed';
  static const String markCompletedBn = 'সম্পন্ন হিসেবে চিহ্নিত করুন';
  static const String addTree = 'Add Tree';
  static const String addTreeBn = 'গাছ যোগ করুন';
  static const String markDead = 'Mark as Dead';
  static const String markDeadBn = 'মৃত হিসেবে চিহ্নিত করুন';
  static const String newTree = 'Newly Planted Tree';
  static const String newTreeBn = 'নতুন রোপিত গাছ';
  static const String saveCrop = 'Save Crop';
  static const String saveCropBn = 'ফসল সংরক্ষণ করুন';
  static const String cropDetail = 'Crop Details';
  static const String cropDetailBn = 'ফসলের বিবরণ';
  static const String deleteCrop = 'Delete Crop';
  static const String deleteCropBn = 'ফসল মুছে ফেলুন';
  static const String activityTimeline = 'Activity Timeline';
  static const String activityTimelineBn = 'কাজের সময়রেখা';
  static const String notes = 'Notes';
  static const String notesBn = 'নোট / মন্তব্য';
  static const String daysOld = 'days old';
  static const String daysOldBn = 'দিন বয়স';
  static const String daysToHarvest = 'days to harvest';
  static const String daysToHarvestBn = 'দিন বাকি ফসল তুলতে';
  static const String readyToHarvest = 'Ready to harvest!';
  static const String readyToHarvestBn = 'ফসল তোলার উপযুক্ত সময়!';
  static const String decimal = 'decimal';
  static const String decimalBn = 'শতক';
  static const String trees = 'trees';
  static const String treesBn = 'টি গাছ';
  static const String orchard = 'Orchard Tracking';
  static const String orchardBn = 'বাগান ট্র্যাকিং';
  static const String total = 'Total';
  static const String totalBn = 'মোট';
  static const String newlyPlanted = 'Newly Planted';
  static const String newlyPlantedBn = 'নতুন রোপিত';
  static const String dead = 'Dead';
  static const String deadBn = 'মৃত';
  static const String live = 'Live';
  static const String liveBn = 'জীবিত';
  static const String updateTrees = 'Update Trees';
  static const String updateTreesBn = 'গাছের তথ্য আপডেট';
  static const String markDeadTrees = 'Mark Trees as Dead';
  static const String markDeadTreesBn = 'মৃত গাছ চিহ্নিত করুন';
  static const String addNewlyPlantedTrees = 'Add Newly Planted Trees';
  static const String addNewlyPlantedTreesBn = 'নতুন রোপিত গাছ যোগ করুন';
  static const String count = 'Count';
  static const String countBn = 'সংখ্যা';
  static const String noActivities = 'No activities scheduled yet.';
  static const String noActivitiesBn = 'এখনো কোনো কার্যক্রম নির্ধারিত হয়নি।';
  static const String noCropsYet = 'No crops yet';
  static const String noCropsYetBn = 'এখনো কোনো ফসল যুক্ত করা হয়নি';
  static const String addYourFirstCrop =
      'Plant your first crop to start tracking.';
  static const String addYourFirstCropBn =
      'ট্র্যাকিং শুরু করতে প্রথম ফসল রোপণ করুন।';
  static const String activeCrops = 'Active crops';
  static const String activeCropsBn = 'সক্রিয় ফসল';
  static const String viewAll = 'View all';
  static const String viewAllBn = 'সব দেখুন';
  static const String recentCrops = 'Recent Crops';
  static const String recentCropsBn = 'সাম্প্রতিক ফসল';
  static const String quickActions = 'Quick Actions';
  static const String quickActionsBn = 'দ্রুত সুবিধা';
  static const String goodMorning = 'Good morning';
  static const String goodMorningBn = 'শুভ সকাল';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodAfternoonBn = 'শুভ দুপুর';
  static const String goodEvening = 'Good evening';
  static const String goodEveningBn = 'শুভ সন্ধ্যা';
  static const String farmer = 'Farmer';
  static const String farmerBn = 'কৃষক ভাই';

  // AI Disease
  static const String aiDiseaseDetection = 'AI Disease Detection';
  static const String aiDiseaseDetectionBn = 'এআই রোগ নির্ণয়';
  static const String aiDiseaseDetect = 'AI Disease';
  static const String aiDiseaseDetectBn = 'এআই রোগ নির্ণয়';
  static const String uploadPhoto =
      'Upload a photo of the affected crop leaf or fruit';
  static const String uploadPhotoBn =
      'আক্রান্ত ফসলের পাতা বা ফলের ছবি আপলোড করুন';
  static const String tapToTakePhoto = 'Tap to take a photo';
  static const String tapToTakePhotoBn = 'ছবি তুলতে ট্যাপ করুন';
  static const String tapToChooseGallery = 'Choose from gallery';
  static const String tapToChooseGalleryBn = 'গ্যালারি থেকে বেছে নিন';
  static const String analyzing = 'Analyzing image...';
  static const String analyzingBn = 'ছবি বিশ্লেষণ করা হচ্ছে...';
  static const String diseaseName = 'Disease Name';
  static const String diseaseNameBn = 'রোগের নাম';
  static const String confidence = 'Confidence';
  static const String confidenceBn = 'নির্ভুলতার হার';
  static const String prevention = 'Prevention';
  static const String preventionBn = 'প্রতিরোধ ব্যবস্থা';
  static const String treatment = 'Treatment';
  static const String treatmentBn = 'চিকিৎসা ও প্রতিকার';
  static const String organicSolutions = 'Organic Solutions';
  static const String organicSolutionsBn = 'জৈব সমাধান';
  static const String chemicalSolutions = 'Chemical Solutions';
  static const String chemicalSolutionsBn = 'রাসায়নিক সমাধান';
  static const String solution = 'Solution';
  static const String solutionBn = 'সমাধান';
  static const String solutionLoading = 'Generating a step-by-step solution...';
  static const String solutionLoadingBn = 'ধাপে ধাপে সমাধান প্রস্তুত করা হচ্ছে...';
  static const String solutionError = 'Could not load the solution right now.';
  static const String solutionErrorBn = 'সমাধান লোড করা যায়নি। আবার চেষ্টা করুন।';
  static const String solutionRetry = 'Retry';
  static const String solutionRetryBn = 'পুনরায় চেষ্টা';
  static const String trainedDiseasesOnlyTitle = 'Trained diseases only';
  static const String trainedDiseasesOnlyTitleBn = 'শুধুমাত্র নির্ধারিত রোগসমূহ';
  static const String trainedDiseasesOnlyBody =
      'Only the diseases this offline model was trained on can be detected.';
  static const String trainedDiseasesOnlyBodyBn =
      'শুধুমাত্র এই মডেলটিতে প্রশিক্ষিত রোগসমূহ নিখুঁতভাবে শনাক্ত হবে।';

  // Chatbot
  static const String aiChatbot = 'AI Agricultural Chatbot';
  static const String aiChatbotBn = 'এআই কৃষি চ্যাটবট';
  static const String typeMessage = 'Type your question...';
  static const String typeMessageBn = 'আপনার কৃষি প্রশ্ন লিখুন...';
  static const String send = 'Send';
  static const String sendBn = 'পাঠান';

  // Weather
  static const String weather = 'Weather';
  static const String weatherBn = 'আবহাওয়া';
  static const String todayForecast = "Today's Forecast";
  static const String todayForecastBn = 'আজকের আবহাওয়া পূর্বাভাস';
  static const String farmingRecommendation = 'Farming Recommendation';
  static const String farmingRecommendationBn = 'আজকের কৃষি পরামর্শ';
  static const String humidity = 'Humidity';
  static const String humidityBn = 'বাতাসের আর্দ্রতা';
  static const String rainfall = 'Rainfall';
  static const String rainfallBn = 'বৃষ্টিপাত';
  static const String windSpeed = 'Wind Speed';
  static const String windSpeedBn = 'বাতাসের গতিবেগ';

  // Market
  static const String marketPrices = 'Market Prices';
  static const String marketPricesBn = 'বাজার দর';
  static const String lastUpdated = 'Last updated';
  static const String lastUpdatedBn = 'সর্বশেষ আপডেট';
  static const String pricePerKg = 'Price / kg (BDT)';
  static const String pricePerKgBn = 'মূল্য / কেজি (টাকা)';

  // Farm records
  static const String farmRecords = 'Farm Records';
  static const String farmRecordsBn = 'খামার হিসাব';
  static const String addExpense = 'Add Expense';
  static const String addExpenseBn = 'খরচ যোগ করুন';
  static const String amount = 'Amount (BDT)';
  static const String amountBn = 'পরিমাণ (টাকা)';
  static const String category = 'Category';
  static const String categoryBn = 'ক্যাটাগরি';
  static const String description = 'Description';
  static const String descriptionBn = 'বিবরণ';
  static const String estimatedYield = 'Estimated Yield';
  static const String estimatedYieldBn = 'আনুমানিক ফলন';

  // Notifications
  static const String notifications = 'Notifications';
  static const String notificationsBn = 'বিজ্ঞপ্তি';
  static const String reminderPrefix = 'Reminder: ';
  static const String reminderPrefixBn = 'অনুস্মারক: ';

  // Generic
  static const String save = 'Save';
  static const String saveBn = 'সংরক্ষণ';
  static const String cancel = 'Cancel';
  static const String cancelBn = 'বাতিল';
  static const String delete = 'Delete';
  static const String deleteBn = 'মুছে ফেলুন';
  static const String edit = 'Edit';
  static const String editBn = 'সম্পাদনা';
  static const String yes = 'Yes';
  static const String yesBn = 'হ্যাঁ';
  static const String no = 'No';
  static const String noBn = 'না';
  static const String loading = 'Loading...';
  static const String loadingBn = 'লোড হচ্ছে...';
  static const String error = 'Error';
  static const String errorBn = 'ত্রুটি';
  static const String retry = 'Retry';
  static const String retryBn = 'পুনরায় চেষ্টা';
  static const String ok = 'OK';
  static const String okBn = 'ঠিক আছে';
  static const String noData = 'No data available';
  static const String noDataBn = 'কোনো তথ্য নেই';
  static const String language = 'Language';
  static const String languageBn = 'ভাষা';
  static const String english = 'English';
  static const String bangla = 'বাংলা';

  // Livestock / poultry
  static const String livestock = 'Livestock & Poultry';
  static const String livestockBn = 'গবাদি পশু ও হাঁস-মুরগি';
  static const String livestockList = 'My animals';
  static const String livestockListBn = 'আমার পশু-পাখি';
  static const String addLivestock = 'Add animal';
  static const String addLivestockBn = 'নতুন পশু যোগ করুন';
  static const String livestockDetail = 'Animal details';
  static const String livestockDetailBn = 'পশুর বিবরণ';
  static const String liveTrack = 'Live track';
  static const String liveTrackBn = 'লাইভ ট্র্যাকিং';
  static const String noLivestockYet = 'No animals yet';
  static const String noLivestockYetBn = 'এখনো কোনো পশু যুক্ত করা হয়নি';
  static const String addYourFirstLivestock =
      'Add your first herd or flock to start tracking.';
  static const String addYourFirstLivestockBn =
      'ট্র্যাকিং শুরু করতে প্রথম পশু বা পাখির দল যোগ করুন।';
  static const String livestockSpecies = 'Species';
  static const String livestockSpeciesBn = 'প্রজাতি / ধরন';
  static const String livestockPurpose = 'Purpose';
  static const String livestockPurposeBn = 'উদ্দেশ্য';
  static const String livestockTotalCount = 'Total animals';
  static const String livestockTotalCountBn = 'মোট প্রাণীর সংখ্যা';
  static const String livestockStartDate = 'Start date';
  static const String livestockStartDateBn = 'শুরুর তারিখ';
  static const String saveAnimal = 'Save animal';
  static const String saveAnimalBn = 'সংরক্ষণ করুন';
  static const String deleteAnimal = 'Delete animal';
  static const String deleteAnimalBn = 'মুছে ফেলুন';
  static const String recordDailySummary = 'Record today';
  static const String recordDailySummaryBn = 'আজকের তথ্য রেকর্ড';
  static const String recordDeaths = 'Record deaths';
  static const String recordDeathsBn = 'মৃত্যু রেকর্ড';
  static const String deathsCount = 'Deaths today';
  static const String deathsCountBn = 'আজকের মৃত্যু';
  static const String eggsToday = 'Eggs today';
  static const String eggsTodayBn = 'আজকের ডিম (টি)';
  static const String milkLitersToday = 'Milk today (L)';
  static const String milkLitersTodayBn = 'আজকের দুধ (লিটার)';
  static const String feedKgToday = 'Feed today (kg)';
  static const String feedKgTodayBn = 'আজকের খাবার (কেজি)';
  static const String purposeMeat = 'Meat';
  static const String purposeMeatBn = 'মাংস';
  static const String purposeEgg = 'Egg';
  static const String purposeEggBn = 'ডিম';
  static const String purposeDairy = 'Milk';
  static const String purposeDairyBn = 'দুধ';
  static const String purposeMixed = 'Mixed';
  static const String purposeMixedBn = 'মিশ্র';
  static const String livestockActivityTimeline = 'Daily checklist';
  static const String livestockActivityTimelineBn = 'দৈনিক কাজের তালিকা';
  static const String todaysChecklist = "Today's tasks";
  static const String todaysChecklistBn = 'আজকের করণীয় কাজ';
  static const String todaysChecklistEmpty =
      'No tasks scheduled for today. Add one below.';
  static const String todaysChecklistEmptyBn =
      'আজকের জন্য কোনো কাজ নির্ধারিত নেই। নিচে যোগ করুন।';
  static const String recurringBadgeDaily = 'Daily';
  static const String recurringBadgeDailyBn = 'দৈনিক';
  static const String recurringBadgeWeekly = 'Weekly';
  static const String recurringBadgeWeeklyBn = 'সাপ্তাহিক';
  static const String livestockAiAdviceTitle = "Today's AI advice";
  static const String livestockAiAdviceTitleBn = 'আজকের এআই পরামর্শ';
  static const String liveAnimals = 'Live';
  static const String liveAnimalsBn = 'জীবিত';
  static const String deadAnimals = 'Dead';
  static const String deadAnimalsBn = 'মৃত';
  static const String totalAnimals = 'Total';
  static const String totalAnimalsBn = 'মোট';
  static const String recentDeaths = 'Recent deaths';
  static const String recentDeathsBn = 'সাম্প্রতিক মৃত্যু';
  static const String lastSummary = 'Last summary';
  static const String lastSummaryBn = 'সর্বশেষ রেকর্ড';
  static const String noSummaryYet = 'No daily summary recorded yet.';
  static const String noSummaryYetBn = 'এখনো কোনো দৈনিক রেকর্ড নেই।';
  static const String animalsCount = 'animals';
  static const String animalsCountBn = 'টি';
  static const String daysOnFarm = 'days on farm';
  static const String daysOnFarmBn = 'দিন খামারে';

  // Daily AI crop advice
  static const String aiAdviceTitle = "Today's AI advice";
  static const String aiAdviceTitleBn = 'আজকের এআই পরামর্শ';
  static const String aiAdviceThinking = 'Thinking…';
  static const String aiAdviceThinkingBn = 'বিশ্লেষণ করা হচ্ছে…';
  static const String aiAdviceEmpty =
      'Tap refresh to generate today\'s AI guidance for this crop.';
  static const String aiAdviceEmptyBn =
      'এই ফসলের জন্য আজকের এআই পরামর্শ পেতে রিফ্রেশ চাপুন।';
  static const String aiAdviceDo = 'Do today';
  static const String aiAdviceDoBn = 'আজকের করণীয়';
  static const String aiAdviceDont = 'Avoid today';
  static const String aiAdviceDontBn = 'আজ যা বর্জন করবেন';
  static const String refresh = 'Refresh';
  static const String refreshBn = 'রিফ্রেশ';

  // Krishi Call Center & Extension Officer Directory
  static const String krishiHelpline = 'Krishi Helpline';
  static const String krishiHelplineBn = 'কৃষি হেল্পলাইন';
  static const String krishiCallCenter = 'Krishi Call Center';
  static const String krishiCallCenterBn = 'কৃষি কল সেন্টার';
  static const String callCenter16123 = '16123 Call Center';
  static const String callCenter16123Bn = '১৬১২৩ কল সেন্টার';
  static const String callCenterSubtext = 'Official Govt Agri Advisory Hotline';
  static const String callCenterSubtextBn = 'সরকারি জাতীয় কৃষি পরামর্শ হটলাইন';
  static const String call16123Now = 'Call 16123 Now';
  static const String call16123NowBn = '১৬১২৩ নম্বরে এখনই কল করুন';
  static const String callHours = 'Sun - Thu: 9:00 AM - 5:00 PM';
  static const String callHoursBn = 'রবি - বৃহস্পতি: সকাল ৯:০০ - বিকাল ৫:০০';
  static const String searchOfficer = 'Search Upazila or Officer...';
  static const String searchOfficerBn = 'উপজেলা বা কর্মকর্তা খুঁজুন...';
  static const String allDivisions = 'All Divisions';
  static const String allDivisionsBn = 'সকল বিভাগ';
  static const String uaoTitle = 'Upazila Agriculture Officers (UAO)';
  static const String uaoTitleBn = 'উপজেলা কৃষি অফিসার (ইউএও)';
  static const String nationalHelplines = 'National Agricultural Helplines';
  static const String nationalHelplinesBn = 'জাতীয় কৃষি হেল্পলাইনসমূহ';
  static const String directCall = 'Call Direct';
  static const String directCallBn = 'সরাসরি কল';
  static const String callOfficer = 'Call Officer';
  static const String callOfficerBn = 'কল করুন';
  static const String sendSms = 'SMS';
  static const String sendSmsBn = 'এসএমএস';
  static const String daeHelpline = 'DAE Hotline';
  static const String daeHelplineBn = 'ডিএই হটলাইন';
  static const String daeNumber = '16333';
  static const String govtInfoHelpline = 'Govt Info Helpline';
  static const String govtInfoHelplineBn = 'সরকারি তথ্য বাতায়ন';
  static const String govtInfoNumber = '333';

  // Crop Yield & Revenue Forecaster
  static const String yieldForecaster = 'Yield Forecaster';
  static const String yieldForecasterTitle = 'Crop Yield & Revenue Forecaster';
  static const String yieldForecasterBn = 'ফলন ও আয় পূর্বাভাস';
  static const String selectCropPreset = 'Select Crop Preset';
  static const String selectCropPresetBn = 'ফসলের নমুনা নির্বাচন করুন';
  static const String expectedYieldPerDec = 'Expected Yield / decimal (kg)';
  static const String expectedYieldPerDecBn = 'শতকে প্রত্যাশিত ফলন (কেজি)';
  static const String expectedYieldMond = 'Expected Yield (Mond / মন)';
  static const String expectedYieldMondBn = 'প্রত্যাশিত ফলন (মন)';
  static const String sellingPricePerKg = 'Selling Price / kg (BDT)';
  static const String sellingPricePerKgBn = 'বিক্রয় মূল্য / কেজি (টাকা)';
  static const String sellingPricePerMond = 'Selling Price / Mond (BDT)';
  static const String sellingPricePerMondBn = 'বিক্রয় মূল্য / মন (টাকা)';
  static const String inputCostPerDec = 'Input Cost / decimal (BDT)';
  static const String inputCostPerDecBn = 'শতক প্রতি খরচ (টাকা)';
  static const String seedCost = 'Seeds & Seedlings (BDT)';
  static const String seedCostBn = 'বীজ ও চারা (টাকা)';
  static const String fertilizerCost = 'Fertilizers & Compost (BDT)';
  static const String fertilizerCostBn = 'সার ও কম্পোস্ট (টাকা)';
  static const String pesticideCost = 'Pesticides & Care (BDT)';
  static const String pesticideCostBn = 'বালাইনাশক ও পরিচর্যা (টাকা)';
  static const String irrigationCost = 'Irrigation & Fuel (BDT)';
  static const String irrigationCostBn = 'সেচ ও জ্বালানি (টাকা)';
  static const String laborCost = 'Labor & Tillage (BDT)';
  static const String laborCostBn = 'শ্রমিক ও চাষাবাদ (টাকা)';
  static const String totalProjectedYield = 'Total Estimated Harvest';
  static const String totalProjectedYieldBn = 'মোট আনুমানিক ফলন';
  static const String totalGrossRevenue = 'Projected Gross Revenue';
  static const String totalGrossRevenueBn = 'আনুমানিক মোট আয়';
  static const String totalInputCost = 'Total Input Investment';
  static const String totalInputCostBn = 'মোট বিনিয়োগ খরচ';
  static const String projectedNetProfit = 'Projected Net Profit';
  static const String projectedNetProfitBn = 'আনুমানিক নিট লাভ';
  static const String projectedNetLoss = 'Projected Net Loss';
  static const String projectedNetLossBn = 'আনুমানিক নিট ক্ষতি';
  static const String profitMargin = 'Profit Margin';
  static const String profitMarginBn = 'মুনাফার হার';
  static const String roi = 'Return on Investment (ROI)';
  static const String roiBn = 'বিনিয়োগে রিটার্ন (আরওআই)';
  static const String monds = 'Mond';
  static const String mondsBn = 'মন';
  static const String kg = 'kg';
  static const String kgBn = 'কেজি';

  // Soil Moisture & Smart Irrigation Calculator
  static const String smartIrrigation = 'Smart Irrigation';
  static const String smartIrrigationTitle = 'Soil Moisture & Irrigation Calculator';
  static const String smartIrrigationBn = 'মাটির আর্দ্রতা ও স্মার্ট সেচ';
  static const String selectSoilType = 'Select Field Soil Type';
  static const String selectSoilTypeBn = 'জমির মাটির ধরন নির্বাচন করুন';
  static const String claySoil = 'Etel / Clay (এঁটেল)';
  static const String claySoilBn = 'এঁটেল মাটি';
  static const String loamSoil = 'Doash / Loam (দোঁআশ)';
  static const String loamSoilBn = 'দোঁআশ মাটি';
  static const String sandySoil = 'Bele / Sandy (বেলে)';
  static const String sandySoilBn = 'বেলে মাটি';
  static const String sandyLoamSoil = 'Bele-Doash (বেলে-দোঁআশ)';
  static const String sandyLoamSoilBn = 'বেলে-দোঁআশ মাটি';
  static const String expectedRainfall = 'Expected Rain Forecast (mm)';
  static const String expectedRainfallBn = 'সম্ভাব্য বৃষ্টিপাত (মিমি)';
  static const String fetchLiveRain = 'Fetch Live Local Weather Rain';
  static const String fetchLiveRainBn = 'লাইভ আবহাওয়া থেকে বৃষ্টি আনুন';
  static const String totalWaterVolume = 'Total Required Water (Liters)';
  static const String totalWaterVolumeBn = 'মোট প্রয়োজনীয় পানি (লিটার)';
  static const String litersPerDecimal = 'Liters / decimal';
  static const String litersPerDecimalBn = 'লিটার / শতক';
  static const String pumpRuntime = 'Estimated Pump Runtime';
  static const String pumpRuntimeBn = 'আনুমানিক পাম্প চালানোর সময়';
  static const String minutes = 'minutes';
  static const String minutesBn = 'মিনিট';
  static const String liters = 'Liters';
  static const String litersBn = 'লিটার';
  static const String irrigateToday = 'Irrigate Today';
  static const String irrigateTodayBn = 'আজই সেচ প্রদান করুন';
  static const String lightIrrigation = 'Light Irrigation Needed';
  static const String lightIrrigationBn = 'হালকা সেচ প্রয়োজন';
  static const String holdIrrigationRain = 'Hold Off Irrigation - Rain Expected';
  static const String holdIrrigationRainBn = 'সেচ স্থগিত রাখুন - বৃষ্টির সম্ভাবনা';
  static const String irrigationInterval = 'Recommended Irrigation Interval';
  static const String irrigationIntervalBn = 'পরবর্তী সেচের ব্যবধান';

  // Community Agri Feed & Username
  static const String username = 'Username';
  static const String usernameBn = 'ইউজারনেম';
  static const String usernameHint = 'e.g. @rahim_farmer';
  static const String usernameHintBn = 'যেমন: @rahim_farmer';
  static const String enterUsername = 'Enter a valid username';
  static const String enterUsernameBn = 'সঠিক ইউজারনেম লিখুন';
  static const String communityFeed = 'Agri Feed';
  static const String communityFeedTitle = 'Community Farmers Feed';
  static const String communityFeedBn = 'কৃষক ফিড ও কমিউনিটি';
  static const String createPost = 'Create Post';
  static const String createPostBn = 'পোস্ট তৈরি করুন';
  static const String postContentHint =
      'Share updates, questions, or tips with fellow farmers...';
  static const String postContentHintBn =
      'সহকর্মী কৃষকদের সাথে আপনার ফসল, প্রশ্ন বা পরামর্শ শেয়ার করুন...';
  static const String addPhoto = 'Add Photo';
  static const String addPhotoBn = 'ছবি যুক্ত করুন';
  static const String post = 'Post';
  static const String postBn = 'পোস্ট করুন';
  static const String comments = 'Comments';
  static const String commentsBn = 'মন্তব্যসমূহ';
  static const String addComment = 'Add a comment...';
  static const String addCommentBn = 'মন্তব্য লিখুন...';
  static const String writeComment = 'Write a comment';
  static const String writeCommentBn = 'মন্তব্য লিখুন';
  static const String noPostsYet = 'No posts in the feed yet.';
  static const String noPostsYetBn = 'ফিডে এখনো কোনো পোস্ট নেই।';
  static const String createFirstPost =
      'Be the first farmer to share an update!';
  static const String createFirstPostBn =
      'প্রথম কৃষক হিসেবে আপনার আপডেট শেয়ার করুন!';
  static const String aiAdviceStale = 'Showing cached advice';
  static const String aiAdviceStaleBn = 'সংরক্ষিত পুরোনো পরামর্শ দেখানো হচ্ছে';
  static const String aiAdviceSourceOffline = 'Offline Template Engine';
  static const String aiAdviceSourceOfflineBn = 'অফলাইন টেমপ্লেট ইঞ্জিন';
  static const String aiAdviceSourceGemini = 'Gemini 2.5 Flash Cloud AI';
  static const String aiAdviceSourceGeminiBn = 'জেমিনি ২.৫ ফ্ল্যাশ ক্লাউড এআই';

  // Market Price Sources
  static const String sourceLive = 'Live DAM';
  static const String sourceLiveBn = 'লাইভ ডিএএম';
  static const String sourceCached = 'Cached DAM';
  static const String sourceCachedBn = 'ক্যাশড ডিএএম';
  static const String sourceMock = 'Offline Base';
  static const String sourceMockBn = 'অফলাইন বেস';
  static const String sourceMockBanner =
      'Showing offline baseline prices for Bangladeshi markets.';
  static const String sourceMockBannerBn =
      'বাংলাদেশের বাজারের অফলাইন ভিত্তিমূল্য প্রদর্শিত হচ্ছে।';
  static const String sourceErrorBanner =
      'Could not connect to DAM server. Showing fallback market prices.';
  static const String sourceErrorBannerBn =
      'বাজার সার্ভারে সংযোগ করা যায়নি। পূর্ববর্তী বাজারদর দেখানো হচ্ছে।';

  static const String smartIrrigationTitleBn = 'মাটির আর্দ্রতা ও সেচ ক্যালকুলেটর';
  static const String yieldForecasterTitleBn = 'ফলন ও রাজস্ব আয় পূর্বাভাস';
  static const String landAreaDecimalBn = 'জমির পরিমাণ (শতক)';

  static const String likesCount = 'likes';
  static const String likesCountBn = 'টি লাইক';
  static const String commentsCount = 'comments';
  static const String commentsCountBn = 'টি মন্তব্য';
  static const String loadingMorePosts = 'Loading more posts...';
  static const String loadingMorePostsBn = 'আরও পোস্ট লোড হচ্ছে...';

  static const String cropDirectory = '50 Crops Directory';
  static const String cropDirectoryBn = '৫০টি ফসল ডিরেক্টরি';
}
