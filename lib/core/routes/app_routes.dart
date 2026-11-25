/// Centralized route names for [AppRouter].
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String appTutorial = '/app-tutorial';
  static const String login = '/login';
  static const String register = '/register';
  static const String phoneLogin = '/login'; // alias for backward compatibility

  static const String home = '/home';
  static const String addCrop = '/crop/add';
  static const String cropDetail = '/crop/detail'; // expects [cropId] arg
  static const String cropList = '/crop/list';
  static const String diseaseDetect = '/disease';
  static const String diseaseResult = '/disease/result';
  static const String chatbot = '/chatbot';
  static const String weatherScreen = '/weather';
  static const String marketPrices = '/market';
  static const String farmRecords = '/farm-records';
  static const String notifications = '/notifications';
  static const String expenseList = '/farm-records/expenses';
  static const String addExpense = '/farm-records/expenses/add';
  static const String cropLibrary = '/library/crops';
  static const String cropLiveTrack = '/crop/live-track'; // expects [cropId]
  static const String pestLibrary = '/library/pests';

  // Livestock / poultry
  static const String livestockList = '/livestock';
  static const String addLivestock = '/livestock/add';
  static const String livestockDetail =
      '/livestock/detail'; // expects [animalId] arg
  static const String livestockLiveTrack =
      '/livestock/live-track'; // expects [animalId] arg

  // Fish & Aquaculture (মৎস্য চাষ)
  static const String fishList = '/fish';
  static const String addFish = '/fish/add';
  static const String fishDetail = '/fish/detail'; // expects [pondId] arg
  static const String fishLiveTrack = '/fish/live-track'; // expects [pondId] arg

  // Settings & Control Panel
  static const String settings = '/settings';

  // Krishi Helpline / Extension Directory
  static const String krishiHelpline = '/krishi-helpline';

  // Crop Yield & Revenue Forecaster
  static const String yieldForecaster = '/yield-forecaster';

  // Soil Moisture & Smart Irrigation Calculator
  static const String smartIrrigation = '/smart-irrigation';

  // Community Agri Feed
  static const String communityFeed = '/community-feed';
}




