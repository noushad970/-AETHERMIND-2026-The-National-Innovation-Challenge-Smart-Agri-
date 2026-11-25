import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../../../../data/models/chat_message.dart';
import '../../../../data/services/chat_realtime_service.dart';
import '../../../../data/services/gemini_service.dart';

/// Live debug snapshot of one chat round-trip. Used to drive the
/// in-app debug popup so we can see what the backend is doing in
/// real time (network retries, model fallbacks, safety blocks, etc).
enum ChatPhase {
  idle,
  sending, // persisting user message to Firestore
  generating, // calling Gemini chatCompletion
  awaitingModel, // awaiting current model reply
  retrying, // current model failed, trying fallback
  succeeded,
  failed,
}

class DebugEvent {
  DebugEvent({
    required this.phase,
    required this.label,
    this.detail,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final ChatPhase phase;
  final String label;
  final String? detail;
  final DateTime timestamp;
}

/// Drives the chatbot screen. Owns the in-memory list of
/// [ChatMessage]s for the active thread, mirrors them to Firestore
/// via [ChatRealtimeService], and calls [GeminiService] for new
/// replies.
///
/// History pagination model:
///   * [_allMessages] is the full chronological store seeded from
///     the Firestore thread and refreshed whenever a new message is
///     persisted.
///   * [_visibleFrom] is the start index (from the end) of the slice
///     that is exposed to the UI as [messages]. The newest N
///     messages are shown first; as the user scrolls up,
///     [loadOlder] extends the visible window towards the start of
///     [_allMessages].
class ChatbotProvider extends ChangeNotifier {
  ChatbotProvider({GeminiService? service, ChatRealtimeService? chat})
    : _service = service ?? GeminiService(),
      _chat = chat ?? ChatRealtimeService() {
    _chatSub = _chat.stream().listen(_onChatSnapshot);
    _seedFromRealtime();
  }

  final GeminiService _service;
  final ChatRealtimeService _chat;
  StreamSubscription<ChatSnapshot>? _chatSub;

  static const String _threadId = 'default';

  /// Default page size used when [loadOlder] is called without arguments.
  static const int defaultPageSize = 20;

  /// Full chronological history for the active thread.
  final List<ChatMessage> _allMessages = [];

  /// Number of messages from the *end* of [_allMessages] currently
  /// exposed via [messages]. Starts at [defaultPageSize] after the
  /// first realtime snapshot lands.
  int _visibleFrom = 0;

  /// True while [loadOlder] is in flight. Used by the UI to render
  /// a "loading older messages..." indicator at the top of the list.
  bool _isLoadingOlder = false;

  bool _loading = false;
  String? _error;

  // ---- debug state ----
  final List<DebugEvent> _debugLog = [];
  ChatPhase _phase = ChatPhase.idle;
  int _attempt = 0;
  String? _activeModel;
  int _historyCount = 0;
  String? _lastFinishReason;
  String? _lastRawError;
  DateTime? _startedAt;

  /// Read-only view of the currently visible (paginated) messages,
  /// ordered oldest -> newest. This is what the chat list renders.
  List<ChatMessage> get messages {
    if (_allMessages.isEmpty) return const [];
    final start = _visibleFrom.clamp(0, _allMessages.length);
    return List.unmodifiable(_allMessages.sublist(start));
  }

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isApiConfigured => _service.isConfigured;

  /// True when there are still older messages that have not yet been
  /// pulled into the visible window.
  bool get hasMoreOlder => _visibleFrom > 0;

  /// True while a [loadOlder] round-trip is in progress.
  bool get isLoadingOlder => _isLoadingOlder;

  /// Total number of stored messages for the active thread.
  int get totalStoredCount => _allMessages.length;

  ChatPhase get phase => _phase;
  int get attempt => _attempt;
  String? get activeModel => _activeModel;
  int get historyCount => _historyCount;
  String? get lastFinishReason => _lastFinishReason;
  String? get lastRawError => _lastRawError;
  DateTime? get startedAt => _startedAt;
  List<DebugEvent> get debugLog => List.unmodifiable(_debugLog);

  Future<Map<String, dynamic>> testConnection() => _service.testConnection();

  /// Pull the initial message list out of the realtime snapshot the
  /// first time it fires. After this, every send() and every stream
  /// tick keeps the in-memory list in sync.
  void _seedFromRealtime() {
    final msgs = _chat.snapshot.messagesByThread[_threadId];
    if (msgs != null) _replaceAll(msgs);
  }

  /// Re-seed the visible window from the realtime snapshot. Used by
  /// the screen's `initState` as a safety net in case the first
  /// stream event fires before the widget is mounted.
  Future<void> loadHistory() async {
    _seedFromRealtime();
    notifyListeners();
  }

  /// Called for every [ChatSnapshot] the realtime service emits. We
  /// refresh the local list whenever Firestore changes so messages
  /// arriving from another device show up immediately.
  void _onChatSnapshot(ChatSnapshot snap) {
    final msgs = snap.messagesByThread[_threadId];
    if (msgs == null) {
      if (_allMessages.isEmpty) return;
      _replaceAll(const []);
      return;
    }
    _replaceAll(msgs);
  }

  /// Replace the in-memory store and re-anchor the pagination window
  /// to the most recent page.
  void _replaceAll(List<ChatMessage> next) {
    // Only swap if the data actually changed — prevents needless
    // notifyListeners() storms on every Firestore heartbeat.
    if (_messagesEqual(_allMessages, next)) return;
    _allMessages
      ..clear()
      ..addAll(next);
    _resetPagination();
    notifyListeners();
  }

  bool _messagesEqual(List<ChatMessage> a, List<ChatMessage> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].content != b[i].content ||
          a[i].role != b[i].role) {
        return false;
      }
    }
    return true;
  }

  /// Pulls the next [pageSize] older messages into the visible window.
  ///
  /// Returns the number of older messages that were actually added
  /// (may be less than [pageSize] when the store is exhausted). Safe
  /// to call repeatedly; concurrent calls are guarded via
  /// [_isLoadingOlder].
  Future<int> loadOlder({int pageSize = defaultPageSize}) async {
    if (_isLoadingOlder) return 0;
    if (_visibleFrom <= 0) return 0;
    if (pageSize <= 0) return 0;

    _isLoadingOlder = true;
    notifyListeners();

    // Simulate a small async tick so the UI gets a frame to show the
    // "loading older" indicator even on very fast devices. The actual
    // data is already in memory; we only need a microtask to flush
    // listeners before we mutate the visible slice.
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final step = pageSize < _visibleFrom ? pageSize : _visibleFrom;
    _visibleFrom -= step;
    final added = step;
    _isLoadingOlder = false;
    notifyListeners();
    return added;
  }

  Future<String> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) {
      throw StateError('empty_or_busy');
    }

    _resetDebugForNewSend();

    _phase = ChatPhase.sending;
    _push(
      ChatPhase.sending,
      'Persisting user message',
      detail: 'len=${trimmed.length} chars',
    );

    final userMsg = ChatMessage(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      threadId: _threadId,
      content: trimmed,
      role: 'user',
      timestamp: DateTime.now(),
    );
    _allMessages.add(userMsg);
    // New messages are always part of the visible window, so no
    // pagination adjustment is needed here.
    await _persist(userMsg);

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Use the FULL chronological history (not just the visible
      // window) so Gemini sees the complete conversation context
      // even when older pages have not been scrolled into view.
      final history = _allMessages
          .take(_allMessages.length - 1)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      _historyCount = history.length;
      _phase = ChatPhase.generating;
      _push(
        ChatPhase.generating,
        'Calling Gemini chatCompletion',
        detail: 'history=$_historyCount | prompt=${trimmed.length} chars',
      );

      final reply = await _service.chatCompletion(
        userMessage: trimmed,
        history: history,
        onAttempt: _onAttempt,
      );

      _phase = ChatPhase.succeeded;
      _error = null;
      _lastRawError = null;
      _push(
        ChatPhase.succeeded,
        'Reply received',
        detail: 'len=${reply.length} chars',
      );

      final botMsg = ChatMessage(
        id: 'a-${DateTime.now().microsecondsSinceEpoch}',
        threadId: _threadId,
        content: reply,
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      _allMessages.add(botMsg);
      await _persist(botMsg);
      return reply;
    } catch (e, st) {
      _error = e.toString();
      _lastRawError = e.toString();
      _phase = ChatPhase.failed;
      _push(ChatPhase.failed, 'Chat error', detail: e.toString());
      developer.log(
        'Chat send error',
        name: 'ChatbotProvider',
        error: e,
        stackTrace: st,
      );
      final fallbackReply = GeminiService.ensureGreeting(
        'কৃষক ভাই, সার্ভারে কিছুটা সাময়িক ট্রাফিক রয়েছে। '
        'আপনার প্রশ্নটির প্রেক্ষিতে সাধারণ পরামর্শ: ফসলে নিয়মিত পর্যবেক্ষণ করুন, '
        'সুষম সার ও সঠিক মাত্রায় বালাইনাশক ব্যবহার করুন। প্রয়োজনে স্থানীয় কৃষি অফিসে যোগাযোগ করুন।',
      );
      final errMsg = ChatMessage(
        id: 'a-${DateTime.now().microsecondsSinceEpoch}',
        threadId: _threadId,
        content: fallbackReply,
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      _allMessages.add(errMsg);
      await _persist(errMsg);
      return fallbackReply;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Callback used by [GeminiService] to report per-model attempts.
  void _onAttempt({
    required String model,
    required int attemptNumber,
    required bool success,
    String? finishReason,
    String? error,
  }) {
    _activeModel = model;
    _attempt = attemptNumber;
    _lastFinishReason = finishReason;

    if (finishReason == 'QUEUED') {
      _phase = ChatPhase.generating;
      _push(
        ChatPhase.generating,
        'Models queued (${GeminiService.fallbackModelsCount})',
        detail: 'primary=$model',
      );
      notifyListeners();
      return;
    }

    if (finishReason == 'CALLING') {
      _phase = ChatPhase.awaitingModel;
      _push(
        ChatPhase.awaitingModel,
        'Calling model',
        detail: 'attempt=#$attemptNumber | model=$model',
      );
      notifyListeners();
      return;
    }

    if (success) {
      _lastRawError = null;
      _error = null;
      _phase = ChatPhase.succeeded;
      _push(
        ChatPhase.succeeded,
        'Attempt #$attemptNumber OK',
        detail: 'model=$model | finishReason=${finishReason ?? 'stop'}',
      );
    } else {
      if (error != null) _lastRawError = error;
      _phase = ChatPhase.retrying;
      _push(
        ChatPhase.retrying,
        'Attempt #$attemptNumber failed',
        detail:
            'model=$model | finishReason=${finishReason ?? '-'} | '
            'error=${error ?? '-'}',
      );
    }
    notifyListeners();
  }

  void _push(ChatPhase phase, String label, {String? detail}) {
    _debugLog.add(DebugEvent(phase: phase, label: label, detail: detail));
    developer.log(
      '[${phase.name}] $label${detail == null ? '' : ' :: $detail'}',
      name: 'ChatbotDebug',
    );
  }

  void _resetDebugForNewSend() {
    _debugLog.clear();
    _attempt = 0;
    _activeModel = null;
    _historyCount = 0;
    _lastFinishReason = null;
    _lastRawError = null;
    _startedAt = DateTime.now();
    _phase = ChatPhase.idle;
    notifyListeners();
  }

  /// Mirror the message into Firestore via [ChatRealtimeService]. The
  /// realtime listener will then echo it back into [_onChatSnapshot]
  /// and update the local list.
  Future<void> _persist(ChatMessage m) async {
    await _chat.saveMessage(m);
  }

  Future<void> clear() async {
    await _chat.deleteThread(_threadId);
    _allMessages.clear();
    _resetPagination();
    _resetDebugForNewSend();
    notifyListeners();
  }

  /// Resets the pagination cursor so that only the newest
  /// [defaultPageSize] messages of [_allMessages] are exposed via
  /// [messages] (or all of them when fewer than a page exist).
  void _resetPagination() {
    if (_allMessages.length <= defaultPageSize) {
      _visibleFrom = 0;
    } else {
      _visibleFrom = _allMessages.length - defaultPageSize;
    }
    _isLoadingOlder = false;
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    super.dispose();
  }
}
