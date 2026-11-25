import 'dart:async';

import '../../core/utils/app_logger.dart';
import '../models/animal.dart';
import '../models/livestock_daily_summary.dart';
import '../models/livestock_daily_suggestion.dart';
import '../services/livestock_children_service.dart';
import '../services/livestock_realtime_service.dart';

/// Firestore-only CRUD for livestock. All reads come from
/// [LivestockRealtimeService] (animal groups) and
/// [LivestockChildrenService] (activities, summaries, suggestions).
/// Writes go through the same services so the realtime listener
/// picks them up and the UI refreshes without any local cache.
class LivestockRepository {
  LivestockRepository({
    LivestockRealtimeService? animals,
    LivestockChildrenService? children,
  }) : _animals = animals ?? LivestockRealtimeService(),
       _children = children ?? LivestockChildrenService();

  final LivestockRealtimeService _animals;
  final LivestockChildrenService _children;

  // ─── Animals ──────────────────────────────────────────────────

  List<Animal> getAll() => _animals.snapshot;

  Animal? getById(String id) {
    for (final a in _animals.snapshot) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> add(Animal a) async {
    try {
      await _animals.save(a);
    } catch (e, st) {
      AppLogger.e('LivestockRepository.add failed', error: e, stack: st);
      rethrow;
    }
  }

  Future<void> update(Animal a) async {
    try {
      await _animals.save(a);
    } catch (e, st) {
      AppLogger.e('LivestockRepository.update failed', error: e, stack: st);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _animals.delete(id);
    } catch (e, st) {
      AppLogger.e('LivestockRepository.delete failed', error: e, stack: st);
      rethrow;
    }
  }

  Future<void> updateCounts({
    required String animalId,
    required int totalCount,
    required int deadCount,
  }) async {
    final a = getById(animalId);
    if (a == null) return;
    a.totalCount = totalCount;
    a.deadCount = deadCount;
    await update(a);
  }

  Future<({int live, int died})> recordDeaths({
    required String animalId,
    required int count,
  }) async {
    final a = getById(animalId);
    if (a == null) {
      return (live: 0, died: 0);
    }
    final next = (a.deadCount + count).clamp(0, a.totalCount);
    a.deadCount = next;
    await update(a);
    return (live: a.liveCount, died: a.deadCount);
  }

  Future<LivestockDailySummary> saveDailySummary({
    required String animalId,
    required int deaths,
    required int eggsToday,
    required double milkLitersToday,
    required double feedKg,
    String notes = '',
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateKey = LivestockDailySummary.dateKeyFor(d);
    final animal = getById(animalId);
    if (animal == null) {
      throw StateError('Animal $animalId not found');
    }
    final newTotalDeaths = (animal.deadCount + deaths).clamp(
      0,
      animal.totalCount,
    );
    final liveAfter = (animal.totalCount - newTotalDeaths).clamp(0, 1 << 30);
    final summary = LivestockDailySummary(
      id: LivestockDailySummary.buildId(animalId, dateKey),
      animalId: animalId,
      userId: animal.userId,
      dateKey: dateKey,
      dayFromStart: animal.daysSinceStart,
      liveCount: liveAfter,
      deathsToday: deaths,
      totalDeaths: newTotalDeaths,
      eggsToday: eggsToday,
      milkLitersToday: milkLitersToday,
      feedKg: feedKg,
      notes: notes,
      recordedAt: DateTime.now(),
    );
    await upsertSummary(summary);
    if (deaths > 0) {
      await recordDeaths(animalId: animalId, count: deaths);
    }
    return summary;
  }

  // ─── Activities ───────────────────────────────────────────────

  List<LivestockActivity> getActivitiesFor(String animalId) {
    final out = _children.activitiesFor(animalId).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return out;
  }

  LivestockActivity? getActivityById(String id) {
    for (final acts in _children.animalIdsWithData.map(
      _children.activitiesFor,
    )) {
      for (final a in acts) {
        if (a.id == id) return a;
      }
    }
    // Newly-created animal templates are embedded in the parent document.
    // They are only copied into the activity subcollection after their first
    // update, so consult the parent mirror as a fallback. Without this, the
    // first checklist tap on every new animal silently did nothing.
    for (final animal in _animals.snapshot) {
      for (final activity in animal.activities) {
        if (activity.id == id) return activity;
      }
    }
    return null;
  }

  /// Toggle a single activity. Returns the updated record. The
  /// realtime service will refresh the local cache from Firestore
  /// after the sync write completes.
  ///
  /// The toggle writes the activity document to the
  /// `livestock/{animalId}/activities/{activityId}` subcollection
  /// **and** mirrors the change into the parent Animal doc's
  /// embedded `activities[]` array. The realtime snapshot decoder
  /// reads activities from the parent doc, so without this mirror
  /// the next Firestore echo would revert `isCompleted` back to
  /// its previous value.
  ///
  /// For **recurring** activities (`repeatIntervalDays > 0`), the
  /// completed record is kept as the historical entry and a fresh
  /// occurrence is created at `scheduledDate + repeatIntervalDays`.
  /// The new occurrence is also pushed to Firestore so the cloud
  /// mirror matches.
  Future<LivestockActivity?> toggleActivity({
    required String activityId,
    required bool done,
  }) async {
    try {
      final act = getActivityById(activityId);
      if (act == null) return null;
      final updated = act.copyWith(
        isCompleted: done,
        completedAt: done ? DateTime.now() : null,
      );

      // Persist the toggled activity.
      final parent = getById(act.animalId);
      if (parent == null) return null;
      await _children.toggleActivity(animal: parent, activity: updated);

      LivestockActivity? nextOccurrence;
      if (done && updated.repeatIntervalDays > 0) {
        final baseDay = DateTime(
          updated.scheduledDate.year,
          updated.scheduledDate.month,
          updated.scheduledDate.day,
        );
        final nextDate = baseDay.add(
          Duration(days: updated.repeatIntervalDays),
        );
        nextOccurrence = LivestockActivity(
          id:
              '${updated.animalId}_d${updated.dayFromStart}_'
              '${updated.category}_r${updated.repeatIntervalDays}_'
              '${nextDate.millisecondsSinceEpoch ~/ 86400000}',
          animalId: updated.animalId,
          title: updated.title,
          description: updated.description,
          category: updated.category,
          dayFromStart: updated.dayFromStart + updated.repeatIntervalDays,
          scheduledDate: nextDate,
          repeatIntervalDays: updated.repeatIntervalDays,
        );
        await _children.toggleActivity(
          animal: parent,
          activity: nextOccurrence,
        );
      }

      // Keep the in-memory Animal.activities list in sync so the
      // provider rebuild sees the new row without a full refresh,
      // and persist the parent so the next Firestore echo carries
      // the toggled state too (the snapshot decoder reads from the
      // parent doc, not from the subcollection).
      final idx = parent.activities.indexWhere((a) => a.id == activityId);
      if (idx >= 0) {
        parent.activities[idx] = updated;
      } else {
        parent.activities.add(updated);
      }
      if (nextOccurrence != null &&
          !parent.activities.any((a) => a.id == nextOccurrence!.id)) {
        parent.activities.add(nextOccurrence);
      }
      await _animals.save(parent);
      return updated;
    } catch (e, st) {
      AppLogger.e(
        'LivestockRepository.toggleActivity failed',
        error: e,
        stack: st,
      );
      rethrow;
    }
  }

  bool wasCompletedLate(LivestockActivity act) {
    if (!act.isCompleted) return false;
    final c = act.completedAt;
    if (c == null) return false;
    final due = act.scheduledDate;
    final dueDay = DateTime(due.year, due.month, due.day);
    final completedDay = DateTime(c.year, c.month, c.day);
    return completedDay.isAfter(dueDay);
  }

  // ─── Daily summaries ──────────────────────────────────────────

  List<LivestockDailySummary> getSummariesForAnimal(String animalId) {
    final out = _children.summariesFor(animalId).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return out;
  }

  LivestockDailySummary? getSummaryForDay({
    required String animalId,
    required String dateKey,
  }) {
    for (final s in _children.summariesFor(animalId)) {
      if (s.dateKey == dateKey) return s;
    }
    return null;
  }

  LivestockDailySummary? getLatestSummaryFor(String animalId) =>
      _children.latestSummaryFor(animalId);

  Future<void> upsertSummary(LivestockDailySummary s) async {
    try {
      await _children.upsertDailySummary(s);
    } catch (e, st) {
      AppLogger.e(
        'LivestockRepository.upsertSummary failed',
        error: e,
        stack: st,
      );
      rethrow;
    }
  }

  // ─── AI suggestions ───────────────────────────────────────────

  LivestockDailySuggestion? getSuggestion({
    required String animalId,
    required String dateKey,
  }) {
    for (final s in _children.suggestionsFor(animalId)) {
      if (s.dateKey == dateKey) return s;
    }
    return null;
  }

  Future<void> upsertSuggestion(LivestockDailySuggestion s) async {
    try {
      await _children.upsertDailySuggestion(s);
    } catch (e, st) {
      AppLogger.e(
        'LivestockRepository.upsertSuggestion failed',
        error: e,
        stack: st,
      );
      rethrow;
    }
  }
}
