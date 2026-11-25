import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:image_picker/image_picker.dart';

import '../../../../data/models/agri_post.dart';
import '../../../../data/models/post_comment.dart';
import '../../../../data/services/feed_service.dart';

class FeedProvider extends ChangeNotifier {
  FeedProvider({FeedService? service})
      : _service = service ?? FeedService();

  final FeedService _service;
  final ImagePicker _picker = ImagePicker();

  List<AgriPost> _posts = [];
  List<AgriPost> get posts => List.unmodifiable(_posts);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  DocumentSnapshot? _lastDocument;
  bool _isPosting = false;
  bool get isPosting => _isPosting;

  /// Reason the feed could not be loaded (a [FeedException] code), or null.
  String? _loadError;
  String? get loadError => _loadError;

  /// Reason the last post / comment / like failed, or null.
  String? _lastError;
  String? get lastError => _lastError;

  /// Reason the last photo pick failed (not set when the user just cancels).
  String? _pickError;
  String? get pickError => _pickError;

  /// Loads the first batch of 10 posts.
  Future<void> loadInitialPosts() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    _loadError = null;
    try {
      final result =
          await _service.fetchPostsBatch(limit: 10, startAfter: null);
      _posts = List.from(result.posts);
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;
    } on FeedException catch (e) {
      _loadError = e.code;
    } catch (e) {
      _loadError = 'unknown';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Triggered on scroll down when nearing bottom: loads next 10 posts.
  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchPostsBatch(
        limit: 10,
        startAfter: _lastDocument,
      );
      // Avoid duplicates if a post was added locally in the meantime.
      final known = _posts.map((p) => p.id).toSet();
      _posts.addAll(result.posts.where((p) => !known.contains(p.id)));
      _lastDocument = result.lastDocument ?? _lastDocument;
      _hasMore = result.hasMore;
    } catch (_) {
      // Keep what is already shown; the next scroll retries.
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Pick and compress image from Camera or Gallery.
  /// Compresses down to imageQuality 50 & scaled dimensions (800x800)
  /// so database/network footprint remains very small.
  Future<Uint8List?> pickAndCompressImage(ImageSource source) async {
    _pickError = null;
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error picking and compressing image: $e');
      _pickError = 'pick-failed';
      return null;
    }
  }

  /// Create and submit a new post. Returns false on failure; the reason is in
  /// [lastError].
  Future<bool> createPost({
    required String authorUid,
    required String authorName,
    required String authorUsername,
    required String text,
    Uint8List? compressedImageBytes,
  }) async {
    if (_isPosting) return false;
    if (text.trim().isEmpty && compressedImageBytes == null) return false;
    _isPosting = true;
    _lastError = null;
    notifyListeners();

    try {
      final newPost = await _service.createPost(
        authorUid: authorUid,
        authorName: authorName,
        authorUsername: authorUsername,
        text: text.trim(),
        compressedImageBytes: compressedImageBytes,
      );
      _posts.insert(0, newPost);
      _loadError = null;
      _isPosting = false;
      notifyListeners();
      return true;
    } on FeedException catch (e) {
      _lastError = e.code;
    } catch (_) {
      _lastError = 'unknown';
    }
    _isPosting = false;
    notifyListeners();
    return false;
  }

  /// Optimistically toggle like on a post.
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final isLiked = post.isLikedBy(userId);

    // Optimistic update
    final newLikedBy = List<String>.from(post.likedByUids);
    if (isLiked) {
      newLikedBy.remove(userId);
    } else {
      newLikedBy.add(userId);
    }
    final newCount = isLiked ? (post.likeCount - 1).clamp(0, 999999) : post.likeCount + 1;

    _posts[index] = post.copyWith(likedByUids: newLikedBy, likeCount: newCount);
    notifyListeners();

    // Commit to Firestore
    final success = await _service.toggleLike(
      postId: postId,
      userId: userId,
      isCurrentlyLiked: isLiked,
    );

    if (!success) {
      // Revert if write failed (look the post up again: the list may have
      // changed while the request was in flight).
      _lastError = 'like-failed';
      final i = _posts.indexWhere((p) => p.id == postId);
      if (i != -1) {
        _posts[i] = post;
      }
      notifyListeners();
    }
  }

  /// Add comment to post and update comment count in memory.
  Future<bool> addComment({
    required String postId,
    required String authorUid,
    required String authorName,
    required String authorUsername,
    required String text,
  }) async {
    if (text.trim().isEmpty) return false;

    _lastError = null;
    try {
      await _service.addComment(
        postId: postId,
        authorUid: authorUid,
        authorName: authorName,
        authorUsername: authorUsername,
        text: text.trim(),
      );
    } on FeedException catch (e) {
      _lastError = e.code;
      return false;
    } catch (_) {
      _lastError = 'unknown';
      return false;
    }

    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _posts[index];
      _posts[index] = post.copyWith(commentCount: post.commentCount + 1);
      notifyListeners();
    }
    return true;
  }

  Stream<List<PostComment>> streamComments(String postId) {
    return _service.streamComments(postId);
  }
}
