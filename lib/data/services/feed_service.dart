import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/agri_post.dart';
import '../models/post_comment.dart';

/// A feed operation failed. [code] is a short machine-readable reason
/// (`permission-denied`, `unauthenticated`, `timeout`, `image-too-large`,
/// `unavailable`, `unknown`) that the UI turns into a friendly message.
class FeedException implements Exception {
  const FeedException(this.code, [this.details]);

  final String code;
  final String? details;

  /// Maps any thrown object to a [FeedException].
  factory FeedException.from(Object e) {
    if (e is FeedException) return e;
    if (e is FirebaseException) {
      return FeedException(e.code, e.message);
    }
    if (e is TimeoutException) {
      return const FeedException('timeout');
    }
    return FeedException('unknown', e.toString());
  }

  @override
  String toString() => 'FeedException($code${details != null ? ': $details' : ''})';
}

class PaginatedPostsResult {
  const PaginatedPostsResult({
    required this.posts,
    this.lastDocument,
    required this.hasMore,
  });

  final List<AgriPost> posts;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

/// Fully backend-driven FeedService communicating directly with Cloud Firestore
/// and Firebase Storage for real user posts, compressed photos, likes, and comments.
class FeedService {
  FeedService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  /// Largest image (bytes) that may be embedded as base64 in a post document.
  /// Base64 adds ~33%, and a Firestore document is limited to 1 MiB.
  static const int _maxEmbeddedImageBytes = 600 * 1024;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection('posts');

  /// Fetches real user posts from Firestore in batches of [limit].
  ///
  /// Throws a [FeedException] on failure so the UI can show the real reason
  /// (for example `permission-denied`) instead of an empty feed.
  Future<PaginatedPostsResult> fetchPostsBatch({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _postsRef.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get().timeout(const Duration(seconds: 15));
      if (snapshot.docs.isEmpty) {
        return const PaginatedPostsResult(posts: [], hasMore: false);
      }

      final posts = <AgriPost>[];
      for (final doc in snapshot.docs) {
        try {
          posts.add(AgriPost.fromMap(doc.data(), doc.id));
        } catch (e) {
          // One malformed document must not hide the whole feed.
          developer.log('Skipping bad post ${doc.id}: $e', name: 'FeedService');
        }
      }

      return PaginatedPostsResult(
        posts: posts,
        lastDocument: snapshot.docs.last,
        hasMore: snapshot.docs.length >= limit,
      );
    } catch (e, st) {
      developer.log(
        'fetchPostsBatch error: $e',
        name: 'FeedService',
        error: e,
        stackTrace: st,
      );
      throw FeedException.from(e);
    }
  }

  /// Create a new real post with text and compressed photo in Firebase.
  /// Throws a [FeedException] if the post could not be saved.
  Future<AgriPost> createPost({
    required String authorUid,
    required String authorName,
    required String authorUsername,
    required String text,
    Uint8List? compressedImageBytes,
  }) async {
    final postId = _uuid.v4();
    String imageUrl = '';
    String imageStoragePath = '';

    // If an image was selected, upload it to Firebase Storage. If Storage is
    // unavailable (not enabled, rules, offline) fall back to embedding the
    // already-compressed image in the post document, as long as it is small
    // enough to fit in a Firestore document (hard limit 1 MiB).
    if (compressedImageBytes != null && compressedImageBytes.isNotEmpty) {
      try {
        final path = 'posts/$authorUid/$postId.jpg';
        final ref = _storage.ref().child(path);
        final uploadTask = await ref
            .putData(
              compressedImageBytes,
              SettableMetadata(contentType: 'image/jpeg'),
            )
            .timeout(const Duration(seconds: 15));
        imageUrl = await uploadTask.ref.getDownloadURL();
        imageStoragePath = path;
      } catch (e) {
        developer.log(
          'Firebase Storage upload unavailable: $e. Embedding image in post.',
          name: 'FeedService',
        );
        if (compressedImageBytes.length > _maxEmbeddedImageBytes) {
          throw const FeedException('image-too-large');
        }
        imageUrl = 'data:image/jpeg;base64,${base64Encode(compressedImageBytes)}';
      }
    }

    final post = AgriPost(
      id: postId,
      authorUid: authorUid,
      authorName: authorName,
      authorUsername: authorUsername,
      text: text,
      imageUrl: imageUrl,
      imageStoragePath: imageStoragePath,
      likedByUids: const [],
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
    );

    try {
      await _postsRef.doc(postId).set(post.toMap()).timeout(
            const Duration(seconds: 20),
          );
      return post;
    } catch (e, st) {
      developer.log(
        'createPost Firestore write error: $e',
        name: 'FeedService',
        error: e,
        stackTrace: st,
      );
      throw FeedException.from(e);
    }
  }

  /// Atomically toggles like for [userId] on post [postId] in Firestore.
  Future<bool> toggleLike({
    required String postId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    try {
      final docRef = _postsRef.doc(postId);
      if (isCurrentlyLiked) {
        await docRef.update({
          'likedByUids': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update({
          'likedByUids': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
      return true;
    } catch (e) {
      developer.log('toggleLike error: $e', name: 'FeedService', error: e);
      return false;
    }
  }

  /// Streams real-time comments for post [postId] from Firestore.
  Stream<List<PostComment>> streamComments(String postId) {
    try {
      return _postsRef
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => PostComment.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      developer.log('streamComments error: $e', name: 'FeedService');
      return Stream.value(const []);
    }
  }

  /// Adds a real comment to Firestore and atomically increments the post commentCount.
  Future<PostComment> addComment({
    required String postId,
    required String authorUid,
    required String authorName,
    required String authorUsername,
    required String text,
  }) async {
    final commentId = _uuid.v4();
    final comment = PostComment(
      id: commentId,
      postId: postId,
      authorUid: authorUid,
      authorName: authorName,
      authorUsername: authorUsername,
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      final batch = _firestore.batch();
      final commentRef =
          _postsRef.doc(postId).collection('comments').doc(commentId);
      final postRef = _postsRef.doc(postId);

      batch.set(commentRef, comment.toMap());
      batch.update(postRef, {'commentCount': FieldValue.increment(1)});

      await batch.commit().timeout(const Duration(seconds: 20));
      return comment;
    } catch (e, st) {
      developer.log('addComment error: $e', name: 'FeedService', error: e, stackTrace: st);
      throw FeedException.from(e);
    }
  }
}
