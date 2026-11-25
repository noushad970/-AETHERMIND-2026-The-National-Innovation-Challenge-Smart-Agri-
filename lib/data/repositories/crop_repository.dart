import '../models/chat_message.dart';
import '../models/crop.dart';
import '../models/expense.dart';
import '../services/chat_realtime_service.dart';
import '../services/crops_realtime_service.dart';
import '../services/expenses_realtime_service.dart';

/// Repository for [Crop] entities. Reads come from the realtime
/// Firestore stream exposed by [CropsRealtimeService] — there is no
/// local cache. Writes go through the same realtime service so the
/// UI refreshes immediately.
///
/// Every write is mirrored to Cloud Firestore via
/// [FirestoreSyncService]. If the user is not yet authenticated the
/// save is a no-op (the realtime stream is empty until sign-in).
class CropRepository {
  CropRepository({CropsRealtimeService? crops})
    : _crops = crops ?? CropsRealtimeService();

  final CropsRealtimeService _crops;

  /// All crops currently known to the realtime stream. The provider
  /// typically subscribes to [CropsRealtimeService.stream] directly
  /// for live updates; this snapshot is a convenience for callers
  /// that just want a one-shot read.
  List<Crop> getAll() => _crops.snapshot;

  Crop? getById(String id) {
    for (final c in _crops.snapshot) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> save(Crop crop) async {
    await _crops.save(crop);
  }

  Future<void> delete(String id) async {
    await _crops.delete(id);
  }

  Future<void> updateActivityCompletion(
    String cropId,
    String activityId, {
    required bool completed,
  }) async {
    final crop = getById(cropId);
    if (crop == null) return;
    final idx = crop.activities.indexWhere((a) => a.id == activityId);
    if (idx == -1) return;
    crop.activities[idx] = crop.activities[idx].copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
    );
    await _crops.save(crop);
  }

  Future<void> addTree(String cropId, {int count = 1}) async {
    final crop = getById(cropId);
    if (crop == null) return;
    crop.newlyPlantedTrees += count;
    await _crops.save(crop);
  }

  Future<void> markDeadTrees(String cropId, {int count = 1}) async {
    final crop = getById(cropId);
    if (crop == null) return;
    crop.deadTrees += count;
    await _crops.save(crop);
  }
}

/// Expense storage. Reads and writes are handled by
/// [ExpensesRealtimeService].
class ExpenseRepository {
  ExpenseRepository({ExpensesRealtimeService? svc})
    : _svc = svc ?? ExpensesRealtimeService();

  final ExpensesRealtimeService _svc;

  List<Expense> getAll() => _svc.snapshot;

  List<Expense> getAllForCrop(String cropId) =>
      _svc.snapshot.where((e) => e.cropId == cropId).toList(growable: false);

  double totalForCrop(String cropId) => _svc.snapshot
      .where((e) => e.cropId == cropId)
      .fold<double>(0, (sum, e) => sum + e.amount);

  Future<void> save(Expense expense) async {
    await _svc.save(expense);
  }

  Future<void> delete(String id) async {
    await _svc.delete(id);
  }
}

/// Chat history repository. Reads via [ChatRealtimeService.snapshot];
/// writes via the service's [saveMessage]/[deleteThread] helpers.
class ChatRepository {
  ChatRepository({ChatRealtimeService? svc})
    : _svc = svc ?? ChatRealtimeService();

  final ChatRealtimeService _svc;

  List<ChatMessage> messagesForThread(String threadId) {
    final out = _svc.snapshot.messagesFor(threadId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  Future<void> save(ChatMessage message, {String? threadTitle}) async {
    await _svc.saveMessage(message, threadTitle: threadTitle);
  }

  Future<void> clearThread(String threadId) async {
    await _svc.deleteThread(threadId);
  }
}
