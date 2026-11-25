import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';

/// Dedicated Local Hive Service for Offline Caching of AI Chatbot Messages.
class ChatHiveService {
  ChatHiveService._();
  static final ChatHiveService instance = ChatHiveService._();

  static const String _chatBoxName = 'chat_messages_box';
  Box? _chatBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized && _chatBox?.isOpen == true) return;
    try {
      _chatBox = await Hive.openBox(_chatBoxName);
      _initialized = true;
      debugPrint('[ChatHiveService] Hive chat box initialized.');
    } catch (e) {
      debugPrint('[ChatHiveService] Error initializing Hive: $e');
    }
  }

  Future<void> saveMessages(String threadId, List<ChatMessage> messages) async {
    if (!_initialized || _chatBox == null) return;
    try {
      final jsonList = messages.map((m) => m.toMap()).toList();
      await _chatBox!.put(threadId, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[ChatHiveService] Error saveMessages: $e');
    }
  }

  List<ChatMessage> getMessages(String threadId) {
    if (!_initialized || _chatBox == null) return [];
    try {
      final raw = _chatBox!.get(threadId);
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ChatHiveService] Error getMessages: $e');
    }
    return [];
  }

  Future<void> clearAll() async {
    try {
      await _chatBox?.clear();
    } catch (_) {}
  }
}
