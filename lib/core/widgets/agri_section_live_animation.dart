import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AgriCardAnimationType {
  diseaseScan, // Laser scanner beam & leaf health pulse
  aiNeural, // AI neural synapses & floating digital sparks
  cropGrowth, // Swaying crop stalks & floating leaf spores
  weatherAtmosphere, // Shimmering sunrays, drifting clouds & raindrop particles
  irrigationRipples, // Expanding water ripples & moisture bubbles
  marketTrends, // Dynamic market price chart wave & upward sparkles
  yieldForecast, // Harvest yield growth curve & golden harvest glow
  communityPulse, // Social beacon pulse & floating chat bubbles
  livestockHeartbeat, // Vital heartbeat wave & pasture breeze
  recordsLedger, // Shimmering ledger tally lines & floating calculation coins
  helplineSignal, // 16123 expanding radio waves & telephone signal rings
  libraryBook, // Turning knowledge pages & fluttering botanical leaves
}

/// A lightweight live animated layer for each homepage section card.
///
/// It no longer owns an animation controller: all cards share one throttled
/// [clock] (see `LoopClock`), and the painter repaints itself through that
/// listenable, so no widgets are rebuilt per frame. The layer sits in its own
/// [RepaintBoundary] so only this small canvas is re-rasterised.
class AgriSectionLiveAnimation extends StatelessWidget {
  const AgriSectionLiveAnimation({
    super.key,
    required this.type,
    required this.clock,
    this.primaryColor = Colors.white,
  });

  final AgriCardAnimationType type;
  final ValueListenable<double> clock;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SectionCanvasPainter(
          type: type,
          clock: clock,
          primaryColor: primaryColor,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _SectionCanvasPainter extends CustomPainter {
  _SectionCanvasPainter({
    required this.type,
    required this.clock,
    required this.primaryColor,
  }) : super(repaint: clock);

  final AgriCardAnimationType type;
  final ValueListenable<double> clock;
  double get progress => clock.value; // 0.0 to 1.0
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case AgriCardAnimationType.diseaseScan:
        _drawDiseaseScan(canvas, size);
        break;
      case AgriCardAnimationType.aiNeural:
        _drawAiNeural(canvas, size);
        break;
      case AgriCardAnimationType.cropGrowth:
        _drawCropGrowth(canvas, size);
        break;
      case AgriCardAnimationType.weatherAtmosphere:
        _drawWeatherAtmosphere(canvas, size);
        break;
      case AgriCardAnimationType.irrigationRipples:
        _drawIrrigationRipples(canvas, size);
        break;
      case AgriCardAnimationType.marketTrends:
        _drawMarketTrends(canvas, size);
        break;
      case AgriCardAnimationType.yieldForecast:
        _drawYieldForecast(canvas, size);
        break;
      case AgriCardAnimationType.communityPulse:
        _drawCommunityPulse(canvas, size);
        break;
      case AgriCardAnimationType.livestockHeartbeat:
        _drawLivestockHeartbeat(canvas, size);
        break;
      case AgriCardAnimationType.recordsLedger:
        _drawRecordsLedger(canvas, size);
        break;
      case AgriCardAnimationType.helplineSignal:
        _drawHelplineSignal(canvas, size);
        break;
      case AgriCardAnimationType.libraryBook:
        _drawLibraryBook(canvas, size);
        break;
    }
  }

  // 1. AI Disease Doctor: Moving laser scanning grid & pulsing diagnostic corners
  void _drawDiseaseScan(Canvas canvas, Size size) {
    final laserY = (progress * size.height);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.lightGreenAccent.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.9),
          Colors.lightGreenAccent.withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, laserY - 2, size.width, 4))
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(0, laserY),
      Offset(size.width, laserY),
      laserPaint,
    );

    // Glowing target reticle on top right
    final targetCenter = Offset(size.width * 0.82, size.height * 0.35);
    final pulseRadius = 14.0 + math.sin(progress * 2 * math.pi) * 4;
    final reticlePaint = Paint()
      ..color = Colors.lightGreenAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(targetCenter, pulseRadius, reticlePaint);
    canvas.drawCircle(targetCenter, 3.5, Paint()..color = Colors.lightGreenAccent.withValues(alpha: 0.7));
  }

  // 2. AI Chatbot: Orbiting neural synapses & floating digital glow nodes
  void _drawAiNeural(Canvas canvas, Size size) {
    final cx = size.width * 0.75;
    final cy = size.height * 0.40;
    final nodeCount = 5;

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.75);

    for (int i = 0; i < nodeCount; i++) {
      final angle = (i * 2 * math.pi / nodeCount) + (progress * 2 * math.pi);
      final r = 18.0 + math.sin(progress * 2 * math.pi + i) * 5;
      final nx = cx + math.cos(angle) * r;
      final ny = cy + math.sin(angle) * r;

      canvas.drawLine(Offset(cx, cy), Offset(nx, ny), linePaint);
      canvas.drawCircle(Offset(nx, ny), 2.5, dotPaint);
    }
    canvas.drawCircle(Offset(cx, cy), 4.0, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  // 3. My Crops Tracker: Swaying crop shoots & floating green leaf spores
  void _drawCropGrowth(Canvas canvas, Size size) {
    final stalkCount = 6;
    final stalkSpacing = size.width / (stalkCount + 1);

    final stalkPaint = Paint()
      ..color = Colors.lightGreenAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= stalkCount; i++) {
      final x = i * stalkSpacing;
      final sway = math.sin((progress * 2 * math.pi) + (i * 0.8)) * 8;
      final h = 30.0 + (i % 3) * 8;

      final path = Path();
      path.moveTo(x, size.height);
      path.quadraticBezierTo(x + sway * 0.5, size.height - h * 0.5, x + sway, size.height - h);
      canvas.drawPath(path, stalkPaint);

      // Mini Leaf Spore at top
      canvas.drawCircle(Offset(x + sway, size.height - h), 2.5, leafPaint);
    }
  }

  // 4. Weather Forecast: Floating mini clouds, sun shimmer rays & raindrops
  void _drawWeatherAtmosphere(Canvas canvas, Size size) {
    // Shimmering Sun Corona
    final sunCenter = Offset(size.width * 0.85, size.height * 0.28);
    final shimmer = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);
    final sunGlow = Paint()
      ..color = Colors.amber.withValues(alpha: 0.25 + shimmer * 0.15);
    canvas.drawCircle(sunCenter, 20 + shimmer * 4, sunGlow);

    // Drifting soft cloud
    final cloudX = (progress * (size.width + 60)) - 30;
    final cloudY = size.height * 0.32;
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cloudX, cloudY), 10, cloudPaint);
    canvas.drawCircle(Offset(cloudX + 8, cloudY - 3), 12, cloudPaint);
    canvas.drawCircle(Offset(cloudX + 16, cloudY), 9, cloudPaint);

    // Raindrop Streaks
    final rainPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      final rx = (size.width * (0.2 + i * 0.2) + progress * 20) % size.width;
      final ry = (progress * size.height + i * 25) % size.height;
      canvas.drawLine(Offset(rx, ry), Offset(rx - 3, ry + 8), rainPaint);
    }
  }

  // 5. Smart Irrigation: Expanding moisture ripples & water droplets
  void _drawIrrigationRipples(Canvas canvas, Size size) {
    final cx = size.width * 0.78;
    final cy = size.height * 0.45;

    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + (i / 3.0)) % 1.0;
      final r = rippleProgress * 36.0;
      final alpha = (1.0 - rippleProgress) * 0.45;

      final ripplePaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      canvas.drawCircle(Offset(cx, cy), r, ripplePaint);
    }

    // Droplet Center
    canvas.drawCircle(
      Offset(cx, cy),
      3.5,
      Paint()..color = Colors.cyanAccent.withValues(alpha: 0.85),
    );
  }

  // 6. Market Prices: Fluctuating price trend chart line & upward sparkles
  void _drawMarketTrends(Canvas canvas, Size size) {
    final chartPath = Path();
    final chartPaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final startY = size.height * 0.65;
    chartPath.moveTo(0, startY);

    for (double x = 0; x <= size.width; x += 15) {
      final y = startY -
          (math.sin((x / size.width * 2 * math.pi) + (progress * 2 * math.pi)) * 12) -
          (x / size.width * 14);
      chartPath.lineTo(x, y);
    }
    canvas.drawPath(chartPath, chartPaint);

    // Glowing Peak Indicator
    final peakX = size.width * 0.75;
    final peakY = startY - (math.sin((peakX / size.width * 2 * math.pi) + (progress * 2 * math.pi)) * 12) - (peakX / size.width * 14);
    canvas.drawCircle(
      Offset(peakX, peakY),
      4.0,
      Paint()..color = Colors.amber.shade200,
    );
  }

  // 7. Yield Forecaster: Ascending harvest growth bars & golden sparkles
  void _drawYieldForecast(Canvas canvas, Size size) {
    final barCount = 5;
    final barWidth = 6.0;
    final startX = size.width * 0.55;

    for (int i = 0; i < barCount; i++) {
      final barX = startX + i * 11;
      final targetH = 12.0 + (i * 6.0);
      final animatedH = targetH * (0.6 + 0.4 * math.sin((progress * 2 * math.pi) + (i * 0.6)));

      final barPaint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.35 + (i * 0.08))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, size.height * 0.75 - animatedH, barWidth, animatedH),
          const Radius.circular(3),
        ),
        barPaint,
      );
    }
  }

  // 8. Community Feed: Radiating social beacon rings & chat bubble float
  void _drawCommunityPulse(Canvas canvas, Size size) {
    final cx = size.width * 0.80;
    final cy = size.height * 0.38;

    for (int i = 0; i < 2; i++) {
      final waveProgress = (progress + (i * 0.5)) % 1.0;
      final r = 10.0 + waveProgress * 28.0;
      final opacity = (1.0 - waveProgress) * 0.4;

      final wavePaint = Paint()
        ..color = Colors.lightGreenAccent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(cx, cy), r, wavePaint);
    }

    // Mini Chat Bubble Icon
    final bubbleRect = Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  // 9. Livestock Care: Vital heartbeat line & pasture grass movement
  void _drawLivestockHeartbeat(Canvas canvas, Size size) {
    final linePath = Path();
    final linePaint = Paint()
      ..color = Colors.deepOrangeAccent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final midY = size.height * 0.62;
    final scrollOffset = progress * size.width;

    linePath.moveTo(0, midY);
    for (double x = 0; x <= size.width; x += 10) {
      final relX = (x + scrollOffset) % size.width;
      double y = midY;
      if (relX > size.width * 0.45 && relX < size.width * 0.55) {
        y = midY - 14.0 * math.sin((relX - size.width * 0.45) / (size.width * 0.1) * math.pi);
      }
      linePath.lineTo(x, y);
    }
    canvas.drawPath(linePath, linePaint);
  }

  // 10. Farm Records: Flowing calculation tally tracks & floating coin sparks
  void _drawRecordsLedger(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blueGrey.shade200.withValues(alpha: 0.3)
      ..strokeWidth = 1.4;

    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.50 + i * 0.12);
      final dashOffset = (progress * 30.0) % 20.0;
      canvas.drawLine(
        Offset(size.width * 0.40 + dashOffset, y),
        Offset(size.width * 0.90, y),
        linePaint,
      );
    }

    // Sparkle coin
    final coinX = size.width * 0.78;
    final coinY = size.height * 0.32 + math.sin(progress * 2 * math.pi) * 4;
    canvas.drawCircle(
      Offset(coinX, coinY),
      5.0,
      Paint()..color = Colors.amberAccent.withValues(alpha: 0.6),
    );
  }

  // 11. Krishi Helpline 16123: Expanding radio broadcast signals & audio waves
  void _drawHelplineSignal(Canvas canvas, Size size) {
    final cx = size.width * 0.80;
    final cy = size.height * 0.38;

    for (int i = 1; i <= 3; i++) {
      final sweepProgress = (progress + (i * 0.33)) % 1.0;
      final arcRadius = 10.0 + sweepProgress * 26.0;
      final opacity = (1.0 - sweepProgress) * 0.45;

      final arcPaint = Paint()
        ..color = Colors.tealAccent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: arcRadius),
        -math.pi / 2,
        math.pi,
        false,
        arcPaint,
      );
    }
  }

  // 12. Crop Directory: Knowledge page sweep & fluttering botanical leaves
  void _drawLibraryBook(Canvas canvas, Size size) {
    final leafX = size.width * 0.78;
    final leafY = size.height * 0.40;
    final flutter = math.sin(progress * 2 * math.pi);

    final leafPath = Path();
    leafPath.moveTo(leafX, leafY);
    leafPath.quadraticBezierTo(leafX + 12, leafY - 10 + flutter * 4, leafX + 20, leafY + flutter * 2);
    leafPath.quadraticBezierTo(leafX + 8, leafY + 12 + flutter * 3, leafX, leafY);

    final leafPaint = Paint()
      ..color = Colors.limeAccent.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _SectionCanvasPainter oldDelegate) {
    return oldDelegate.clock != clock || oldDelegate.type != type;
  }
}
