import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../providers/animation_mode_provider.dart';
import 'loop_clock.dart';

/// Living Agriculture Farmland Background.
///
/// In animated mode the landscape moves at a capped 30 fps and sits in its own
/// [RepaintBoundary], so scrolling content above it is never repainted by the
/// animation. In static mode a single frame is painted once and cached: no
/// ticker, no particles, no repaints.
///
/// Landscape elements:
/// - Dynamic Sky with Radiant Sun & Solar Corona Rays
/// - Drifting Clouds & Flying Bird Formations
/// - Rolling Green Paddy Hills & Terraces
/// - Rotating Hilltop Windmill
/// - Winding Irrigation Canal with Sunlight Shimmer
/// - Animated Working Farmers in the Field
/// - Wind-swayed Crop Stalks & Floating Golden Pollen Particles
class AgriAtmosphericBackground extends StatefulWidget {
  const AgriAtmosphericBackground({
    super.key,
    required this.child,
    this.isRainy = false,
    this.particleColor,
  });

  final Widget child;
  final bool isRainy;
  final Color? particleColor;

  @override
  State<AgriAtmosphericBackground> createState() =>
      _AgriAtmosphericBackgroundState();
}

class _AgriAtmosphericBackgroundState extends State<AgriAtmosphericBackground>
    with SingleTickerProviderStateMixin {
  /// Frame shown in static mode (sun high, clouds mid-sky).
  static const double _staticProgress = 0.2;

  late final LoopClock _clock = LoopClock(
    vsync: this,
    period: const Duration(seconds: 8),
    maxFps: 30,
  );
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _Particle(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          size: _rng.nextDouble() * 3.5 + 1.5,
          speed: _rng.nextDouble() * 0.4 + 0.2,
          opacity: _rng.nextDouble() * 0.4 + 0.3,
          wobbleOffset: _rng.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.animationsEnabled) {
      _clock.start();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final animate = context.animationsEnabled;
    final ValueListenable<double> progress =
        animate ? _clock : const _FixedProgress(_staticProgress);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Farmland landscape canvas (own layer; cached when static).
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _LivingFarmlandLandscapePainter(
                clock: progress,
                isDark: isDark,
                isRainy: widget.isRainy,
              ),
              size: Size.infinite,
            ),
          ),
        ),

        // 2. Floating pollen / rain particles (animated mode only).
        if (animate)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AtmosphericPollenPainter(
                  particles: _particles,
                  clock: _clock,
                  color: widget.particleColor ??
                      (widget.isRainy
                          ? Colors.lightBlueAccent
                          : (isDark
                              ? const Color(0xFFFFE082)
                              : const Color(0xFFC8E6C9))),
                  isRainy: widget.isRainy,
                ),
              ),
            ),
          ),

        // 3. Subtle tint overlay (keeps text readable over the landscape).
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),

        // 4. Foreground scrollable content.
        widget.child,
      ],
    );
  }
}

/// A [ValueListenable] that never changes (used for the static frame).
class _FixedProgress implements ValueListenable<double> {
  const _FixedProgress(this.value);

  @override
  final double value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wobbleOffset,
  });

  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final double wobbleOffset;
}

class _AtmosphericPollenPainter extends CustomPainter {
  _AtmosphericPollenPainter({
    required this.particles,
    required this.clock,
    required this.color,
    required this.isRainy,
  }) : super(repaint: clock);

  final List<_Particle> particles;
  final ValueListenable<double> clock;
  double get progress => clock.value;
  final Color color;
  final bool isRainy;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final curY = (p.y + progress * p.speed) % 1.0;
      final curX = isRainy
          ? p.x
          : (p.x + math.sin(progress * math.pi * 2 + p.wobbleOffset) * 0.04) % 1.0;

      final posX = curX * size.width;
      final posY = curY * size.height;

      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity * 0.38)
        ..style = PaintingStyle.fill;

      if (isRainy) {
        canvas.drawLine(
          Offset(posX, posY),
          Offset(posX - 2, posY + p.size * 3.5),
          paint..strokeWidth = 1.4,
        );
      } else {
        canvas.drawCircle(Offset(posX, posY), p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphericPollenPainter oldDelegate) {
    return oldDelegate.clock != clock ||
        oldDelegate.color != color ||
        oldDelegate.isRainy != isRainy;
  }
}

/// Vector Painter rendering a full rural Bangladeshi farmland panorama with
/// animated natural elements.
class _LivingFarmlandLandscapePainter extends CustomPainter {
  _LivingFarmlandLandscapePainter({
    required this.clock,
    required this.isDark,
    required this.isRainy,
  }) : super(repaint: clock);

  final ValueListenable<double> clock;
  double get loopProgress => clock.value;
  final bool isDark;
  final bool isRainy;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawSunOrMoon(canvas, size);
    _drawClouds(canvas, size);
    _drawBirds(canvas, size);
    _drawMountains(canvas, size);
    _drawRollingHills(canvas, size);
    _drawWindmill(canvas, size);
    _drawIrrigationRiver(canvas, size);
    _drawPaddyFields(canvas, size);
    _drawFarmers(canvas, size);
    _drawForegroundCropBreeze(canvas, size);
  }

  // 1. Sky Gradient
  void _drawSky(Canvas canvas, Size size) {
    final colors = isDark
        ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
        : (isRainy
            ? [const Color(0xFF4B6CB7), const Color(0xFF182848)]
            : [const Color(0xFF0288D1), const Color(0xFF4FC3F7), const Color(0xFFE1F5FE)]);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  // 2. Radiant Sun & Solar Rays
  void _drawSunOrMoon(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.78, size.height * 0.16);
    final r = 32.0;

    if (isDark) {
      // Crescent Moon
      final moonPaint = Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.85);
      canvas.drawCircle(center, 18, moonPaint);
      final cutout = Paint()..color = const Color(0xFF1B2C38);
      canvas.drawCircle(center + const Offset(6, -4), 16, cutout);
      return;
    }

    // Solar Corona Shimmer
    final shimmer = 0.5 + 0.5 * math.sin(loopProgress * 2 * math.pi);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.45 + shimmer * 0.1),
          const Color(0xFFFF9800).withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 100));
    canvas.drawCircle(center, 100, glowPaint);

    // Rotating Sun Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.35)
      ..strokeWidth = 2.0;
    final rayCount = 10;
    final angleOffset = loopProgress * math.pi / 2;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi / rayCount) + angleOffset;
      final p1 = center + Offset(math.cos(angle) * (r + 6), math.sin(angle) * (r + 6));
      final p2 = center + Offset(math.cos(angle) * (r + 24), math.sin(angle) * (r + 24));
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Sun Sphere
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, sunPaint);
  }

  // 3. Drifting Clouds
  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : (isRainy ? Colors.blueGrey.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.65));

    // Cloud 1
    final c1X = ((size.width * 0.15) + (loopProgress * size.width * 0.35)) % (size.width + 120) - 60;
    _drawCloudShape(canvas, Offset(c1X, size.height * 0.12), 26, cloudPaint);

    // Cloud 2
    final c2X = ((size.width * 0.60) + (loopProgress * size.width * 0.20)) % (size.width + 120) - 60;
    _drawCloudShape(canvas, Offset(c2X, size.height * 0.20), 20, cloudPaint);
  }

  void _drawCloudShape(Canvas canvas, Offset pos, double r, Paint paint) {
    canvas.drawCircle(pos, r, paint);
    canvas.drawCircle(pos + Offset(r * 0.7, -r * 0.2), r * 0.75, paint);
    canvas.drawCircle(pos + Offset(-r * 0.7, r * 0.1), r * 0.6, paint);
    canvas.drawCircle(pos + Offset(r * 1.2, r * 0.2), r * 0.5, paint);
  }

  // 4. Flying Birds
  void _drawBirds(Canvas canvas, Size size) {
    final birdPaint = Paint()
      ..color = isDark ? Colors.white54 : const Color(0xFF1E293B).withValues(alpha: 0.65)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final baseX = (loopProgress * (size.width + 100)) - 50;
    final baseY = size.height * 0.15;

    for (int i = 0; i < 3; i++) {
      final pos = Offset(
        baseX - (i * 22),
        baseY + (i * 12) + math.sin(loopProgress * 2 * math.pi + i) * 4,
      );
      final flap = math.sin((loopProgress * 6 * math.pi) + i) * 5;

      final path = Path();
      path.moveTo(pos.dx - 8, pos.dy + flap);
      path.quadraticBezierTo(pos.dx - 4, pos.dy - 2, pos.dx, pos.dy);
      path.quadraticBezierTo(pos.dx + 4, pos.dy - 2, pos.dx + 8, pos.dy + flap);
      canvas.drawPath(path, birdPaint);
    }
  }

  // 5. Distant Misty Mountains
  void _drawMountains(Canvas canvas, Size size) {
    final mountainPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1B3B2B).withValues(alpha: 0.6)
          : const Color(0xFF4A7C59).withValues(alpha: 0.45);

    final mPath = Path();
    final h = size.height * 0.42;
    mPath.moveTo(0, h);
    mPath.lineTo(size.width * 0.25, h - 30);
    mPath.lineTo(size.width * 0.50, h + 10);
    mPath.lineTo(size.width * 0.80, h - 35);
    mPath.lineTo(size.width, h - 8);
    mPath.lineTo(size.width, size.height);
    mPath.lineTo(0, size.height);
    mPath.close();

    canvas.drawPath(mPath, mountainPaint);
  }

  // 6. Lush Rolling Farmland Hills
  void _drawRollingHills(Canvas canvas, Size size) {
    // Back Hill (Deep Forest Green)
    final backHillColor = isDark ? const Color(0xFF0F381E) : const Color(0xFF1B7A5C);
    final p1 = Path();
    p1.moveTo(0, size.height * 0.46);
    p1.quadraticBezierTo(size.width * 0.45, size.height * 0.38, size.width, size.height * 0.48);
    p1.lineTo(size.width, size.height);
    p1.lineTo(0, size.height);
    p1.close();
    canvas.drawPath(p1, Paint()..color = backHillColor.withValues(alpha: 0.85));

    // Mid Hill (Emerald Green)
    final midHillColor = isDark ? const Color(0xFF0F5C4A) : const Color(0xFF388E3C);
    final p2 = Path();
    p2.moveTo(0, size.height * 0.56);
    p2.quadraticBezierTo(size.width * 0.55, size.height * 0.46, size.width, size.height * 0.58);
    p2.lineTo(size.width, size.height);
    p2.lineTo(0, size.height);
    p2.close();
    canvas.drawPath(p2, Paint()..color = midHillColor.withValues(alpha: 0.9));
  }

  // 7. Rotating Hilltop Windmill
  void _drawWindmill(Canvas canvas, Size size) {
    final wx = size.width * 0.85;
    final wy = size.height * 0.45;

    // Tower
    final towerPath = Path();
    towerPath.moveTo(wx - 7, wy + 26);
    towerPath.lineTo(wx - 4, wy);
    towerPath.lineTo(wx + 4, wy);
    towerPath.lineTo(wx + 7, wy + 26);
    towerPath.close();

    canvas.drawPath(
      towerPath,
      Paint()..color = isDark ? Colors.white30 : Colors.white70,
    );

    // Rotating Blades
    final hub = Offset(wx, wy);
    final bladeAngle = loopProgress * 2 * math.pi;
    final bladePaint = Paint()
      ..color = isDark ? Colors.white60 : Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final a = bladeAngle + (i * math.pi / 2);
      final tip = hub + Offset(math.cos(a) * 18, math.sin(a) * 18);
      canvas.drawLine(hub, tip, bladePaint);
    }
    canvas.drawCircle(hub, 3, Paint()..color = const Color(0xFFB71C1C));
  }

  // 8. Winding Irrigation River / Canal
  void _drawIrrigationRiver(Canvas canvas, Size size) {
    final riverPath = Path();
    riverPath.moveTo(size.width * 0.30, size.height * 0.55);
    riverPath.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.65,
      size.width * 0.35,
      size.height * 0.80,
    );
    riverPath.quadraticBezierTo(
      size.width * 0.20,
      size.height * 0.95,
      size.width * 0.10,
      size.height,
    );
    riverPath.lineTo(size.width * 0.24, size.height);
    riverPath.quadraticBezierTo(
      size.width * 0.32,
      size.height * 0.92,
      size.width * 0.44,
      size.height * 0.80,
    );
    riverPath.quadraticBezierTo(
      size.width * 0.58,
      size.height * 0.64,
      size.width * 0.36,
      size.height * 0.55,
    );
    riverPath.close();

    final riverPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [const Color(0xFF006064), const Color(0xFF00838F)]
            : [const Color(0xFF4DD0E1), const Color(0xFF00ACC1)],
      ).createShader(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45));

    canvas.drawPath(riverPath, riverPaint);

    // River Water Glint / Shimmer
    final shimmerOffset = (loopProgress * 40) % 25;
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width * 0.38 + shimmerOffset, size.height * 0.70),
      Offset(size.width * 0.44 + shimmerOffset, size.height * 0.71),
      glintPaint,
    );
  }

  // 9. Paddy Fields & Terraced Crop Ridges
  void _drawPaddyFields(Canvas canvas, Size size) {
    final fieldColor = isDark ? const Color(0xFF144D29) : const Color(0xFF2EA37B);
    final fieldPath = Path();
    fieldPath.moveTo(0, size.height * 0.68);
    fieldPath.quadraticBezierTo(size.width * 0.5, size.height * 0.62, size.width, size.height * 0.72);
    fieldPath.lineTo(size.width, size.height);
    fieldPath.lineTo(0, size.height);
    fieldPath.close();
    canvas.drawPath(fieldPath, Paint()..color = fieldColor);

    // Terraced crop row ridges
    final ridgePaint = Paint()
      ..color = (isDark ? const Color(0xFF0A2E16) : const Color(0xFF1B7A5C)).withValues(alpha: 0.5)
      ..strokeWidth = 1.6;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.74 + i * 0.07);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - 8),
        ridgePaint,
      );
    }
  }

  // 10. Live Animated Working Farmers & Grazing Cattle
  void _drawFarmers(Canvas canvas, Size size) {
    final farmerColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFF0F5C4A);
    final farmerPaint = Paint()..color = farmerColor;

    // Farmer 1: Harvesting / Tilling paddy
    final f1X = size.width * 0.22;
    final f1Y = size.height * 0.72;
    final harvestAngle = math.sin(loopProgress * 4 * math.pi) * 0.35;

    // Body & Mathal (Straw Hat)
    canvas.drawCircle(Offset(f1X, f1Y - 14), 4.5, farmerPaint);
    // Conical Straw Hat (Mathal)
    final hatPath = Path();
    hatPath.moveTo(f1X - 8, f1Y - 14);
    hatPath.lineTo(f1X, f1Y - 20);
    hatPath.lineTo(f1X + 8, f1Y - 14);
    hatPath.close();
    canvas.drawPath(hatPath, Paint()..color = const Color(0xFFFFB300));

    // Torso & Bending Animation
    final torsoPath = Path();
    torsoPath.moveTo(f1X, f1Y - 10);
    torsoPath.lineTo(f1X + harvestAngle * 10, f1Y);
    torsoPath.lineTo(f1X - 3, f1Y + 8);
    canvas.drawPath(
      torsoPath,
      Paint()
        ..color = farmerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Farmer 2: Walking with Shoulder Pole (Bhaat / Basket)
    final f2Walk = (loopProgress * size.width * 0.40) % (size.width * 0.50);
    final f2X = size.width * 0.55 + f2Walk;
    final f2Y = size.height * 0.78;
    final legBob = math.sin(loopProgress * 8 * math.pi) * 2.5;

    // Head & Hat
    canvas.drawCircle(Offset(f2X, f2Y - 16 + legBob), 4.0, farmerPaint);
    final hat2 = Path();
    hat2.moveTo(f2X - 7, f2Y - 16 + legBob);
    hat2.lineTo(f2X, f2Y - 22 + legBob);
    hat2.lineTo(f2X + 7, f2Y - 16 + legBob);
    hat2.close();
    canvas.drawPath(hat2, Paint()..color = const Color(0xFFFFB300));

    // Body
    canvas.drawLine(
      Offset(f2X, f2Y - 12 + legBob),
      Offset(f2X, f2Y + legBob),
      Paint()..color = farmerColor..strokeWidth = 2.5,
    );

    // Shoulder Pole & Baskets
    final polePaint = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 1.8;
    canvas.drawLine(
      Offset(f2X - 12, f2Y - 8 + legBob),
      Offset(f2X + 12, f2Y - 8 + legBob),
      polePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(f2X - 14, f2Y - 4 + legBob, 5, 5),
      Paint()..color = const Color(0xFFFFCA28),
    );
    canvas.drawRect(
      Rect.fromLTWH(f2X + 9, f2Y - 4 + legBob, 5, 5),
      Paint()..color = const Color(0xFFFFCA28),
    );

    // Grazing Cattle in Meadow
    final cowX = size.width * 0.75;
    final cowY = size.height * 0.65;
    final cowChew = math.sin(loopProgress * 4 * math.pi) * 1.5;

    // Cow Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cowX, cowY - 8, 18, 10), const Radius.circular(3)),
      Paint()..color = isDark ? Colors.white70 : const Color(0xFF3E2723),
    );
    // Cow Head
    canvas.drawCircle(
      Offset(cowX - 4, cowY - 4 + cowChew),
      4.5,
      Paint()..color = isDark ? Colors.white70 : const Color(0xFF3E2723),
    );
  }

  // 11. Foreground Swaying Crop Breeze
  void _drawForegroundCropBreeze(Canvas canvas, Size size) {
    final stalkCount = 14;
    final spacing = size.width / (stalkCount + 1);

    final stalkPaint = Paint()
      ..color = (isDark ? const Color(0xFF81C784) : const Color(0xFF0F5C4A)).withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final grainPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= stalkCount; i++) {
      final x = i * spacing;
      final sway = math.sin((loopProgress * 2 * math.pi) + (i * 0.7)) * 10;
      final h = 28.0 + (i % 4) * 8;

      final p = Path();
      p.moveTo(x, size.height);
      p.quadraticBezierTo(x + sway * 0.5, size.height - h * 0.5, x + sway, size.height - h);
      canvas.drawPath(p, stalkPaint);

      // Golden Grain Ear at tip
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + sway, size.height - h), width: 4.5, height: 8),
        grainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LivingFarmlandLandscapePainter oldDelegate) {
    return oldDelegate.clock != clock ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isRainy != isRainy;
  }
}
