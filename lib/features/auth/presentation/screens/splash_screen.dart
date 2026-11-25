import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../data/services/crops_realtime_service.dart';
import '../../../../data/services/daily_suggestion_update_service.dart';
import '../../../livestock/presentation/providers/livestock_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../providers/auth_provider.dart';

/// Cinematic Agricultural Sunrise Splash Screen
/// Plays a live dawn-to-daylight sunrise animation over lush green fields
/// with live animated farmers working the land before transitioning into the app.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sunriseController;
  late final AnimationController _loopController;
  late final AuthProvider _auth;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();

    // 4-second cinematic sunrise timeline
    _sunriseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();

    // Continuous loop controller for live farmer & nature movements
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Auto-enter app after 2.8 seconds
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted && !_navigated) {
        _enterApp();
      }
    });

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initAndPreloadAppData());
  }

  Future<void> _initAndPreloadAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;

      if (hasCompletedOnboarding && mounted) {
        final notifProv = context.read<NotificationProvider>();
        await notifProv.loadLocalNotifications();

        if (mounted) {
          final crops = context.read<CropsRealtimeService>().snapshot;
          final animals = context.read<LivestockProvider>().animals;
          final weather = context.read<WeatherProvider>().data;
          final isBn = context.read<LocaleProvider>().isBangla;

          unawaited(
            notifProv.syncAndSchedule(
              crops: crops,
              animals: animals,
              weather: weather,
              isBn: isBn,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Startup data preload error: $e');
    }
  }

  Future<void> _enterApp() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    try {
      final updater = context.read<DailySuggestionUpdateService>();
      updater.start();
      unawaited(updater.run());
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding =
        prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;

    if (!mounted) return;

    if (!hasCompletedOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    if (_auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _sunriseController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = context.watch<LocaleProvider>().isBangla;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Animated Agricultural Canvas
          AnimatedBuilder(
            animation: Listenable.merge([_sunriseController, _loopController]),
            builder: (context, _) {
              return CustomPaint(
                painter: AgriculturalDawnSunrisePainter(
                  sunriseProgress: _sunriseController.value,
                  loopProgress: _loopController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Central App Branding & Localized Enter App Button
          SafeArea(
            child: AnimatedBuilder(
              animation: _sunriseController,
              builder: (context, child) {
                final val = _sunriseController.value;
                // Fade in starting at 35% of sunrise
                final opacity = ((val - 0.35) / 0.4).clamp(0.0, 1.0);
                final slideY = (1.0 - opacity) * 30;

                if (opacity <= 0.0) return const SizedBox.shrink();

                return Transform.translate(
                  offset: Offset(0, slideY),
                  child: Opacity(
                    opacity: opacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 50),

                          // Logo Shield with Radiant Glow
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/app_logo.png',
                              width: 76,
                              height: 76,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.agriculture_rounded,
                                size: 66,
                                color: Color(0xFF0F5C4A),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // App Title with Glassmorphism Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isBangla
                                      ? AppStrings.appNameBn
                                      : AppStrings.appName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isBangla
                                      ? AppStrings.appName
                                      : 'Smart Agriculture AI Assistant',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade200,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Localized Tagline Banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B7A5C).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isBangla
                                  ? '🌱 স্মার্ট কৃষির নতুন দিগন্ত'
                                  : '🌱 The New Era of Smart Agriculture',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Prominent Localized "Enter App" Button
                          Padding(
                            padding: const EdgeInsets.only(bottom: 28.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1B7A5C),
                                          Color(0xFF0F5C4A),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.amber.shade300,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2EA37B)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _enterApp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.agriculture_rounded,
                                            color: Colors.amberAccent,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            isBangla
                                                ? 'অ্যাপে প্রবেশ করুন'
                                                : 'Enter App',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isBangla
                                      ? '🌾 স্মার্ট কৃষি সেবায় আপনাকে স্বাগতম'
                                      : '🌾 Welcome to Smart Agriculture Platform',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich Vector Painter that draws the Sunrise, Sky Dawn, Lush Farmland,
/// Windmill, Swaying Paddy Stalks, and Live Animated Working Farmers.
class AgriculturalDawnSunrisePainter extends CustomPainter {
  AgriculturalDawnSunrisePainter({
    required this.sunriseProgress,
    required this.loopProgress,
  });

  final double sunriseProgress; // 0.0 (night) to 1.0 (bright day)
  final double loopProgress; // 0.0 to 1.0 loop for living movements

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawStarsAndMoon(canvas, size);
    _drawRisingSun(canvas, size);
    _drawClouds(canvas, size);
    _drawFlyingBirds(canvas, size);
    _drawDistantMountains(canvas, size);
    _drawFarmlandHills(canvas, size);
    _drawWindmill(canvas, size);
    _drawPaddyFields(canvas, size);
    _drawAnimatedFarmers(canvas, size);
    _drawForegroundCrops(canvas, size);
  }

  /// 1. Dynamic Sky: Interpolates from Night -> Sunrise Glow -> Bright Daytime
  void _drawSky(Canvas canvas, Size size) {
    // Gradient definitions
    const nightColors = [
      Color(0xFF03071E),
      Color(0xFF0B192C),
      Color(0xFF1E293B),
    ];

    const dawnColors = [
      Color(0xFF1E1B4B),
      Color(0xFF701A75),
      Color(0xFFEA580C),
      Color(0xFFFDE047),
    ];

    const dayColors = [
      Color(0xFF0284C7),
      Color(0xFF38BDF8),
      Color(0xFFBAE6FD),
      Color(0xFFFEF08A),
    ];

    List<Color> currentColors;
    if (sunriseProgress < 0.5) {
      final t = sunriseProgress / 0.5;
      currentColors = [
        Color.lerp(nightColors[0], dawnColors[0], t)!,
        Color.lerp(nightColors[1], dawnColors[1], t)!,
        Color.lerp(nightColors[2], dawnColors[2], t)!,
      ];
    } else {
      final t = (sunriseProgress - 0.5) / 0.5;
      currentColors = [
        Color.lerp(dawnColors[0], dayColors[0], t)!,
        Color.lerp(dawnColors[1], dayColors[1], t)!,
        Color.lerp(dawnColors[2], dayColors[2], t)!,
        Color.lerp(dawnColors[3], dayColors[3], t)!,
      ];
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: currentColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);
  }

  /// 2. Stars & Soft Moon (Fades out as dawn breaks)
  void _drawStarsAndMoon(Canvas canvas, Size size) {
    final nightOpacity = (1.0 - sunriseProgress * 2.2).clamp(0.0, 1.0);
    if (nightOpacity <= 0) return;

    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: nightOpacity * 0.9);

    // Fixed starry coordinates
    final stars = [
      const Offset(0.15, 0.08),
      const Offset(0.35, 0.12),
      const Offset(0.75, 0.06),
      const Offset(0.88, 0.14),
      const Offset(0.52, 0.18),
      const Offset(0.22, 0.22),
      const Offset(0.68, 0.25),
      const Offset(0.82, 0.28),
      const Offset(0.10, 0.32),
      const Offset(0.42, 0.05),
    ];

    for (int i = 0; i < stars.length; i++) {
      final pos = Offset(stars[i].dx * size.width, stars[i].dy * size.height);
      final twinkle = 0.5 + 0.5 * math.sin((loopProgress * 2 * math.pi) + i);
      final r = (1.2 + (i % 3) * 0.8) * twinkle;
      canvas.drawCircle(pos, r, starPaint);
    }

    // Crescent Moon
    final moonCenter = Offset(size.width * 0.18, size.height * 0.12);
    final moonPaint = Paint()
      ..color = Colors.amber.shade100.withValues(alpha: nightOpacity * 0.85);
    canvas.drawCircle(moonCenter, 14, moonPaint);

    final moonCutout = Paint()
      ..color = Color.lerp(
        const Color(0xFF03071E),
        const Color(0xFF1E1B4B),
        sunriseProgress,
      )!;
    canvas.drawCircle(moonCenter + const Offset(5, -4), 13, moonCutout);
  }

  /// 3. Radiant Rising Golden Sun with Expanding Corona and Rays
  void _drawRisingSun(Canvas canvas, Size size) {
    if (sunriseProgress < 0.1) return;

    final t = ((sunriseProgress - 0.1) / 0.9).clamp(0.0, 1.0);
    final startY = size.height * 0.65;
    final endY = size.height * 0.26;
    final sunY = startY + (endY - startY) * math.sin(t * math.pi / 2);
    final sunX = size.width * 0.5;
    final sunPos = Offset(sunX, sunY);

    final sunOpacity = (t * 1.5).clamp(0.0, 1.0);
    final sunRadius = 36.0 + 6.0 * math.sin(t * math.pi);

    // Expanding Corona Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.6 * sunOpacity),
          const Color(0xFFFF9800).withValues(alpha: 0.3 * sunOpacity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: sunPos, radius: 140));

    canvas.drawCircle(sunPos, 140, glowPaint);

    // Sun Rays (Rotating slowly)
    final rayPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.35 * sunOpacity)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rayCount = 12;
    final rayAngleOffset = loopProgress * math.pi / 3;
    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) + rayAngleOffset;
      final inner = sunPos + Offset(math.cos(angle) * (sunRadius + 8), math.sin(angle) * (sunRadius + 8));
      final outer = sunPos + Offset(math.cos(angle) * (sunRadius + 32), math.sin(angle) * (sunRadius + 32));
      canvas.drawLine(inner, outer, rayPaint);
    }

    // Sun Core
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: sunPos, radius: sunRadius));

    canvas.drawCircle(sunPos, sunRadius, sunPaint);
  }

  /// 4. Fluffy Morning Clouds Drifting
  void _drawClouds(Canvas canvas, Size size) {
    final cloudOpacity = (sunriseProgress * 1.2).clamp(0.0, 0.85);
    if (cloudOpacity <= 0) return;

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: cloudOpacity);

    // Cloud 1
    final c1X = ((size.width * 0.1) + (loopProgress * size.width * 0.25)) % (size.width + 100) - 50;
    _drawCloudShape(canvas, Offset(c1X, size.height * 0.18), 35, cloudPaint);

    // Cloud 2
    final c2X = ((size.width * 0.65) + (loopProgress * size.width * 0.15)) % (size.width + 100) - 50;
    _drawCloudShape(canvas, Offset(c2X, size.height * 0.14), 28, cloudPaint);
  }

  void _drawCloudShape(Canvas canvas, Offset pos, double r, Paint paint) {
    canvas.drawCircle(pos, r, paint);
    canvas.drawCircle(pos + Offset(r * 0.7, -r * 0.2), r * 0.8, paint);
    canvas.drawCircle(pos + Offset(-r * 0.7, r * 0.1), r * 0.65, paint);
    canvas.drawCircle(pos + Offset(r * 1.3, r * 0.2), r * 0.55, paint);
  }

  /// 5. Morning Birds Flying in V-Formation
  void _drawFlyingBirds(Canvas canvas, Size size) {
    if (sunriseProgress < 0.35) return;
    final birdOpacity = ((sunriseProgress - 0.35) / 0.4).clamp(0.0, 0.85);

    final birdPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: birdOpacity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final baseX = (loopProgress * (size.width + 120)) - 60;
    final baseY = size.height * 0.22;

    final offsets = [
      const Offset(0, 0),
      const Offset(-20, 10),
      const Offset(-40, 20),
      const Offset(-22, -12),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final pos = Offset(baseX + offsets[i].dx, baseY + offsets[i].dy + math.sin(loopProgress * 2 * math.pi + i) * 6);
      final wingFlap = math.sin((loopProgress * 8 * math.pi) + i) * 7;

      final path = Path();
      path.moveTo(pos.dx - 10, pos.dy + wingFlap);
      path.quadraticBezierTo(pos.dx - 5, pos.dy - 3, pos.dx, pos.dy);
      path.quadraticBezierTo(pos.dx + 5, pos.dy - 3, pos.dx + 10, pos.dy + wingFlap);

      canvas.drawPath(path, birdPaint);
    }
  }

  /// 6. Distant Misty Blue Mountains
  void _drawDistantMountains(Canvas canvas, Size size) {
    final mountainColor = Color.lerp(
      const Color(0xFF0F172A),
      const Color(0xFF5B8296),
      sunriseProgress,
    )!;

    final mPath = Path();
    final h = size.height * 0.55;
    mPath.moveTo(0, h);
    mPath.lineTo(size.width * 0.2, h - 35);
    mPath.lineTo(size.width * 0.45, h + 10);
    mPath.lineTo(size.width * 0.75, h - 45);
    mPath.lineTo(size.width, h - 10);
    mPath.lineTo(size.width, size.height);
    mPath.lineTo(0, size.height);
    mPath.close();

    canvas.drawPath(mPath, Paint()..color = mountainColor);
  }

  /// 7. Lush Rolling Green Farmland Hills
  void _drawFarmlandHills(Canvas canvas, Size size) {
    // Back Hill (Dark Forest to Deep Green)
    final backHillColor = Color.lerp(
      const Color(0xFF062816),
      const Color(0xFF1B7A5C),
      sunriseProgress,
    )!;

    final p1 = Path();
    p1.moveTo(0, size.height * 0.58);
    p1.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.50,
      size.width,
      size.height * 0.62,
    );
    p1.lineTo(size.width, size.height);
    p1.lineTo(0, size.height);
    p1.close();
    canvas.drawPath(p1, Paint()..color = backHillColor);

    // Mid Hill (Emerald Green to Rich Grass Green)
    final midHillColor = Color.lerp(
      const Color(0xFF0A3A1F),
      const Color(0xFF2EA37B),
      sunriseProgress,
    )!;

    final p2 = Path();
    p2.moveTo(0, size.height * 0.68);
    p2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.56,
      size.width,
      size.height * 0.70,
    );
    p2.lineTo(size.width, size.height);
    p2.lineTo(0, size.height);
    p2.close();
    canvas.drawPath(p2, Paint()..color = midHillColor);
  }

  /// 8. Rotating Windmill on the Hill
  void _drawWindmill(Canvas canvas, Size size) {
    final x = size.width * 0.82;
    final y = size.height * 0.57;

    final bodyColor = Color.lerp(
      const Color(0xFF1B2A1E),
      const Color(0xFFEDE7F6),
      sunriseProgress,
    )!;

    // Windmill Tower
    final towerPath = Path();
    towerPath.moveTo(x - 6, y + 25);
    towerPath.lineTo(x - 3, y);
    towerPath.lineTo(x + 3, y);
    towerPath.lineTo(x + 6, y + 25);
    towerPath.close();
    canvas.drawPath(towerPath, Paint()..color = bodyColor);

    // Rotating Blades
    final bladeAngle = loopProgress * 2 * math.pi;
    final bladePaint = Paint()
      ..color = bodyColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final a = bladeAngle + (i * math.pi / 2);
      final bx = x + math.cos(a) * 16;
      final by = y + math.sin(a) * 16;
      canvas.drawLine(Offset(x, y), Offset(bx, by), bladePaint);
    }
  }

  /// 9. Agricultural Paddy / Crop Rows
  void _drawPaddyFields(Canvas canvas, Size size) {
    final fieldColor = Color.lerp(
      const Color(0xFF0E4522),
      const Color(0xFF66BB6A),
      sunriseProgress,
    )!;

    final p3 = Path();
    p3.moveTo(0, size.height * 0.74);
    p3.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.66,
      size.width,
      size.height * 0.76,
    );
    p3.lineTo(size.width, size.height);
    p3.lineTo(0, size.height);
    p3.close();
    canvas.drawPath(p3, Paint()..color = fieldColor);

    // Perspective Crop Contour Lines
    final linePaint = Paint()
      ..color = Colors.yellow.shade700.withValues(alpha: 0.25 * sunriseProgress)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 4; i++) {
      final linePath = Path();
      final offsetY = size.height * (0.74 + i * 0.05);
      linePath.moveTo(0, offsetY);
      linePath.quadraticBezierTo(
        size.width * 0.5,
        offsetY - 20,
        size.width,
        offsetY + 10,
      );
      canvas.drawPath(linePath, linePaint);
    }
  }

  /// 10. Live Animated Farmers Working the Land
  void _drawAnimatedFarmers(Canvas canvas, Size size) {
    // -------------------------------------------------------------
    // FARMER 1 (Left Field): Planting / Harvesting crops with rhythmic arm swing
    // -------------------------------------------------------------
    final f1X = size.width * 0.28;
    final f1Y = size.height * 0.71;
    _drawHarvestingFarmer(canvas, Offset(f1X, f1Y), loopProgress);

    // -------------------------------------------------------------
    // FARMER 2 (Center/Right Ridge): Walking across field with harvest basket pole
    // -------------------------------------------------------------
    // Walks continuously across the middle ridge
    final walkProgress = (loopProgress * 1.2) % 1.0;
    final f2X = (size.width * 0.48) + (walkProgress * size.width * 0.42);
    final f2Y = size.height * 0.69 + math.sin(walkProgress * math.pi) * 4;
    _drawWalkingFarmer(canvas, Offset(f2X, f2Y), loopProgress);

    // -------------------------------------------------------------
    // FARMER 3 (Distant Field): Tending crops with hoe
    // -------------------------------------------------------------
    final f3X = size.width * 0.70;
    final f3Y = size.height * 0.64;
    _drawDistantFarmer(canvas, Offset(f3X, f3Y), loopProgress);
  }

  /// Farmer 1: Harvesting / Planting motion
  void _drawHarvestingFarmer(Canvas canvas, Offset pos, double time) {
    final farmerPaint = Paint()..color = const Color(0xFF0F5C4A);
    final skinPaint = Paint()..color = const Color(0xFFD7CCC8);
    final hatPaint = Paint()..color = const Color(0xFFD4A373); // Mathal (Straw Hat)
    final basketPaint = Paint()..color = const Color(0xFF8D6E63);

    final workMotion = math.sin(time * 3 * math.pi); // Rhythmic bend

    // Basket on ground beside farmer
    canvas.drawOval(
      Rect.fromCenter(center: pos + const Offset(16, 12), width: 14, height: 10),
      basketPaint,
    );

    // Legs / Lower body (Crouching)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 5, pos.dy + 4, 10, 10),
        const Radius.circular(3),
      ),
      farmerPaint,
    );

    // Torso (Bending forward and down)
    final torsoAngle = 0.2 + workMotion * 0.15;
    canvas.save();
    canvas.translate(pos.dx, pos.dy + 4);
    canvas.rotate(torsoAngle);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, -12, 8, 12),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF1B7A5C),
    );

    // Working Arm swinging down to crops
    final armPath = Path();
    armPath.moveTo(2, -8);
    armPath.lineTo(8 + workMotion * 4, 4 + workMotion * 6);
    canvas.drawPath(
      armPath,
      Paint()
        ..color = skinPaint.color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Head
    canvas.drawCircle(const Offset(0, -15), 4.5, skinPaint);

    // Mathal (Conical Straw Hat)
    final hatPath = Path();
    hatPath.moveTo(-11, -15);
    hatPath.lineTo(0, -23);
    hatPath.lineTo(11, -15);
    hatPath.close();
    canvas.drawPath(hatPath, hatPaint);

    canvas.restore();
  }

  /// Farmer 2: Walking with bamboo harvest pole & swinging baskets
  void _drawWalkingFarmer(Canvas canvas, Offset pos, double time) {
    final hatPaint = Paint()..color = const Color(0xFFD4A373);
    final skinPaint = Paint()..color = const Color(0xFFD7CCC8);
    final clothesPaint = Paint()..color = const Color(0xFF0277BD); // Blue shirt
    final polePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 2.0;
    final basketPaint = Paint()..color = const Color(0xFFA1887F);

    final walkCycle = math.sin(time * 6 * math.pi);

    // Animated Walking Legs
    final legPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pos + const Offset(-2, 4), pos + Offset(-2 - walkCycle * 4, 14), legPaint);
    canvas.drawLine(pos + const Offset(2, 4), pos + Offset(2 + walkCycle * 4, 14), legPaint);

    // Torso & Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx - 3.5, pos.dy - 8, 7, 12),
        const Radius.circular(2),
      ),
      clothesPaint,
    );
    canvas.drawCircle(pos + const Offset(0, -11), 3.5, skinPaint);

    // Mathal (Straw Hat)
    final hatPath = Path();
    hatPath.moveTo(pos.dx - 8, pos.dy - 12);
    hatPath.lineTo(pos.dx, pos.dy - 18);
    hatPath.lineTo(pos.dx + 8, pos.dy - 12);
    hatPath.close();
    canvas.drawPath(hatPath, hatPaint);

    // Bamboo shoulder pole (Baka / বাঁক)
    final poleY = pos.dy - 6 + walkCycle * 1.5;
    canvas.drawLine(Offset(pos.dx - 14, poleY), Offset(pos.dx + 14, poleY), polePaint);

    // Hanging Harvest Baskets
    canvas.drawLine(Offset(pos.dx - 13, poleY), Offset(pos.dx - 13, poleY + 8), polePaint);
    canvas.drawLine(Offset(pos.dx + 13, poleY), Offset(pos.dx + 13, poleY + 8), polePaint);

    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx - 13, poleY + 10), width: 8, height: 6), basketPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + 13, poleY + 10), width: 8, height: 6), basketPaint);
  }

  /// Farmer 3: Distant farmer tending crops
  void _drawDistantFarmer(Canvas canvas, Offset pos, double time) {
    final silhouette = Paint()..color = const Color(0xFF0F5C4A).withValues(alpha: 0.8);
    final hoeMotion = math.sin(time * 4 * math.pi);

    // Small Body & Hat
    canvas.drawCircle(pos + const Offset(0, -6), 2.5, silhouette);
    canvas.drawRect(Rect.fromLTWH(pos.dx - 2, pos.dy - 4, 4, 6), silhouette);

    // Hoe tool striking the ground
    final toolPaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 1.2;
    canvas.drawLine(pos + const Offset(1, -2), pos + Offset(6, 4 + hoeMotion * 2), toolPaint);
  }

  /// 11. Foreground Green and Golden Crops Swaying with Morning Wind
  void _drawForegroundCrops(Canvas canvas, Size size) {
    final stalkCount = 28;
    final stalkWidth = size.width / stalkCount;

    final cropPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF0F5C4A),
        const Color(0xFF8BC34A),
        sunriseProgress,
      )!
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final goldenHeadPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: sunriseProgress);

    final baseY = size.height;

    for (int i = 0; i < stalkCount; i++) {
      final x = i * stalkWidth + (i % 3) * 3;
      final stalkHeight = 35.0 + (i % 5) * 8;
      final windSway = math.sin((loopProgress * 2 * math.pi) + (i * 0.4)) * 6;

      final path = Path();
      path.moveTo(x, baseY);
      path.quadraticBezierTo(
        x + windSway * 0.5,
        baseY - stalkHeight * 0.6,
        x + windSway,
        baseY - stalkHeight,
      );

      canvas.drawPath(path, cropPaint);

      // Golden Grain Head at the top
      if (sunriseProgress > 0.4) {
        canvas.drawCircle(
          Offset(x + windSway, baseY - stalkHeight),
          2.5,
          goldenHeadPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AgriculturalDawnSunrisePainter oldDelegate) {
    return oldDelegate.sunriseProgress != sunriseProgress ||
        oldDelegate.loopProgress != loopProgress;
  }
}
