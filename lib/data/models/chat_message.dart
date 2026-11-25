/// One turn in a chatbot conversation.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.threadId,
    required this.content,
    required this.role, // 'user' | 'assistant'
    required this.timestamp,
    this.imagePath,
  });

  final String id;
  final String threadId;
  final String content;
  final String role;
  final DateTime timestamp;
  final String? imagePath;

  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() => {
    'id': id,
    'threadId': threadId,
    'content': content,
    'role': role,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id: m['id'] as String,
    threadId: m['threadId'] as String,
    content: m['content'] as String,
    role: m['role'] as String,
    timestamp: DateTime.parse(m['timestamp'] as String),
    imagePath: m['imagePath'] as String?,
  );
}
