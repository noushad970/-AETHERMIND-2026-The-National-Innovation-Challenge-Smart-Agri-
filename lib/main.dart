import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/crops_realtime_service.dart';
import 'data/services/crop_daily_suggestion_service.dart';
import 'data/services/chat_realtime_service.dart';
import 'data/services/daily_suggestion_update_service.dart';
import 'data/services/feeding_alarm_service.dart';
import 'data/services/fish_children_service.dart';
import 'data/services/fish_realtime_service.dart';
import 'data/services/livestock_children_service.dart';
import 'data/services/livestock_realtime_service.dart';
import 'data/repositories/daily_suggestion_repository.dart';
import 'data/repositories/fish_daily_suggestion_repository.dart';
import 'data/repositories/livestock_daily_suggestion_repository.dart';
import 'data/repositories/livestock_repository.dart';
import 'data/services/gemini_service.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/chatbot/presentation/providers/chatbot_provider.dart';
import 'features/crop_tracker/data/crop_summary_provider.dart';
import 'features/crop_tracker/presentation/providers/crops_provider.dart';
import 'features/crop_tracker/presentation/providers/daily_suggestions_provider.dart';
import 'features/ai_disease/presentation/providers/disease_detection_provider.dart';
import 'features/fish_tracker/presentation/providers/fish_daily_suggestions_provider.dart';
import 'features/fish_tracker/presentation/providers/fish_provider.dart';
import 'features/livestock/presentation/providers/livestock_daily_suggestions_provider.dart';
import 'features/livestock/presentation/providers/livestock_provider.dart';
import 'core/providers/animation_mode_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'features/weather/presentation/providers/weather_daily_advice_provider.dart';
import 'features/weather/presentation/providers/weather_provider.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/widgets/network_status_overlay.dart';
import 'data/services/network_monitor_service.dart';
import 'data/services/offline_sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting locales
  try {
    await initializeDateFormatting('bn_BD', null);
    await initializeDateFormatting('bn', null);
    await initializeDateFormatting('en', null);
  } catch (e) {
    debugPrint('Date formatting init skipped: $e');
  }

  // Initialize Hive and all offline sync storage boxes (Crops, Livestock, Fish, Chat)
  try {
    await Hive.initFlutter();
    await OfflineSyncManager.instance.init();
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  // Initialize network monitor for real-time mobile data & Wi-Fi connectivity
  try {
    await NetworkMonitorService.instance.init();
  } catch (e) {
    debugPrint('Network monitor init error: $e');
  }

  // Initialize timezone data needed by scheduled notifications.
  try {
    tz_data.initializeTimeZones();
  } catch (e) {
    debugPrint('Timezone init error: $e');
  }

  // Initialize local notifications.
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  // Initialize feeding alarm system with audio and heads-up channels
  try {
    await FeedingAlarmService.instance.init();
  } catch (e) {
    debugPrint('FeedingAlarmService init error: $e');
  }

  // Initialize Firebase.
  Object? firebaseInitError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    firebaseInitError = e;
    debugPrint('Firebase init skipped: $e\n$st');
  }

  runApp(AgriApp(firebaseInitError: firebaseInitError));
}

class AgriApp extends StatelessWidget {
  const AgriApp({super.key, this.firebaseInitError});

  /// Surfaces a Firebase init failure as a startup overlay so the user
  /// (and developer) can see why auth / cloud features are unavailable
  /// instead of just seeing a generic "Error" later.
  final Object? firebaseInitError;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AnimationModeProvider()),

        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CropsRealtimeService()),
        ChangeNotifierProvider(create: (_) => LivestockRealtimeService()),
        ChangeNotifierProvider(create: (_) => FishRealtimeService()),
        ChangeNotifierProvider(create: (_) => CropDailySuggestionService()),
        ChangeNotifierProvider(create: (_) => LivestockChildrenService()),
        ChangeNotifierProvider(create: (_) => FishChildrenService()),
        ChangeNotifierProvider.value(value: FeedingAlarmService.instance),
        ChangeNotifierProvider(create: (_) => ChatRealtimeService()),
        ChangeNotifierProxyProvider<AuthProvider, CropsProvider>(
          create: (ctx) =>
              CropsProvider(realtime: ctx.read<CropsRealtimeService>()),
          update: (ctx, _, prev) =>
              prev ?? CropsProvider(realtime: ctx.read<CropsRealtimeService>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CropSummaryProvider>(
          create: (ctx) =>
              CropSummaryProvider(realtime: ctx.read<CropsRealtimeService>()),
          update: (ctx, _, prev) =>
              prev ??
              CropSummaryProvider(realtime: ctx.read<CropsRealtimeService>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DailySuggestionsProvider>(
          create: (ctx) => DailySuggestionsProvider(
            realtime: ctx.read<CropDailySuggestionService>(),
            repository: DailySuggestionRepository(
              svc: ctx.read<CropDailySuggestionService>(),
            ),
          ),
          update: (ctx, _, prev) =>
              prev ??
              DailySuggestionsProvider(
                realtime: ctx.read<CropDailySuggestionService>(),
                repository: DailySuggestionRepository(
                  svc: ctx.read<CropDailySuggestionService>(),
                ),
              ),
        ),
        ChangeNotifierProvider(create: (_) => DiseaseDetectionProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatbotProvider>(
          create: (ctx) =>
              ChatbotProvider(chat: ctx.read<ChatRealtimeService>()),
          update: (ctx, _, prev) =>
              prev ?? ChatbotProvider(chat: ctx.read<ChatRealtimeService>()),
        ),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WeatherDailyAdviceProvider>(
          create: (ctx) =>
              WeatherDailyAdviceProvider(weather: ctx.read<WeatherProvider>()),
          update: (_, _, prev) => prev ?? WeatherDailyAdviceProvider(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..loadLocalNotifications()),

        ChangeNotifierProxyProvider<
          AuthProvider,
          LivestockDailySuggestionsProvider
        >(
          create: (ctx) => LivestockDailySuggestionsProvider(
            realtime: ctx.read<LivestockChildrenService>(),
            repository: LivestockDailySuggestionRepository(
              svc: ctx.read<LivestockChildrenService>(),
            ),
          ),
          update: (ctx, _, prev) =>
              prev ??
              LivestockDailySuggestionsProvider(
                realtime: ctx.read<LivestockChildrenService>(),
                repository: LivestockDailySuggestionRepository(
                  svc: ctx.read<LivestockChildrenService>(),
                ),
              ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, LivestockProvider>(
          create: (ctx) {
            final livestock = LivestockProvider(
              realtime: ctx.read<LivestockRealtimeService>(),
              repository: LivestockRepository(
                animals: ctx.read<LivestockRealtimeService>(),
                children: ctx.read<LivestockChildrenService>(),
              ),
            );
            final suggestions = ctx.read<LivestockDailySuggestionsProvider>();
            livestock.setSuggestionRefreshHook((animalId) {
              final animal = livestock.byId(animalId);
              if (animal == null) return;
              unawaited(suggestions.ensureToday(animal, null));
            });
            return livestock;
          },
          update: (_, _, prev) => prev ?? LivestockProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FishDailySuggestionsProvider>(
          create: (ctx) => FishDailySuggestionsProvider(
            realtime: ctx.read<FishChildrenService>(),
            repository: FishDailySuggestionRepository(
              svc: ctx.read<FishChildrenService>(),
            ),
          ),
          update: (ctx, _, prev) =>
              prev ??
              FishDailySuggestionsProvider(
                realtime: ctx.read<FishChildrenService>(),
                repository: FishDailySuggestionRepository(
                  svc: ctx.read<FishChildrenService>(),
                ),
              ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FishProvider>(
          create: (ctx) => FishProvider(
            realtime: ctx.read<FishRealtimeService>(),
            children: ctx.read<FishChildrenService>(),
          ),
          update: (ctx, _, prev) =>
              prev ??
              FishProvider(
                realtime: ctx.read<FishRealtimeService>(),
                children: ctx.read<FishChildrenService>(),
              ),
        ),
        Provider<DailySuggestionUpdateService>(
          create: (ctx) => DailySuggestionUpdateService(
            crops: ctx.read<CropsRealtimeService>(),
            livestock: ctx.read<LivestockRealtimeService>(),
            cropSuggestions: ctx.read<DailySuggestionsProvider>(),
            livestockSuggestions: ctx.read<LivestockDailySuggestionsProvider>(),
            weather: ctx.read<WeatherDailyAdviceProvider>(),
            gemini: GeminiService(),
          ),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(

        builder: (context, localeProv, themeProv, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            locale: localeProv.locale,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProv.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.generate,
            builder: (context, child) {
              Widget currentChild = child ?? const SizedBox();
              if (firebaseInitError != null) {
                currentChild = Stack(
                  children: [
                    currentChild,
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Firebase not configured',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  firebaseInitError.toString(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return NetworkStatusOverlay(child: currentChild);
            },
          );
        },
      ),
    );
  }
}

