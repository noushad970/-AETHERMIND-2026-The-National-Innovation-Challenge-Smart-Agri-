import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  PostComment({
    required this.id,
    required this.postId,
    required this.authorUid,
    required this.authorName,
    required this.authorUsername,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String postId;
  final String authorUid;
  final String authorName;
  final String authorUsername;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PostComment.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return PostComment(
      id: (map['id'] ?? docId) as String,
      postId: (map['postId'] ?? '') as String,
      authorUid: (map['authorUid'] ?? '') as String,
      authorName: (map['authorName'] ?? 'Farmer') as String,
      authorUsername: (map['authorUsername'] ?? '@farmer') as String,
      text: (map['text'] ?? '') as String,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
