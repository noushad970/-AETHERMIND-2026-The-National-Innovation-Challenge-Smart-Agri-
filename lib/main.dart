import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'core/providers/animation_mode_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';

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

