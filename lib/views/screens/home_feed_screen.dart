import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/posts_provider.dart';
import '../../models/mock_data.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';

/// Home Feed Screen - Main entry point of the app
/// Displays a feed of posts from religious leaders
/// Uses Provider for state management (Explore/Following tabs)
class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  /// Build segmented control for Explore/Following tabs
  Widget _buildSegmentedControl(BuildContext context, FeedProvider feedProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Explore button
          Expanded(
            child: GestureDetector(
              onTap: () => feedProvider.selectExplore(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: feedProvider.isExploreSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Explore',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: feedProvider.isExploreSelected ? Colors.white : Colors.grey[600],
                    fontWeight: feedProvider.isExploreSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Following button
          Expanded(
            child: GestureDetector(
              onTap: () => feedProvider.selectFollowing(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: feedProvider.isFollowingSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Following',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: feedProvider.isFollowingSelected ? Colors.white : Colors.grey[600],
                    fontWeight: feedProvider.isFollowingSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context);
    final postsProvider = Provider.of<PostsProvider>(context);
    final posts = postsProvider.posts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'Home Feed',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Profile avatar on the right
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildSegmentedControl(context, feedProvider),
        ),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostCard(
            post: post,
            // Example: Trigger comments bottom sheet when comment button is tapped
            onComment: () {
              showCommentsBottomSheet(
                context,
                comments: MockData.getMockComments(),
                postTitle: '${post.author.name}\'s Post',
              );
            },
          );
        },
      ),
    );
  }
}
