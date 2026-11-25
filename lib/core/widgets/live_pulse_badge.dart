import 'package:flutter/material.dart';
import '../providers/animation_mode_provider.dart';
import '../theme/app_theme.dart';

/// Animated glowing pulsating dot for real-time live sensors, weather, and AI states.
class LivePulseBadge extends StatefulWidget {
  const LivePulseBadge({
    super.key,
    this.color = AppTheme.primaryGreenLight,
    this.size = 10,
    this.label,
  });

  final Color color;
  final double size;
  final String? label;

  @override
  State<LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.animationsEnabled) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = context.animationsEnabled;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (animate)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(
                            alpha: _opacityAnimation.value,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.label != null) ...[
          const SizedBox(width: 6),
          Text(
            widget.label!,
            style: TextStyle(
              color: widget.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
