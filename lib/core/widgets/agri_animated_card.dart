import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../providers/animation_mode_provider.dart';
import 'agri_section_live_animation.dart';
import 'loop_clock.dart';

/// Agriculture themed interactive card: background photo, tinted gradient
/// overlay, icon header and (in animated mode) a live contextual animation.
///
/// Performance notes:
/// * No `BackdropFilter`: a per-card blur forces an offscreen layer every
///   frame, which is very slow on low-end GPUs. The gradient overlay is
///   opaque enough that the blur was barely visible anyway.
/// * The static content and the live animation sit in separate
///   [RepaintBoundary]s, so the animation never repaints the photo or text.
/// * All cards share one throttled clock ([AgriAnimationClockScope]).
/// * In static mode there is no live layer, no tap-bounce and no image fade.
class AgriAnimatedCard extends StatefulWidget {
  const AgriAnimatedCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.imageBgUrl,
    this.imageAssetPath,
    @Deprecated('Blur was removed for performance; this has no effect.')
    this.blurAmount = 4.5,
    this.animationType,
    this.badgeText,
    this.iconColor = Colors.white,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String? imageBgUrl;
  final String? imageAssetPath;
  final double blurAmount;
  final AgriCardAnimationType? animationType;
  final String? badgeText;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  State<AgriAnimatedCard> createState() => _AgriAnimatedCardState();
}

class _AgriAnimatedCardState extends State<AgriAnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  static const int _imageCacheWidth = 400;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBackgroundImage(bool animate) {
    if (widget.imageAssetPath != null && widget.imageAssetPath!.isNotEmpty) {
      return Image.asset(
        widget.imageAssetPath!,
        fit: BoxFit.cover,
        cacheWidth: _imageCacheWidth,
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(gradient: widget.gradient),
        ),
      );
    }

    if (widget.imageBgUrl != null && widget.imageBgUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.imageBgUrl!,
        fit: BoxFit.cover,
        // Decode at card size, not full resolution, to save memory.
        memCacheWidth: _imageCacheWidth,
        fadeInDuration:
            animate ? const Duration(milliseconds: 200) : Duration.zero,
        fadeOutDuration:
            animate ? const Duration(milliseconds: 200) : Duration.zero,
        placeholder: (_, _) => Container(
          decoration: BoxDecoration(gradient: widget.gradient),
        ),
        errorWidget: (_, _, _) => Container(
          decoration: BoxDecoration(gradient: widget.gradient),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: widget.gradient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animate = context.animationsEnabled;
    final clock = animate ? AgriAnimationClockScope.maybeOf(context) : null;

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: animate ? 12 : 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1 + 2. Photo and tinted overlay. Painted once, then cached.
            Positioned.fill(
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildBackgroundImage(animate),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.gradient.colors.first
                                .withValues(alpha: 0.78),
                            widget.gradient.colors.last
                                .withValues(alpha: 0.90),
                            Colors.black.withValues(alpha: 0.68),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Live animation layer (animated mode only).
            if (widget.animationType != null && clock != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AgriSectionLiveAnimation(
                    type: widget.animationType!,
                    clock: clock,
                  ),
                ),
              ),

            // 4. Foreground content (icon, badge, title, subtitle).
            Padding(
              padding: const EdgeInsets.all(14),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );

    if (!animate) {
      // Static mode: plain tap, no bounce animation.
      return Semantics(
        button: true,
        label: widget.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    return Semantics(
      button: true,
      label: widget.title,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap?.call();
          },
          onTapCancel: () => _controller.reverse(),
          child: card,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 22),
            ),
            if (widget.badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  widget.badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 11,
                    height: 1.2,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
