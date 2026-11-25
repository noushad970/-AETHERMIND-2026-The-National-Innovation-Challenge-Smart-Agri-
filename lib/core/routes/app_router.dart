import 'package:flutter/material.dart';

import '../widgets/auth_gate.dart';

import '../../features/ai_chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/ai_disease/presentation/screens/disease_detect_screen.dart';
import '../../features/ai_disease/presentation/screens/disease_result_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/crop_tracker/presentation/screens/add_crop_screen.dart';

import '../../features/crop_tracker/presentation/screens/crop_detail_screen.dart';
import '../../features/crop_tracker/presentation/screens/crop_library_screen.dart';
import '../../features/crop_tracker/presentation/screens/crop_list_screen.dart';

import '../../features/crop_tracker/presentation/screens/crop_live_track_screen.dart';
import '../../features/fish_tracker/presentation/screens/add_fish_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_detail_screen.dart';
import '../../features/fish_tracker/presentation/screens/fish_list_screen.dart';
import '../../features/livestock/presentation/screens/add_livestock_screen.dart';
import '../../features/livestock/presentation/screens/livestock_detail_screen.dart';
import '../../features/livestock/presentation/screens/livestock_list_screen.dart';
import '../../features/livestock/presentation/screens/livestock_live_track_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/app_tutorial_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
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
      default:
        return _unknownRoute(settings.name);
    }
  }

  static Route<dynamic> _unknownRoute(String? name) => MaterialPageRoute(
    builder: (_) =>
        Scaffold(body: Center(child: Text('Route not found: $name'))),
  );
}
