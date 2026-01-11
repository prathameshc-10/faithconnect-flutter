import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../models/post_model.dart';
import '../../providers/posts_provider.dart';
import '../../providers/app_state_provider.dart';
import '../widgets/comments_bottom_sheet.dart';

/// Reels Screen with actual video playback
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _videoControllers = {};
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    // Dispose all video controllers
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  /// Initialize video controller for a specific index
  Future<void> _initializeVideoController(int index, String videoUrl) async {
    if (_videoControllers.containsKey(index)) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = controller;

      await controller.initialize();
      controller.setLooping(true);

      // Auto-play if it's the current page
      if (index == _currentPage && mounted) {
        controller.play();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  /// Handle page change
  void _onPageChanged(int page) {
    setState(() {
      // Pause previous video
      _videoControllers[_currentPage]?.pause();

      // Update current page
      _currentPage = page;

      // Play new video
      _videoControllers[page]?.play();
    });
  }

  /// Format number for display
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Build a single reel item with video player
  Widget _buildReelItem(PostModel reel, int index, double bottomNavHeight, PostsProvider postsProvider, BuildContext context) {
    final videoController = _videoControllers[index];
    final hasVideo = reel.videoUrl != null && reel.videoUrl!.isNotEmpty;

    // Initialize video if available and not already initialized
    if (hasVideo && !_videoControllers.containsKey(index)) {
      _initializeVideoController(index, reel.videoUrl!);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player or placeholder
        if (hasVideo && videoController != null && videoController.value.isInitialized)
          GestureDetector(
            onTap: () {
              // Toggle play/pause on tap
              setState(() {
                if (videoController.value.isPlaying) {
                  videoController.pause();
                } else {
                  videoController.play();
                }
              });
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoController.value.size.width,
                height: videoController.value.size.height,
                child: VideoPlayer(videoController),
              ),
            ),
          )
        else
          // Placeholder while video loads or if no video
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[900]!,
                  Colors.grey[800]!,
                  Colors.grey[900]!,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasVideo)
                    const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  else
                    Icon(
                      Icons.play_circle_outline,
                      size: 80,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    hasVideo ? 'Loading video...' : 'No video available',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Play/Pause overlay indicator
        if (videoController != null && videoController.value.isInitialized)
          Center(
            child: AnimatedOpacity(
              opacity: videoController.value.isPlaying ? 0.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  videoController.value.isPlaying
                      ? Icons.play_arrow
                      : Icons.pause,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Bottom gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Bottom content: Author info and description
        Positioned(
          bottom: bottomNavHeight + 20,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Author row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: reel.author.profileImageUrl.isNotEmpty
                        ? NetworkImage(reel.author.profileImageUrl)
                        : null,
                    child: reel.author.profileImageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reel.author.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (reel.author.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ],
                          ],
                        ),
                        Text(
                          reel.author.username,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Follow', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reel.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Right-aligned action buttons
        Positioned(
          right: 16,
          bottom: bottomNavHeight + 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer2<PostsProvider, AppStateProvider>(
                builder: (context, postsProvider, appState, child) {
                  final isLiked = postsProvider.isReelLiked(reel.id);
                  return _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    count: _formatNumber(reel.likes),
                    onTap: appState.userId != null
                        ? () async {
                            try {
                              await postsProvider.toggleLike(reel, appState.userId!);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to like reel. Please try again.'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    isLiked: isLiked,
                  );
                },
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) => _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: _formatNumber(reel.comments),
                  onTap: () {
                    final appState = context.read<AppStateProvider>();
                    final postsProvider = context.read<PostsProvider>();
                    if (appState.userId != null) {
                      postsProvider.fetchComments(reel.id, isReel: true);
                      showCommentsBottomSheet(
                        context,
                        postId: reel.id,
                        postTitle: 'Reel Comments',
                        isReel: true,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) => _buildActionButton(
                  icon: Icons.share,
                  count: _formatNumber(reel.shares),
                  onTap: () async {
                    final postsProvider = context.read<PostsProvider>();
                    try {
                      await postsProvider.share(reel);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to share reel. Please try again.'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    VoidCallback? onTap,
    bool isLiked = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Icon(
                icon,
                color: isLiked ? Colors.red : Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PostsProvider, AppStateProvider>(
      builder: (context, postsProvider, appState, child) {
        if (appState.community != null && appState.community!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            postsProvider.loadReels(appState.community!);
            // Load liked status if user is logged in
            if (appState.userId != null) {
              postsProvider.loadLikedStatus(appState.userId!);
            }
          });
        }

        final reels = postsProvider.reels;
        final isLoading = postsProvider.isLoading;
        final bottomNavHeight = kBottomNavigationBarHeight;

        if (isLoading) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (reels.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            extendBody: true,
            body: SafeArea(
              bottom: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No reels yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[300])),
                      const SizedBox(height: 8),
                      Text(
                        'Reels from leaders in your community will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                return _buildReelItem(reels[index], index, bottomNavHeight, postsProvider, context);
              },
            ),
          ),
        );
      },
    );
  }
}