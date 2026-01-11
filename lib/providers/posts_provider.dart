import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Provider that owns all post content for the app.
///
/// - Fetches posts and reels from Firestore
/// - Filters by community
/// - Allows leaders to create posts and reels
class PostsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<PostModel> _posts = [];
  List<PostModel> _reels = [];
  Map<String, UserModel> _authorsCache = {};
  
  bool _isLoading = false;
  String? _community;
  
  StreamSubscription? _postsSubscription;
  StreamSubscription? _reelsSubscription;

  List<PostModel> get posts => List.unmodifiable(_posts);
  List<PostModel> get reels => List.unmodifiable(_reels);
  bool get isLoading => _isLoading;

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

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _reelsSubscription?.cancel();
    super.dispose();
  }
}

