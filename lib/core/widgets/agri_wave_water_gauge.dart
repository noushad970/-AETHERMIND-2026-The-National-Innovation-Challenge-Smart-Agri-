import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/animation_mode_provider.dart';
import '../theme/app_theme.dart';

/// Animated fluid water wave gauge for soil moisture and smart irrigation levels.
class AgriWaveWaterGauge extends StatefulWidget {
  const AgriWaveWaterGauge({
    super.key,
    required this.percentage, // 0.0 to 1.0
    this.size = 140,
    this.label = 'Moisture',
    this.unit = '%',
  });

  final double percentage;
  final double size;
  final String label;
  final String unit;

  @override
  State<AgriWaveWaterGauge> createState() => _AgriWaveWaterGaugeState();
}

class _AgriWaveWaterGaugeState extends State<AgriWaveWaterGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.animationsEnabled) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      // Static mode: freeze the wave on a single frame.
      _controller.stop();
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.percentage.clamp(0.0, 1.0);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.skyBlue.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: AppTheme.skyBlue.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Wave animation
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _WavePainter(
                      animationValue: _controller.value,
                      fillPercentage: pct,
                    ),
                  );
                },
              ),
            ),
            // Text center
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(pct * 100).toInt()}${widget.unit}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.animationValue,
    required this.fillPercentage,
  });

  final double animationValue;
  final double fillPercentage;

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    final waterHeight = height * (1.0 - fillPercentage);

    final paint1 = Paint()
      ..color = AppTheme.skyBlue.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = AppTheme.emeraldGreen.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    final path2 = Path();

    path1.moveTo(0, waterHeight);
    path2.moveTo(0, waterHeight);

    for (double x = 0; x <= width; x++) {
      final y1 = math.sin((x / width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 6 + waterHeight;
      final y2 = math.cos((x / width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 6 + waterHeight;
      path1.lineTo(x, y1);
      path2.lineTo(x, y2);
    }

    path1.lineTo(width, height);
    path1.lineTo(0, height);
    path1.close();

    path2.lineTo(width, height);
    path2.lineTo(0, height);
    path2.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
