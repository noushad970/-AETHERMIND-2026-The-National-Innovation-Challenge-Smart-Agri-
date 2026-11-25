import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/agri_atmospheric_background.dart';
import '../../../../core/widgets/header_action_bar.dart';
import '../../../../data/models/agri_post.dart';
import '../../../../data/models/post_comment.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/feed_provider.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadInitialPosts();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<FeedProvider>().loadMorePosts();
    }
  }

  void _openCreatePostModal(BuildContext context, {ImageSource? initialSource}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreatePostModal(initialSource: initialSource),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    final displayName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!
        : context.tr(AppStrings.farmer, AppStrings.farmerBn);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/app_logo.png',
              width: 26,
              height: 26,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.forum_outlined, size: 22),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr(
                AppStrings.communityFeed,
                AppStrings.communityFeedBn,
              ),
            ),
          ],
        ),
        actions: const [
          HeaderActionBar(),
          SizedBox(width: 8),
        ],
      ),
      body: AgriAtmosphericBackground(
        child: RefreshIndicator(
          onRefresh: () => feedProvider.loadInitialPosts(),
          child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: feedProvider.posts.isEmpty
              ? 2
              : 1 + feedProvider.posts.length + (feedProvider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Index 0: Top "Create Post" Card
            if (index == 0) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryGreenLight,
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _openCreatePostModal(context),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Text(
                                context.tr(
                                  'Share questions or updates with farmers...',
                                  'কৃষি সংক্রান্ত প্রশ্ন বা অভিজ্ঞতা লিখুন...',
                                ),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => _openCreatePostModal(
                            context,
                            initialSource: ImageSource.gallery,
                          ),
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            color: AppTheme.primaryGreen,
                            size: 18,
                          ),
                          label: Text(
                            context.tr('Photo', 'ছবি যুক্ত করুন'),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: AppTheme.divider,
                        ),
                        TextButton.icon(
                          onPressed: () => _openCreatePostModal(context),
                          icon: const Icon(
                            Icons.edit_note,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                          label: Text(
                            context.tr(AppStrings.createPost, AppStrings.createPostBn),
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            // If empty and not loading, show empty state
            if (feedProvider.posts.isEmpty) {
              if (feedProvider.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (feedProvider.loadError != null) {
                return _FeedErrorCard(
                  code: feedProvider.loadError!,
                  onRetry: () => feedProvider.loadInitialPosts(),
                );
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        size: 40,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.tr('No Community Posts Yet', 'এখনও কোনো পোস্ট নেই'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'Be the first farmer to share a photo, question, or farming experience!',
                        'প্রথম কৃষক হিসেবে আপনার মাঠের ছবি, প্রশ্ন বা ফসলের অভিজ্ঞতা শেয়ার করুন!',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _openCreatePostModal(context),
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(
                        context.tr('Create First Post', 'প্রথম পোস্টটি তৈরি করুন'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Post Items (indices 1 .. N)
            final postIndex = index - 1;
            if (postIndex < feedProvider.posts.length) {
              final post = feedProvider.posts[postIndex];
              return _PostCard(
                post: post,
                currentUserId: currentUser?.uid,
              );
            }

            // Bottom loading indicator
            return feedProvider.isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.tr(
                              AppStrings.loadingMorePosts,
                              AppStrings.loadingMorePostsBn,
                            ),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(height: 80);
          },
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePostModal(context),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        tooltip: context.tr(AppStrings.createPost, AppStrings.createPostBn),
        icon: const Icon(Icons.add),
        label: Text(
          context.tr(AppStrings.createPost, AppStrings.createPostBn),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
  });

  final AgriPost post;
  final String? currentUserId;

  void _openCommentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CommentsModal(post: post),
    );
  }

  String _formatTime(BuildContext context, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return context.tr('Just now', 'এইমাত্র');
    if (diff.inMinutes < 60) {
      return context.tr(
        '${diff.inMinutes}m ago',
        '${diff.inMinutes} মিনিট আগে',
      );
    }
    if (diff.inHours < 24) {
      return context.tr(
        '${diff.inHours}h ago',
        '${diff.inHours} ঘণ্টা আগে',
      );
    }
    return context.tr(
      '${diff.inDays}d ago',
      '${diff.inDays} দিন আগে',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUserId);
    final feedProvider = context.read<FeedProvider>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryGreenLight,
                child: Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : 'F',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${post.authorUsername} • ${_formatTime(context, post.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post Text
          if (post.text.isNotEmpty)
            Text(
              post.text,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),

          // Compressed Image Preview (if present)
          if (post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: post.imageUrl.startsWith('data:image')
                  ? Image.memory(
                      _dataUriToBytes(post.imageUrl),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      post.imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Action Buttons: Like & Comment
          Row(
            children: [
              // Like Button
              InkWell(
                onTap: () {
                  final uid = currentUserId;
                  if (uid == null) {
                    _showSignInNeeded(context);
                    return;
                  }
                  feedProvider.toggleLike(
                    postId: post.id,
                    userId: uid,
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likeCount} ${context.tr(AppStrings.likesCount, AppStrings.likesCountBn)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isLiked ? Colors.red : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Comment Button
              InkWell(
                onTap: () => _openCommentsModal(context),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount} ${context.tr(AppStrings.commentsCount, AppStrings.commentsCountBn)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Uint8List _dataUriToBytes(String dataUri) {
    try {
      final base64String = dataUri.split(',').last;
      return base64Decode(base64String);
    } catch (_) {
      return Uint8List(0);
    }
  }
}

class _CreatePostModal extends StatefulWidget {
  const _CreatePostModal({this.initialSource});
  final ImageSource? initialSource;

  @override
  State<_CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<_CreatePostModal> {
  final TextEditingController _textController = TextEditingController();
  Uint8List? _compressedImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.initialSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickImage(widget.initialSource!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final feed = context.read<FeedProvider>();
    final bytes = await feed.pickAndCompressImage(source);
    if (!mounted) return;
    if (bytes != null) {
      setState(() => _compressedImageBytes = bytes);
    } else if (feed.pickError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_feedErrorText(context, feed.pickError))),
      );
    }
  }

  Future<void> _submitPost() async {
    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    final user = auth.user;

    // Posts are tied to the signed-in account (the server rules require it).
    if (user == null) {
      _showSignInNeeded(context);
      return;
    }
    final uid = user.uid;
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : context.tr(AppStrings.farmer, AppStrings.farmerBn);
    final username = auth.username.trim().isNotEmpty ? auth.username : '@farmer';

    if (_textController.text.trim().isEmpty && _compressedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Please write something or add a photo.',
              'কিছু লিখুন অথবা ছবি যুক্ত করুন।',
            ),
          ),
        ),
      );
      return;
    }

    final success = await feed.createPost(
      authorUid: uid,
      authorName: displayName,
      authorUsername: username,
      text: _textController.text,
      compressedImageBytes: _compressedImageBytes,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Post published successfully!',
              'পোস্টটি সফলভাবে প্রকাশিত হয়েছে!',
            ),
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.tr('Failed to submit post.', 'পোস্ট প্রকাশ করা যায়নি।')} '
            '${_feedErrorText(context, feed.lastError)}',
          ),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPosting = context.watch<FeedProvider>().isPosting;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Title & Close Icon
              Row(
                children: [
                  const Icon(Icons.edit_square, color: AppTheme.primaryGreen, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    context.tr(AppStrings.createPost, AppStrings.createPostBn),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Post Text Box
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: context.tr(
                      AppStrings.postContentHint,
                      AppStrings.postContentHintBn,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ALWAYS-VISIBLE ADD IMAGE SECTION
              if (_compressedImageBytes != null) ...[
                // Image preview with clear removal button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('Photo Attached (Compressed)', 'ছবি যুক্ত করা হয়েছে (কম্প্রেসড)'),
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(() => _compressedImageBytes = null),
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            label: Text(
                              context.tr('Remove', 'মুছুন'),
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _compressedImageBytes!,
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Prominent Add Image Action Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_photo_alternate, color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('Add Photo to Post:', 'ছবি যুক্ত করুন:'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryGreen,
                                elevation: 0,
                                side: const BorderSide(color: AppTheme.primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt_outlined, size: 18),
                              label: Text(
                                context.tr('Camera', 'ক্যামেরা'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryGreen,
                                elevation: 0,
                                side: const BorderSide(color: AppTheme.primaryGreen),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.photo_library_outlined, size: 18),
                              label: Text(
                                context.tr('Gallery', 'গ্যালারি'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Prominent Full-Width Bottom Submit Post Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    context.tr('Publish Post', 'পোস্ট প্রকাশ করুন'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsModal extends StatefulWidget {
  const _CommentsModal({required this.post});
  final AgriPost post;

  @override
  State<_CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<_CommentsModal> {
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  late final Stream<List<PostComment>> _commentsStream;

  @override
  void initState() {
    super.initState();
    // Create the stream once; re-creating it on every rebuild would
    // resubscribe to Firestore and flicker the list.
    _commentsStream = context.read<FeedProvider>().streamComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final feed = context.read<FeedProvider>();
    final user = auth.user;

    if (user == null) {
      _showSignInNeeded(context);
      return;
    }
    final uid = user.uid;
    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : context.tr(AppStrings.farmer, AppStrings.farmerBn);
    final username = auth.username.trim().isNotEmpty ? auth.username : '@farmer';

    setState(() => _isSubmitting = true);
    final success = await feed.addComment(
      postId: widget.post.id,
      authorUid: uid,
      authorName: displayName,
      authorUsername: username,
      text: text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _commentCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_feedErrorText(context, feed.lastError)),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  context.tr(
                    AppStrings.commentsCount,
                    AppStrings.commentsCountBn,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // Real-time comments stream
            Expanded(
              child: StreamBuilder<List<PostComment>>(
                stream: _commentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final err = snapshot.error;
                    return Center(
                      child: Text(
                        _feedErrorText(
                          context,
                          err is FirebaseException ? err.code : 'unknown',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr(
                          'No comments yet. Be the first to comment!',
                          'এখনও কোনো মন্তব্য নেই। প্রথম মন্তব্য করুন!',
                        ),
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryGreenLight,
                          child: Text(
                            c.authorName.isNotEmpty
                                ? c.authorName[0].toUpperCase()
                                : 'F',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          c.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.text,
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '${c.authorUsername} • ${_formatCommentTime(context, c.createdAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Comment Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: context.tr(
                          'Write a comment...',
                          'একটি মন্তব্য লিখুন...',
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppTheme.divider),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppTheme.primaryGreen),
                    onPressed: _isSubmitting ? null : _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCommentTime(BuildContext context, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return context.tr('Just now', 'এইমাত্র');
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

/// Friendly, bilingual text for a feed failure code (see `FeedException`).
String _feedErrorText(BuildContext context, String? code) {
  switch (code) {
    case 'permission-denied':
      return context.tr(
        'Not allowed by the server. Please sign in again. (Admin: deploy the latest Firestore rules.)',
        'সার্ভার অনুমতি দেয়নি। অনুগ্রহ করে আবার সাইন ইন করুন। (অ্যাডমিন: সর্বশেষ Firestore rules ডিপ্লয় করুন।)',
      );
    case 'unauthenticated':
      return context.tr(
        'Please sign in to use the community.',
        'কমিউনিটি ব্যবহারে অনুগ্রহ করে সাইন ইন করুন।',
      );
    case 'unavailable':
    case 'timeout':
      return context.tr(
        'Network is slow or offline. Please try again.',
        'নেটওয়ার্ক ধীর বা বন্ধ। অনুগ্রহ করে আবার চেষ্টা করুন।',
      );
    case 'image-too-large':
      return context.tr(
        'The photo is too large. Please choose a smaller photo.',
        'ছবিটি অনেক বড়। অনুগ্রহ করে ছোট ছবি বেছে নিন।',
      );
    case 'pick-failed':
      return context.tr(
        'Could not open the camera or gallery on this device.',
        'এই ডিভাইসে ক্যামেরা বা গ্যালারি খোলা যায়নি।',
      );
    default:
      return context.tr(
        'Something went wrong. Please try again.',
        'কিছু ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      );
  }
}

void _showSignInNeeded(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(_feedErrorText(context, 'unauthenticated')),
      backgroundColor: AppTheme.danger,
    ),
  );
}

/// Shown instead of the empty state when the feed could not be loaded.
class _FeedErrorCard extends StatelessWidget {
  const _FeedErrorCard({required this.code, required this.onRetry});

  final String code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.danger),
          const SizedBox(height: 12),
          Text(
            context.tr('Could not load posts', 'পোস্ট লোড করা যায়নি'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            _feedErrorText(context, code),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.tr('Retry', 'আবার চেষ্টা করুন')),
          ),
        ],
      ),
    );
  }
}
