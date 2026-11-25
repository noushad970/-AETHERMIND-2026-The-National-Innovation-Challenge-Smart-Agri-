import 'package:flutter/material.dart';

import '../widgets/auth_gate.dart';

import '../../features/ai_chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/ai_disease/presentation/screens/disease_detect_screen.dart';
import '../../features/ai_disease/presentation/screens/disease_result_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/community_feed/presentation/screens/community_feed_screen.dart';
import '../../features/crop_tracker/presentation/screens/add_crop_screen.dart';

import '../../features/crop_tracker/presentation/screens/crop_detail_screen.dart';
import '../../features/crop_tracker/presentation/screens/crop_library_screen.dart';
import '../../features/crop_tracker/presentation/screens/crop_list_screen.dart';

import '../../features/crop_tracker/presentation/screens/crop_live_track_screen.dart';
import '../../features/farm_records/presentation/screens/add_expense_screen.dart';
import '../../features/farm_records/presentation/screens/expense_list_screen.dart';
import '../../features/farm_records/presentation/screens/farm_records_screen.dart';
import '../../features/fish_tracker/presentation/screens/add_fish_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_detail_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_list_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_live_track_screen.dart';
import '../../features/krishi_helpline/presentation/screens/krishi_helpline_screen.dart';
import '../../features/livestock/presentation/screens/add_livestock_screen.dart';
import '../../features/livestock/presentation/screens/livestock_detail_screen.dart';
import '../../features/livestock/presentation/screens/livestock_list_screen.dart';
import '../../features/livestock/presentation/screens/livestock_live_track_screen.dart';
import '../../features/market_prices/presentation/screens/market_prices_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/app_tutorial_screen.dart';
import '../../features/smart_irrigation/presentation/screens/soil_irrigation_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
import '../../features/yield_forecaster/presentation/screens/yield_forecaster_screen.dart';
import '../widgets/build_preview_screen.dart';
import 'app_routes.dart';

/// Generates [MaterialPageRoute]s for all named routes in [AppRoutes].
class AppRouter {
  AppRouter._();

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const BuildPreviewScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.appTutorial:
        return MaterialPageRoute(builder: (_) => const AppTutorialScreen());
      case AppRoutes.login:
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // Crop tracker
      case AppRoutes.cropList:
        return MaterialPageRoute(builder: (_) => const CropListScreen());
      case AppRoutes.addCrop:
        return MaterialPageRoute(builder: (_) => const AddCropScreen());
      case AppRoutes.cropDetail:
        final cropId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CropDetailScreen(cropId: cropId),
        );
      case AppRoutes.cropLiveTrack:
        final cropId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CropLiveTrackScreen(cropId: cropId),
        );
      case AppRoutes.cropLibrary:
        return MaterialPageRoute(builder: (_) => const CropLibraryScreen());

      // AI Disease
      case AppRoutes.diseaseDetect:
        return MaterialPageRoute(builder: (_) => const DiseaseDetectScreen());
      case AppRoutes.diseaseResult:
        return MaterialPageRoute(builder: (_) => const DiseaseResultScreen());

      // AI Chatbot
      case AppRoutes.chatbot:
        return MaterialPageRoute(
          builder: (_) => const AuthGate(
            featureName: 'AI chat and saved conversation history',
            child: ChatbotScreen(),
          ),
        );

      // Weather
      case AppRoutes.weatherScreen:
        return MaterialPageRoute(builder: (_) => const WeatherScreen());

      // Market prices
      case AppRoutes.marketPrices:
        return MaterialPageRoute(builder: (_) => const MarketPricesScreen());

      // Farm records
      case AppRoutes.farmRecords:
        return MaterialPageRoute(builder: (_) => const FarmRecordsScreen());
      case AppRoutes.expenseList:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen());
      case AppRoutes.addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());

      // Notifications
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // Livestock / poultry
      case AppRoutes.livestockList:
        return MaterialPageRoute(builder: (_) => const LivestockListScreen());
      case AppRoutes.addLivestock:
        return MaterialPageRoute(builder: (_) => const AddLivestockScreen());
      case AppRoutes.livestockDetail:
        final animalId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => LivestockDetailScreen(animalId: animalId),
        );
      case AppRoutes.livestockLiveTrack:
        final animalId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => LivestockLiveTrackScreen(animalId: animalId),
        );

      // Fish & Aquaculture (মৎস্য চাষ)
      case AppRoutes.fishList:
        return MaterialPageRoute(builder: (_) => const FishListScreen());
      case AppRoutes.addFish:
        return MaterialPageRoute(builder: (_) => const AddFishScreen());
      case AppRoutes.fishDetail:
        final pondId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => FishDetailScreen(pondId: pondId),
        );
      case AppRoutes.fishLiveTrack:
        final pondId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => FishLiveTrackScreen(pondId: pondId),
        );

      // Krishi Helpline
      case AppRoutes.krishiHelpline:
        return MaterialPageRoute(builder: (_) => const KrishiHelplineScreen());

      // Crop Yield & Revenue Forecaster
      case AppRoutes.yieldForecaster:
        return MaterialPageRoute(builder: (_) => const YieldForecasterScreen());

      // Smart Irrigation
      case AppRoutes.smartIrrigation:
        return MaterialPageRoute(builder: (_) => const SoilIrrigationScreen());

      // Community Agri Feed
      case AppRoutes.communityFeed:
        return MaterialPageRoute(builder: (_) => const CommunityFeedScreen());
      default:
        return _unknownRoute(settings.name);
    }
  }

  static Route<dynamic> _unknownRoute(String? name) => MaterialPageRoute(
    builder: (_) =>
        Scaffold(body: Center(child: Text('Route not found: $name'))),
  );
}
