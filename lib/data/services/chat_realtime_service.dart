import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import 'chat_hive_service.dart';
import 'firestore_sync_service.dart';

/// Real-time chat service. Streams every chat thread (with its
/// nested messages) for the signed-in user from Firestore. The
/// provider renders thread + message lists directly off the
/// stream — there is no local cache.
///
/// Schema:
///   users/{uid}/chatThreads/{threadId}             -> { id, title, lastMessageAt, lastMessagePreview }
///   users/{uid}/chatThreads/{threadId}/messages/{messageId} -> ChatMessage
class ChatRealtimeService extends ChangeNotifier {
  ChatRealtimeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreSyncService? sync,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _sync = sync ?? FirestoreSyncService() {
    final cached = ChatHiveService.instance.getMessages('default');
    if (cached.isNotEmpty) {
      _messagesByThread['default'] = cached;
    }
    _authSub = _auth.authStateChanges().listen((u) => _onAuthChanged(u?.uid));
    final current = _auth.currentUser?.uid;
    if (current != null) _onAuthChanged(current);
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreSyncService _sync;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _threadsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _messagesSubs = {};

  String? _uid;
  String? _lastError;
  List<ChatThread> _lastThreads = const [];
  final Map<String, List<ChatMessage>> _messagesByThread = {};

  /// Snapshot of all known threads + their messages.
  ChatSnapshot get snapshot => ChatSnapshot(
    threads: List<ChatThread>.unmodifiable(_lastThreads),
    messagesByThread: {
      for (final e in _messagesByThread.entries)
        e.key: List<ChatMessage>.unmodifiable(e.value),
    },
  );

  /// Broadcast stream of snapshot updates. Replays the most recent
  /// value to new subscribers.
  Stream<ChatSnapshot> stream() async* {
    yield snapshot;
    yield* _controller.stream;
  }

  final StreamController<ChatSnapshot> _controller =
      StreamController<ChatSnapshot>.broadcast();

  void _publish() {
    if (!_controller.isClosed) _controller.add(snapshot);
    notifyListeners();
  }

  String? get lastError => _lastError;
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  void _onAuthChanged(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _threadsSub?.cancel();
    _threadsSub = null;
    for (final s in _messagesSubs.values) {
      s.cancel();
    }
    _messagesSubs.clear();
    _messagesByThread.clear();
    _lastThreads = const [];
    if (uid == null) {
      _publish();
      return;
    }

    final threadsCol = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.chatThreadsCollection);
    _threadsSub = threadsCol.snapshots().listen(
      (snap) {
        _lastError = null;
        _fromThreadsSnapshot(snap);
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Chat threads stream failed',
          name: 'ChatRealtimeService',
          error: e,
          stackTrace: st,
        );
        _lastError = 'Realtime chat sync failed: $e';
        notifyListeners();
      },
    );
  }

  void _fromThreadsSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final next = <ChatThread>[];
    final keepSubs = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final thread = ChatThread(
        id: doc.id,
        title: (data['title'] ?? doc.id).toString(),
        lastMessageAt: _parseDate(data['lastMessageAt']),
        lastMessagePreview: data['lastMessagePreview'] as String?,
      );
      next.add(thread);
      keepSubs.add(doc.id);
      if (!_messagesSubs.containsKey(doc.id)) {
        _subscribeMessages(doc.id);
      }
    }
    // Cancel subscriptions for threads that have been removed server-side.
    final removed = _messagesSubs.keys
        .where((k) => !keepSubs.contains(k))
        .toList();
    for (final k in removed) {
      _messagesSubs[k]?.cancel();
      _messagesSubs.remove(k);
      _messagesByThread.remove(k);
    }
    next.sort((a, b) {
      final at = a.lastMessageAt;
      final bt = b.lastMessageAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    _lastThreads = next;
    _publish();
  }

  void _subscribeMessages(String threadId) {
    final col = _firestore
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.chatThreadsCollection)
        .doc(threadId)
        .collection('messages');
    _messagesSubs[threadId] = col.snapshots().listen(
      (snap) {
        final out = <ChatMessage>[];
        for (final doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          try {
            out.add(_messageFromMap(data));
          } catch (e) {
            developer.log(
              'Skipping malformed chat message ${doc.id}: $e',
              name: 'ChatRealtimeService',
            );
          }
        }
        out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _messagesByThread[threadId] = out;
        ChatHiveService.instance.saveMessages(threadId, out);
        _publish();
      },
      onError: (Object e, StackTrace st) {
        developer.log(
          'Chat messages stream failed for $threadId',
          name: 'ChatRealtimeService',
          error: e,
          stackTrace: st,
        );
      },
    );
  }

  ChatMessage _messageFromMap(Map<String, dynamic> m) => ChatMessage(
    id: (m['id'] ?? '').toString(),
    threadId: (m['threadId'] ?? '').toString(),
    content: (m['content'] ?? '').toString(),
    role: (m['role'] ?? 'user').toString(),
    timestamp: _parseDate(m['timestamp']) ?? DateTime.now(),
    imagePath: m['imagePath'] as String?,
  );

  DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is Map) {
      final secs = v['_seconds'];
      if (secs is num) {
        return DateTime.fromMillisecondsSinceEpoch(secs.toInt() * 1000);
      }
    }
    return null;
  }

  /// Force a re-publish of the current snapshot.
  void invalidate() => _publish();

  Future<void> saveMessage(ChatMessage message, {String? threadTitle}) async {
    if (_uid == null) return;
    await _sync.upsertChatMessage(
      threadId: message.threadId,
      message: message,
      threadTitle: threadTitle,
    );
    // Mirror the write into the in-memory snapshot immediately so
    // listeners never observe a stale list while the Firestore echo
    // is still in flight (prevents a just-sent message from briefly
    // "disappearing").
    final existing = _messagesByThread[message.threadId] ?? const [];
    _messagesByThread[message.threadId] = [...existing, message]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _publish();
  }

  Future<void> deleteThread(String threadId) async {
    if (_uid == null) return;
    await _sync.deleteChatThread(threadId);
    _messagesByThread.remove(threadId);
    _lastThreads = _lastThreads.where((t) => t.id != threadId).toList();
    _publish();
  }

  @override
  void dispose() {
    for (final s in _messagesSubs.values) {
      s.cancel();
    }
    _messagesSubs.clear();
    _threadsSub?.cancel();
    _authSub?.cancel();
    _controller.close();
    super.dispose();
  }
}

/// Lightweight thread metadata for the UI. The thread's message
/// list lives in [ChatSnapshot.messagesByThread].
class ChatThread {
  const ChatThread({
    required this.id,
    required this.title,
    required this.lastMessageAt,
    required this.lastMessagePreview,
  });

  final String id;
  final String title;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
}

/// Plain data wrapper so the UI can read threads + their messages
/// in a single immutable view.
class ChatSnapshot {
  const ChatSnapshot({required this.threads, required this.messagesByThread});

  final List<ChatThread> threads;
  final Map<String, List<ChatMessage>> messagesByThread;

  List<ChatMessage> messagesFor(String threadId) =>
      messagesByThread[threadId] ?? const [];
}
