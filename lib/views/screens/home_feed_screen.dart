import 'package:faith_connect/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/posts_provider.dart';
import '../../providers/app_state_provider.dart';
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
    return Consumer3<FeedProvider, PostsProvider, AppStateProvider>(
      builder: (context, feedProvider, postsProvider, appState, child) {
        // Load posts when community is available
        if (appState.community != null && appState.community!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            postsProvider.loadPosts(appState.community!);
            // Load liked status if user is logged in
            if (appState.userId != null) {
              postsProvider.loadLikedStatus(appState.userId!);
            }
          });
        }

        // Filter posts based on selected tab
        List<PostModel> posts = postsProvider.posts;
        if (feedProvider.isFollowingSelected && appState.userId != null) {
          // For Following tab, we could filter by followed leaders
          // For now, show all posts from community (following filter can be added later)
        }

        // Show loading only if we're loading AND have no posts yet
        final isLoading = postsProvider.isLoading && posts.isEmpty;

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
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : posts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posts from leaders in your community will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (appState.community != null) {
                          await postsProvider.refresh(appState.community!);
                        }
                      },
                      child: ListView.builder(
                        itemCount: posts.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final appState = context.read<AppStateProvider>();
                          final isLiked = postsProvider.isPostLiked(post.id);
                          
                          return PostCard(
                            post: post,
                            isLiked: isLiked,
                            onLike: appState.userId != null
                                ? () async {
                                    try {
                                      await postsProvider.toggleLike(post, appState.userId!);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to like post. Please try again.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            onComment: () {
                              if (appState.userId != null) {
                                // Fetch comments and show bottom sheet
                                postsProvider.fetchComments(post.id, isReel: false);
                                showCommentsBottomSheet(
                                  context,
                                  postId: post.id,
                                  postTitle: '${post.author.name}\'s Post',
                                  isReel: false,
                                );
                              }
                            },
                            onShare: () async {
                              try {
                                await postsProvider.share(post);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to share post. Please try again.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
