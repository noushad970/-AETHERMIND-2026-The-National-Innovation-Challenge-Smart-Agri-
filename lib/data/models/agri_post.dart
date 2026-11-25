import 'package:cloud_firestore/cloud_firestore.dart';

class AgriPost {
  AgriPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorUsername,
    required this.text,
    this.imageUrl = '',
    this.imageStoragePath = '',
    this.likedByUids = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String authorUid;
  final String authorName;
  final String authorUsername;
  final String text;
  final String imageUrl;
  final String imageStoragePath;
  final List<String> likedByUids;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  bool isLikedBy(String? uid) => uid != null && likedByUids.contains(uid);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'text': text,
      'imageUrl': imageUrl,
      'imageStoragePath': imageStoragePath,
      'likedByUids': likedByUids,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AgriPost.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    final likes = (map['likedByUids'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const [];

    return AgriPost(
      id: (map['id'] ?? docId) as String,
      authorUid: (map['authorUid'] ?? '') as String,
      authorName: (map['authorName'] ?? 'Farmer') as String,
      authorUsername: (map['authorUsername'] ?? '@farmer') as String,
      text: (map['text'] ?? '') as String,
      imageUrl: (map['imageUrl'] ?? '') as String,
      imageStoragePath: (map['imageStoragePath'] ?? '') as String,
      likedByUids: likes,
      likeCount: (map['likeCount'] ?? likes.length) as int,
      commentCount: (map['commentCount'] ?? 0) as int,
      createdAt: parseDate(map['createdAt']),
    );
  }

  AgriPost copyWith({
    List<String>? likedByUids,
    int? likeCount,
    int? commentCount,
  }) {
    return AgriPost(
      id: id,
      authorUid: authorUid,
      authorName: authorName,
      authorUsername: authorUsername,
      text: text,
      imageUrl: imageUrl,
      imageStoragePath: imageStoragePath,
      likedByUids: likedByUids ?? this.likedByUids,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
    );
  }
}
