import 'dart:async';
import 'dart:developer' as developer;

import '../../features/crop_tracker/presentation/providers/daily_suggestions_provider.dart';
import '../../features/livestock/presentation/providers/livestock_daily_suggestions_provider.dart';
import 'crops_realtime_service.dart';
import 'gemini_service.dart';
import 'livestock_realtime_service.dart';

/// Orchestrates a once-per-day regeneration of AI suggestions for every
/// crop and animal the signed-in user owns, persisting the result to
/// Firestore so the crop / livestock / weather screens can render the
/// advice instantly without calling Gemini on every open.
///
/// Triggers:
///   * [run] is called from the splash screen once auth resolves.
///   * A periodic timer fires every [interval] while the app is open
///     so we still catch up if the realtime stream is slow.
///   * The realtime services notify us when the user's crop or animal
///     list changes, so newly-added items get today's suggestion even
///     if they were created minutes after sign-in.
///   * A day-rollover timer schedules the next run for the moment the
///     local date flips, so the cache stays fresh across midnight.
///
/// The per-day record is keyed by `<id>|<YYYY-MM-DD>`. The service
/// keeps a per-id map of the last dateKey it generated, so the same
/// crop is never generated twice on the same day even when multiple
/// triggers race.
class DailySuggestionUpdateService {
  DailySuggestionUpdateService({
    required this.crops,
    required this.livestock,
    required this.cropSuggestions,
    required this.livestockSuggestions,
    required this.gemini,
    this.weather,
  });

  final CropsRealtimeService crops;
  final LivestockRealtimeService livestock;
  final DailySuggestionsProvider cropSuggestions;
  final LivestockDailySuggestionsProvider livestockSuggestions;
  final GeminiService gemini;

  /// Optional weather advice provider. Late-bound so this service
  /// can be created before the weather provider is registered. It
  /// must expose `ensureToday()` and a `ChangeNotifier`-compatible
  /// `addListener` / `removeListener` surface so a new weather
  /// snapshot triggers a fresh run.
  final dynamic weather;

  /// Per-id keys that already have today's suggestion. Cleared when
  /// the local date key flips.
  final Map<String, String> _lastGeneratedCrops = <String, String>{};
  final Map<String, String> _lastGeneratedAnimals = <String, String>{};
  final Map<String, String> _lastGeneratedWeather = <String, String>{};

  bool _running = false;
  Timer? _ticker;
  Timer? _rolloverTimer;
  void Function()? _cropsListener;
  void Function()? _livestockListener;
  void Function()? _weatherListener;

  /// Starts all background timers and hooks the realtime listeners.
  /// Idempotent — safe to call multiple times.
  void start({Duration interval = const Duration(minutes: 30)}) {
    _ticker?.cancel();
    _ticker = Timer.periodic(interval, (_) {
      unawaited(run());
    });

    _attachRealtimeListeners();
    _scheduleRollover();
  }

  void _attachRealtimeListeners() {
    _cropsListener ??= () => unawaited(run());
    crops.addListener(_cropsListener!);

    _livestockListener ??= () => unawaited(run());
    livestock.addListener(_livestockListener!);

    final w = weather;
    if (w != null) {
      _weatherListener ??= () => unawaited(run());
      try {
        w.addListener(_weatherListener!);
      } catch (_) {
        // Provider isn't a ChangeNotifier — ignore.
      }
    }
  }

  /// Schedules a one-shot timer for the next local midnight so the
  /// day-keyed cache is refreshed the moment a new day starts.
  void _scheduleRollover() {
    _rolloverTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final delta = tomorrow.difference(now) + const Duration(seconds: 30);
    _rolloverTimer = Timer(delta, () {
      _lastGeneratedCrops.clear();
      _lastGeneratedAnimals.clear();
      _lastGeneratedWeather.clear();
      unawaited(run());
      _scheduleRollover();
    });
  }

  /// Generate (or reuse) today's suggestion for every crop / animal /
  /// weather slot the user owns and persist it to Firestore.
  /// Concurrent calls collapse into a single run. After [timeout] we
  /// give up so a stuck Gemini call never blocks the next trigger.
  Future<void> run({Duration timeout = const Duration(seconds: 45)}) async {
    if (_running) return;
    _running = true;
    try {
      await _waitForData();
      await runOnce().timeout(
        timeout,
        onTimeout: () {
          developer.log(
            'Daily suggestion run timed out after $timeout',
            name: 'DailySuggestionUpdateService',
          );
        },
      );
    } catch (e, st) {
      developer.log(
        'run() failed: $e',
        name: 'DailySuggestionUpdateService',
        error: e,
        stackTrace: st,
      );
    } finally {
      _running = false;
    }
  }

  /// Internal helper exposed for tests. Skips the dedup guard and
  /// returns once every eligible id has been processed.
  Future<void> runOnce() async {
    final dateKey = _dateKey(DateTime.now());

    // --- Crops ------------------------------------------------------
    for (final crop in crops.snapshot) {
      if (_lastGeneratedCrops[crop.id] == dateKey) continue;
      try {
        await cropSuggestions.ensureToday(crop);
        _lastGeneratedCrops[crop.id] = dateKey;
      } catch (e, st) {
        developer.log(
          'Daily crop suggestion failed for ${crop.id}: $e',
          name: 'DailySuggestionUpdateService',
          error: e,
          stackTrace: st,
        );
      }
    }

    // --- Animals ----------------------------------------------------
    for (final animal in livestock.snapshot) {
      if (_lastGeneratedAnimals[animal.id] == dateKey) continue;
      try {
        await livestockSuggestions.ensureToday(animal, null);
        _lastGeneratedAnimals[animal.id] = dateKey;
      } catch (e, st) {
        developer.log(
          'Daily livestock suggestion failed for ${animal.id}: $e',
          name: 'DailySuggestionUpdateService',
          error: e,
          stackTrace: st,
        );
      }
    }

    // --- Weather ----------------------------------------------------
    final w = weather;
    if (w != null) {
      if (_lastGeneratedWeather['user'] != dateKey) {
        try {
          await w.ensureToday();
          _lastGeneratedWeather['user'] = dateKey;
        } catch (e, st) {
          developer.log(
            'Daily weather suggestion failed: $e',
            name: 'DailySuggestionUpdateService',
            error: e,
            stackTrace: st,
          );
        }
      }
    }
  }

  /// Waits (up to [timeout]) for at least one of the realtime snapshots
  /// to populate so we don't run the update against an empty list right
  /// after sign-in. If the user genuinely has no data we proceed anyway
  /// and the loops simply do nothing.
  Future<void> _waitForData({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      if (crops.snapshot.isNotEmpty || livestock.snapshot.isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Cancels all timers and listeners. The root provider lives for
  /// the app lifetime, but expose this so callers can stop updates
  /// (e.g. on sign-out).
  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _rolloverTimer?.cancel();
    _rolloverTimer = null;
    if (_cropsListener != null) crops.removeListener(_cropsListener!);
    if (_livestockListener != null) {
      livestock.removeListener(_livestockListener!);
    }
    final w = weather;
    if (_weatherListener != null && w != null) {
      try {
        w.removeListener(_weatherListener!);
      } catch (_) {}
    }
    _cropsListener = null;
    _livestockListener = null;
    _weatherListener = null;
  }
}
