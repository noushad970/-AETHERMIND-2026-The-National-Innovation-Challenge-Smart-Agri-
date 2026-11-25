import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../layout/app_navigation.dart';
import '../layout/desktop_page_frame.dart';
import '../widgets/auth_gate.dart';

import '../../features/ai_chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/ai_disease/presentation/screens/disease_detect_screen.dart';
import '../../features/ai_disease/presentation/screens/disease_result_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/community_feed/presentation/screens/community_feed_screen.dart';
import '../../features/crop_tracker/presentation/screens/add_crop_screen.dart';

import '../../features/crop_tracker/presentation/screens/crop_detail_screen.dart';
import '../../features/crop_tracker/presentation/screens/crop_library_screen.dart';
import '../../features/crop_tracker/presentation/screens/crop_list_screen.dart';

import '../../features/crop_tracker/presentation/screens/crop_live_track_screen.dart';
import '../../features/farm_records/presentation/screens/add_expense_screen.dart';
import '../../features/farm_records/presentation/screens/expense_list_screen.dart';
import '../../features/farm_records/presentation/screens/farm_records_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/fish_tracker/presentation/screens/add_fish_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_detail_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_list_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_live_track_screen.dart';
import '../../features/krishi_helpline/presentation/screens/krishi_helpline_screen.dart';
import '../../features/landing/presentation/screens/landing_screen.dart';
import '../../features/livestock/presentation/screens/add_livestock_screen.dart';
import '../../features/livestock/presentation/screens/livestock_detail_screen.dart';
import '../../features/livestock/presentation/screens/livestock_list_screen.dart';
import '../../features/livestock/presentation/screens/livestock_live_track_screen.dart';
import '../../features/market_prices/presentation/screens/market_prices_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/app_tutorial_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/smart_irrigation/presentation/screens/soil_irrigation_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
import '../../features/yield_forecaster/presentation/screens/yield_forecaster_screen.dart';
import 'app_routes.dart';

/// Generates [AppPageRoute]s for all named routes in [AppRoutes].
class AppRouter {
  AppRouter._();

  /// The website opens on a landing page; the apps open straight away.
  static const bool showLandingPage = kIsWeb;

  /// Starts the website on the landing page, whatever address was typed, so
  /// that every visit goes through the start screen and its sign-in check.
  static List<Route<dynamic>> landingInitialRoutes(String _) => [
    generate(const RouteSettings(name: AppRoutes.splash))!,
  ];

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(
          settings,
          (_) => showLandingPage ? const LandingScreen() : const SplashScreen(),
        );
      case AppRoutes.appStart:
        return _page(settings, (_) => const SplashScreen());
      case AppRoutes.onboarding:
        return _page(settings, (_) => const OnboardingScreen());
      case AppRoutes.appTutorial:
        return _page(settings, (_) => const AppTutorialScreen());
      case AppRoutes.login:
      case AppRoutes.register:
        return _page(settings, (_) => const LoginScreen());

      case AppRoutes.home:
        return _page(settings, (_) => const HomeScreen());

      // Crop tracker
      case AppRoutes.cropList:
        return _page(settings, (_) => const CropListScreen());
      case AppRoutes.addCrop:
        return _page(settings, (_) => const AddCropScreen());
      case AppRoutes.cropDetail:
        final cropId = settings.arguments as String;
        return _page(
          settings,
          (_) => CropDetailScreen(cropId: cropId),
        );
      case AppRoutes.cropLiveTrack:
        final cropId = settings.arguments as String;
        return _page(
          settings,
          (_) => CropLiveTrackScreen(cropId: cropId),
        );
      case AppRoutes.cropLibrary:
        return _page(settings, (_) => const CropLibraryScreen());

      // AI Disease
      case AppRoutes.diseaseDetect:
        return _page(settings, (_) => const DiseaseDetectScreen());
      case AppRoutes.diseaseResult:
        return _page(settings, (_) => const DiseaseResultScreen());

      // AI Chatbot
      case AppRoutes.chatbot:
        return _page(
          settings,
          (_) => const AuthGate(
            featureName: 'AI chat and saved conversation history',
            child: ChatbotScreen(),
          ),
        );

      // Weather
      case AppRoutes.weatherScreen:
        return _page(settings, (_) => const WeatherScreen());

      // Market prices
      case AppRoutes.marketPrices:
        return _page(settings, (_) => const MarketPricesScreen());

      // Farm records
      case AppRoutes.farmRecords:
        return _page(settings, (_) => const FarmRecordsScreen());
      case AppRoutes.expenseList:
        return _page(settings, (_) => const ExpenseListScreen());
      case AppRoutes.addExpense:
        return _page(settings, (_) => const AddExpenseScreen());

      // Notifications
      case AppRoutes.notifications:
        return _page(settings, (_) => const NotificationsScreen());

      // Livestock / poultry
      case AppRoutes.livestockList:
        return _page(settings, (_) => const LivestockListScreen());
      case AppRoutes.addLivestock:
        return _page(settings, (_) => const AddLivestockScreen());
      case AppRoutes.livestockDetail:
        final animalId = settings.arguments as String;
        return _page(
          settings,
          (_) => LivestockDetailScreen(animalId: animalId),
        );
      case AppRoutes.livestockLiveTrack:
        final animalId = settings.arguments as String;
        return _page(
          settings,
          (_) => LivestockLiveTrackScreen(animalId: animalId),
        );

      // Fish & Aquaculture (মৎস্য চাষ)
      case AppRoutes.fishList:
        return _page(settings, (_) => const FishListScreen());
      case AppRoutes.addFish:
        return _page(settings, (_) => const AddFishScreen());
      case AppRoutes.fishDetail:
        final pondId = settings.arguments as String;
        return _page(
          settings,
          (_) => FishDetailScreen(pondId: pondId),
        );
      case AppRoutes.fishLiveTrack:
        final pondId = settings.arguments as String;
        return _page(
          settings,
          (_) => FishLiveTrackScreen(pondId: pondId),
        );

      // Settings
      case AppRoutes.settings:
        return _page(settings, (_) => const SettingsScreen());

      // Krishi Helpline
      case AppRoutes.krishiHelpline:
        return _page(settings, (_) => const KrishiHelplineScreen());

      // Crop Yield & Revenue Forecaster
      case AppRoutes.yieldForecaster:
        return _page(settings, (_) => const YieldForecasterScreen());

      // Smart Irrigation
      case AppRoutes.smartIrrigation:
        return _page(settings, (_) => const SoilIrrigationScreen());

      // Community Agri Feed
      case AppRoutes.communityFeed:
        return _page(settings, (_) => const CommunityFeedScreen());

      default:
        return _unknownRoute(settings.name);
    }
  }

  /// Builds a named page, framed for desktop windows.
  static Route<dynamic> _page(RouteSettings settings, WidgetBuilder builder) =>
      AppPageRoute(
        routeName: settings.name,
        builder: (context) => DesktopPageFrame(
          style: DesktopPageStyle.forRoute(settings.name),
          child: builder(context),
        ),
      );

  static Route<dynamic> _unknownRoute(String? name) => MaterialPageRoute(
    builder: (_) =>
        Scaffold(body: Center(child: Text('Route not found: $name'))),
  );
}
