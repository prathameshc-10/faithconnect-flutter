import 'package:flutter/foundation.dart';

import '../models/mock_data.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// Provider that owns all post content for the app.
///
/// - Initializes from [MockData.getMockPosts]
/// - Allows leaders to create posts and reels which immediately
///   appear in worshiper feeds and leader profiles.
class PostsProvider with ChangeNotifier {
  final List<PostModel> _posts = List.from(MockData.getMockPosts());

  List<PostModel> get posts => List.unmodifiable(_posts);

  /// All reels (video posts only).
  List<PostModel> get reels =>
      _posts.where((post) => post.videoUrl != null).toList();

  /// Posts for a specific leader (non‑video).
  List<PostModel> postsForLeader(String leaderId) {
    return _posts
        .where((p) => p.author.id == leaderId && p.videoUrl == null)
        .toList();
  }

  /// Reels for a specific leader (video posts).
  List<PostModel> reelsForLeader(String leaderId) {
    return _posts
        .where((p) => p.author.id == leaderId && p.videoUrl != null)
        .toList();
  }

  /// Add a new post or reel created by a leader.
  ///
  /// [isReel] controls whether this is treated as a vertical video reel.
  void addContent({
    required UserModel author,
    required String content,
    bool isReel = false,
  }) {
    final now = DateTime.now();
    final newPost = PostModel(
      id: 'p_${now.millisecondsSinceEpoch}',
      author: author,
      content: content,
      videoUrl: isReel ? 'video_url_placeholder' : null,
      imageUrl: isReel ? null : null,
      createdAt: now,
      likes: 0,
      comments: 0,
      shares: 0,
      views: 0,
    );

    _posts.insert(0, newPost);
    notifyListeners();
  }
}

