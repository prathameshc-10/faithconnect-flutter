import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../models/post_model.dart';
import '../widgets/comments_bottom_sheet.dart';

/// Reels Screen
/// Full-screen vertical video reel interface with swipe behavior
/// UI-only implementation with PageView for swipe navigation
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();
  late List<PostModel> _reels;

  @override
  void initState() {
    super.initState();
    // Get all video posts (reels)
    final allPosts = MockData.getMockPosts();
    _reels = allPosts.where((post) => post.videoUrl != null).toList();
    
    // If no reels, add a placeholder
    if (_reels.isEmpty) {
      _reels = [allPosts.first];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Format number for display (e.g., 160000 -> 160K)
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Build a single reel item
  Widget _buildReelItem(PostModel reel, double bottomNavHeight) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image placeholder (full screen)
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
                Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  reel.content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
          bottom: bottomNavHeight + 20, // Above bottom navigation with padding
          left: 16,
          right: 80, // Leave space for action buttons
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
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
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
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 16,
                              ),
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
                  // Follow button
                  OutlinedButton(
                    onPressed: () {
                      // Handle follow action (no logic required)
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
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
        
        // Right-aligned vertical action buttons
        Positioned(
          right: 16,
          bottom: bottomNavHeight + 20, // Above bottom navigation with padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.favorite,
                count: _formatNumber(reel.likes),
                onTap: () {
                  // Handle like action (no logic required)
                },
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                count: _formatNumber(reel.comments),
                onTap: () {
                  showCommentsBottomSheet(
                    context,
                    comments: MockData.getMockComments(),
                    postTitle: 'Reel Comments',
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.share,
                count: _formatNumber(reel.shares),
                onTap: () {
                  // Handle share action (no logic required)
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build action button with icon and count
  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required VoidCallback onTap,
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
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get bottom navigation bar height for proper spacing
    final bottomNavHeight = kBottomNavigationBarHeight;
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // Extend body behind bottom navigation
      body: SafeArea(
        bottom: false, // Allow content to extend to bottom navigation area
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _reels.length,
          itemBuilder: (context, index) {
            return _buildReelItem(_reels[index], bottomNavHeight);
          },
        ),
      ),
    );
  }
}
