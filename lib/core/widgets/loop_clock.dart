import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../providers/animation_mode_provider.dart';

/// A looping 0..1 progress value that ticks at a capped frame rate.
///
/// Many small decorative animations do not need 60 fps. Driving them all from
/// one throttled clock (instead of one controller per widget) keeps the
/// number of repaints low on weak devices.
class LoopClock extends ValueNotifier<double> {
  LoopClock({
    required TickerProvider vsync,
    required this.period,
    int maxFps = 30,
  })  : _minInterval = Duration(microseconds: (1000000 / maxFps).round()),
        super(0) {
    _ticker = vsync.createTicker(_onTick);
  }

  final Duration period;
  final Duration _minInterval;
  late final Ticker _ticker;
  Duration _lastEmit = Duration.zero;

  bool get isRunning => _ticker.isActive;

  void start() {
    if (_ticker.isActive) return;
    _lastEmit = Duration.zero;
    _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) _ticker.stop();
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastEmit < _minInterval) return;
    _lastEmit = elapsed;
    value = (elapsed.inMicroseconds % period.inMicroseconds) /
        period.inMicroseconds;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Provides one shared [LoopClock] to the cards below it.
///
/// The clock only runs while animated mode is on and the surrounding route is
/// visible (it uses the widget's own ticker, which Flutter mutes when the
/// route is covered).
class AgriAnimationClockScope extends StatefulWidget {
  const AgriAnimationClockScope({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3200),
    this.maxFps = 30,
  });

  final Widget child;
  final Duration period;
  final int maxFps;

  /// The nearest shared clock, or null if there is none (or it is stopped).
  static LoopClock? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_ClockInherited>()
        ?.clock;
  }

  @override
  State<AgriAnimationClockScope> createState() =>
      _AgriAnimationClockScopeState();
}

class _AgriAnimationClockScopeState extends State<AgriAnimationClockScope>
    with SingleTickerProviderStateMixin {
  late final LoopClock _clock = LoopClock(
    vsync: this,
    period: widget.period,
    maxFps: widget.maxFps,
  );

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
    return _ClockInherited(clock: _clock, child: widget.child);
  }
}

class _ClockInherited extends InheritedWidget {
  const _ClockInherited({required this.clock, required super.child});

  final LoopClock clock;

  @override
  bool updateShouldNotify(_ClockInherited oldWidget) =>
      clock != oldWidget.clock;
}
