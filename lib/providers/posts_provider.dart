import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../services/firestore_service.dart';
import '../services/share_service.dart';

/// Provider that owns all post content for the app.
///
/// - Fetches posts and reels from Firestore
/// - Filters by community
/// - Allows leaders to create posts and reels
class PostsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ShareService _shareService = ShareService();
  
  List<PostModel> _posts = [];
  List<PostModel> _reels = [];
  Map<String, UserModel> _authorsCache = {};
  
  bool _isLoading = false;
  String? _community;
  
  StreamSubscription? _postsSubscription;
  StreamSubscription? _reelsSubscription;
  
  // Like state
  Set<String> _likedPostIds = {};
  Set<String> _likedReelIds = {};
  Map<String, StreamSubscription> _likeSubscriptions = {};
  
  // Comment state
  Map<String, List<CommentModel>> _commentsCache = {};
  Map<String, StreamSubscription> _commentSubscriptions = {};
  Map<String, bool> _isLoadingComments = {};

  List<PostModel> get posts => List.unmodifiable(_posts);
  List<PostModel> get reels => List.unmodifiable(_reels);
  bool get isLoading => _isLoading;
  
  /// Check if a post is liked by the current user
  bool isPostLiked(String postId) => _likedPostIds.contains(postId);
  
  /// Check if a reel is liked by the current user
  bool isReelLiked(String reelId) => _likedReelIds.contains(reelId);
  
  /// Get comments for a post
  List<CommentModel> getComments(String postId) => 
      _commentsCache[postId] ?? [];
  
  /// Check if comments are loading for a post
  bool isLoadingComments(String postId) => 
      _isLoadingComments[postId] ?? false;

  /// Load posts from Firestore filtered by community
  Future<void> loadPosts(String community) async {
    if (community.isEmpty) return;
    
    // Cancel previous subscription
    await _postsSubscription?.cancel();
    
    // Only set loading if we're switching communities or first load
    if (_community != community || _posts.isEmpty) {
      _community = community;
      _isLoading = true;
      _posts = [];
      notifyListeners();
    }

    try {
      // Listen to posts stream
      _postsSubscription = _firestoreService.getPostsByCommunity(community).listen(
        (postsData) async {
          _posts = await _convertPostsData(postsData);
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error loading posts: $error');
          _isLoading = false;
          _posts = [];
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading posts: $e');
      _isLoading = false;
      _posts = [];
      notifyListeners();
    }
  }

  /// Load reels from Firestore filtered by community
  Future<void> loadReels(String community) async {
    if (community.isEmpty) return;

    // Cancel previous subscription
    await _reelsSubscription?.cancel();

    try {
      // Listen to reels stream
      _reelsSubscription = _firestoreService.getReelsByCommunity(community).listen(
        (reelsData) async {
          _reels = await _convertReelsData(reelsData);
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error loading reels: $error');
        },
      );
    } catch (e) {
      debugPrint('Error loading reels: $e');
    }
  }

  /// Convert Firestore post data to PostModel
  Future<List<PostModel>> _convertPostsData(List<Map<String, dynamic>> postsData) async {
    final posts = <PostModel>[];
    
    for (final data in postsData) {
      final authorId = data['authorId'] as String;
      final author = await _getAuthor(authorId);
      
      if (author == null) continue;
      
      final timestamp = data['createdAt'] as firestore.Timestamp?;
      posts.add(PostModel(
        id: data['id'] as String,
        author: author,
        content: data['content'] as String? ?? '',
        videoUrl: (data['videoUrl'] as String?)?.isNotEmpty == true 
            ? data['videoUrl'] as String 
            : null,
        imageUrl: (data['imageUrl'] as String?)?.isNotEmpty == true 
            ? data['imageUrl'] as String 
            : null,
        createdAt: timestamp?.toDate() ?? DateTime.now(),
        likes: (data['likes'] as int?) ?? 0,
        comments: (data['comments'] as int?) ?? 0,
        shares: (data['shares'] as int?) ?? 0,
        views: (data['views'] as int?) ?? 0,
      ));
    }
    
    return posts;
  }

  /// Convert Firestore reel data to PostModel
  Future<List<PostModel>> _convertReelsData(List<Map<String, dynamic>> reelsData) async {
    final reels = <PostModel>[];
    
    for (final data in reelsData) {
      final authorId = data['authorId'] as String;
      final author = await _getAuthor(authorId);
      
      if (author == null) continue;
      
      final timestamp = data['createdAt'] as firestore.Timestamp?;
      reels.add(PostModel(
        id: data['id'] as String,
        author: author,
        content: data['content'] as String? ?? '',
        videoUrl: data['videoUrl'] as String? ?? '',
        createdAt: timestamp?.toDate() ?? DateTime.now(),
        likes: (data['likes'] as int?) ?? 0,
        comments: (data['comments'] as int?) ?? 0,
        shares: (data['shares'] as int?) ?? 0,
        views: (data['views'] as int?) ?? 0,
      ));
    }
    
    return reels;
  }

  /// Get author data from cache or Firestore
  Future<UserModel?> _getAuthor(String authorId) async {
    if (_authorsCache.containsKey(authorId)) {
      return _authorsCache[authorId];
    }

    try {
      final leaderData = await _firestoreService.getLeaderData(authorId);
      if (leaderData != null) {
        final author = UserModel(
          id: authorId,
          name: leaderData['name'] as String? ?? '',
          username: '@${(leaderData['name'] as String? ?? '').toLowerCase().replaceAll(' ', '_')}',
          profileImageUrl: leaderData['profileImageUrl'] as String? ?? '',
          isVerified: false,
          description: leaderData['bio'] as String?,
          community: leaderData['community'] as String?,
          role: leaderData['role'] as String?,
        );
        _authorsCache[authorId] = author;
        return author;
      }
    } catch (e) {
      debugPrint('Error fetching author: $e');
    }

    return null;
  }

  /// Posts for a specific leader (non‑video).
  List<PostModel> postsForLeader(String leaderId) {
    return _posts
        .where((p) => p.author.id == leaderId && p.videoUrl == null)
        .toList();
  }

  /// Reels for a specific leader (video posts).
  List<PostModel> reelsForLeader(String leaderId) {
    return _reels
        .where((p) => p.author.id == leaderId)
        .toList();
  }

  /// Refresh posts and reels
  Future<void> refresh(String community) async {
    await _postsSubscription?.cancel();
    await _reelsSubscription?.cancel();
    _posts = [];
    _reels = [];
    _authorsCache = {};
    _community = null;
    await loadPosts(community);
    await loadReels(community);
  }

  /// Share a post or reel
  /// Opens the native share sheet and increments the share count on success
  /// 
  /// [post] - The post or reel to share
  /// Automatically detects if it's a post or reel based on which list contains it
  Future<void> share(PostModel post) async {
    try {
      // Open native share sheet
      final shareSuccess = await _shareService.sharePost(
        text: post.content,
        videoUrl: post.videoUrl,
      );

      if (shareSuccess) {
        // Determine if it's a reel or post by checking which list contains it
        final isReel = _reels.any((p) => p.id == post.id);
        
        // Increment share count in Firestore
        if (isReel) {
          await _firestoreService.shareReel(post.id);
        } else {
          await _firestoreService.sharePost(post.id);
        }

        // Optimistically update local state
        if (isReel) {
          final index = _reels.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _reels[index] = PostModel(
              id: post.id,
              author: post.author,
              content: post.content,
              videoUrl: post.videoUrl,
              imageUrl: post.imageUrl,
              createdAt: post.createdAt,
              likes: post.likes,
              comments: post.comments,
              shares: post.shares + 1,
              views: post.views,
            );
          }
        } else {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = PostModel(
              id: post.id,
              author: post.author,
              content: post.content,
              videoUrl: post.videoUrl,
              imageUrl: post.imageUrl,
              createdAt: post.createdAt,
              likes: post.likes,
              comments: post.comments,
              shares: post.shares + 1,
              views: post.views,
            );
          }
        }

        notifyListeners();
      }
      // If share failed, do nothing (error handling in UI)
    } catch (e) {
      debugPrint('Error sharing post: $e');
      // Re-throw to allow UI to handle error
      rethrow;
    }
  }

  /// Toggle like on a post or reel
  /// [post] - The post or reel to like/unlike
  /// [userId] - The current user's ID
  Future<void> toggleLike(PostModel post, String userId) async {
    try {
      final isReel = _reels.any((p) => p.id == post.id);
      final isLiked = isReel 
          ? _likedReelIds.contains(post.id)
          : _likedPostIds.contains(post.id);
      
      // Optimistically update UI
      if (isReel) {
        if (isLiked) {
          _likedReelIds.remove(post.id);
        } else {
          _likedReelIds.add(post.id);
        }
      } else {
        if (isLiked) {
          _likedPostIds.remove(post.id);
        } else {
          _likedPostIds.add(post.id);
        }
      }
      
      // Update local post/reel model
      final newLikes = isLiked ? post.likes - 1 : post.likes + 1;
      final updatedPost = PostModel(
        id: post.id,
        author: post.author,
        content: post.content,
        videoUrl: post.videoUrl,
        imageUrl: post.imageUrl,
        createdAt: post.createdAt,
        likes: newLikes < 0 ? 0 : newLikes,
        comments: post.comments,
        shares: post.shares,
        views: post.views,
      );
      
      if (isReel) {
        final index = _reels.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _reels[index] = updatedPost;
        }
      } else {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      }
      
      notifyListeners();
      
      // Update Firestore
      if (isReel) {
        if (isLiked) {
          await _firestoreService.unlikeReel(
            reelId: post.id,
            userId: userId,
          );
        } else {
          await _firestoreService.likeReel(
            reelId: post.id,
            userId: userId,
          );
        }
      } else {
        if (isLiked) {
          await _firestoreService.unlikePost(
            postId: post.id,
            userId: userId,
          );
        } else {
          await _firestoreService.likePost(
            postId: post.id,
            userId: userId,
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Roll back optimistic update
      final isReel = _reels.any((p) => p.id == post.id);
      final wasLiked = isReel 
          ? !_likedReelIds.contains(post.id)
          : !_likedPostIds.contains(post.id);
      
      if (isReel) {
        if (wasLiked) {
          _likedReelIds.add(post.id);
        } else {
          _likedReelIds.remove(post.id);
        }
      } else {
        if (wasLiked) {
          _likedPostIds.add(post.id);
        } else {
          _likedPostIds.remove(post.id);
        }
      }
      
      // Restore original post
      if (isReel) {
        final index = _reels.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _reels[index] = post;
        }
      } else {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post;
        }
      }
      
      notifyListeners();
      rethrow;
    }
  }

  /// Load liked status for posts and reels
  /// Call this when user logs in or when loading posts
  Future<void> loadLikedStatus(String userId) async {
    try {
      // Load liked posts
      for (final post in _posts) {
        final isLiked = await _firestoreService.isPostLiked(
          postId: post.id,
          userId: userId,
        );
        if (isLiked) {
          _likedPostIds.add(post.id);
        }
      }
      
      // Load liked reels
      for (final reel in _reels) {
        final isLiked = await _firestoreService.isReelLiked(
          reelId: reel.id,
          userId: userId,
        );
        if (isLiked) {
          _likedReelIds.add(reel.id);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading liked status: $e');
    }
  }

  /// Fetch comments for a post or reel
  /// [postId] - The post or reel ID
  /// [isReel] - Whether this is a reel (true) or post (false)
  Future<void> fetchComments(String postId, {bool isReel = false}) async {
    // Cancel existing subscription if any
    _commentSubscriptions[postId]?.cancel();
    
    _isLoadingComments[postId] = true;
    notifyListeners();
    
    try {
      Stream<List<Map<String, dynamic>>> commentsStream;
      if (isReel) {
        commentsStream = _firestoreService.getReelComments(postId);
      } else {
        commentsStream = _firestoreService.getPostComments(postId);
      }
      
      _commentSubscriptions[postId] = commentsStream.listen(
        (commentsData) async {
          final comments = <CommentModel>[];
          
          for (final data in commentsData) {
            final comment = CommentModel.fromFirestore(data, data['id'] as String);
            
            // Load author data
            final authorId = comment.userId;
            final author = await _getAuthor(authorId);
            
            if (author != null) {
              comments.add(CommentModel(
                id: comment.id,
                userId: comment.userId,
                text: comment.text,
                createdAt: comment.createdAt,
                author: author,
              ));
            }
          }
          
          _commentsCache[postId] = comments;
          _isLoadingComments[postId] = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error fetching comments: $error');
          _isLoadingComments[postId] = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      _isLoadingComments[postId] = false;
      notifyListeners();
    }
  }

  /// Add a comment to a post or reel
  /// [postId] - The post or reel ID
  /// [userId] - The current user's ID
  /// [text] - The comment text
  /// [isReel] - Whether this is a reel (true) or post (false)
  Future<void> addComment({
    required String postId,
    required String userId,
    required String text,
    bool isReel = false,
  }) async {
    if (text.trim().isEmpty) return;
    
    try {
      // Optimistically add comment to UI
      final author = await _getAuthor(userId);
      if (author == null) {
        throw Exception('Author not found');
      }
      
      final newComment = CommentModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        text: text.trim(),
        createdAt: DateTime.now(),
        author: author,
      );
      
      final currentComments = _commentsCache[postId] ?? [];
      _commentsCache[postId] = [newComment, ...currentComments];
      
      // Update comment count optimistically
      final isReelPost = _reels.any((p) => p.id == postId);
      if (isReelPost) {
        final index = _reels.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _reels[index];
          _reels[index] = PostModel(
            id: post.id,
            author: post.author,
            content: post.content,
            videoUrl: post.videoUrl,
            imageUrl: post.imageUrl,
            createdAt: post.createdAt,
            likes: post.likes,
            comments: post.comments + 1,
            shares: post.shares,
            views: post.views,
          );
        }
      } else {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = PostModel(
            id: post.id,
            author: post.author,
            content: post.content,
            videoUrl: post.videoUrl,
            imageUrl: post.imageUrl,
            createdAt: post.createdAt,
            likes: post.likes,
            comments: post.comments + 1,
            shares: post.shares,
            views: post.views,
          );
        }
      }
      
      notifyListeners();
      
      // Add comment to Firestore
      if (isReel) {
        await _firestoreService.addReelComment(
          reelId: postId,
          userId: userId,
          text: text.trim(),
        );
      } else {
        await _firestoreService.addComment(
          postId: postId,
          userId: userId,
          text: text.trim(),
        );
      }
      
      // Comment will be updated via stream, so we don't need to manually update
    } catch (e) {
      debugPrint('Error adding comment: $e');
      
      // Roll back optimistic update
      final currentComments = _commentsCache[postId] ?? [];
      if (currentComments.isNotEmpty && currentComments.first.id.startsWith('temp_')) {
        _commentsCache[postId] = currentComments.skip(1).toList();
      }
      
      // Roll back comment count
      final isReelPost = _reels.any((p) => p.id == postId);
      if (isReelPost) {
        final index = _reels.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _reels[index];
          _reels[index] = PostModel(
            id: post.id,
            author: post.author,
            content: post.content,
            videoUrl: post.videoUrl,
            imageUrl: post.imageUrl,
            createdAt: post.createdAt,
            likes: post.likes,
            comments: (post.comments - 1).clamp(0, double.infinity).toInt(),
            shares: post.shares,
            views: post.views,
          );
        }
      } else {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = PostModel(
            id: post.id,
            author: post.author,
            content: post.content,
            videoUrl: post.videoUrl,
            imageUrl: post.imageUrl,
            createdAt: post.createdAt,
            likes: post.likes,
            comments: (post.comments - 1).clamp(0, double.infinity).toInt(),
            shares: post.shares,
            views: post.views,
          );
        }
      }
      
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _reelsSubscription?.cancel();
    
    // Cancel all comment subscriptions
    for (var subscription in _commentSubscriptions.values) {
      subscription.cancel();
    }
    _commentSubscriptions.clear();
    
    super.dispose();
  }
}

