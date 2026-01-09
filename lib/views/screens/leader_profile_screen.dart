import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/mock_data.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';

/// Leader Profile Screen
/// Displays a leader's profile with Posts and Reels tabs
/// Uses Navigator.push for navigation
class LeaderProfileScreen extends StatefulWidget {
  final UserModel leader;

  const LeaderProfileScreen({
    super.key,
    required this.leader,
  });

  @override
  State<LeaderProfileScreen> createState() => _LeaderProfileScreenState();
}

class _LeaderProfileScreenState extends State<LeaderProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get posts for this leader (Posts tab)
  List<PostModel> _getLeaderPosts() {
    final allPosts = MockData.getMockPosts();
    // Filter posts by this leader, excluding video posts
    return allPosts
        .where((post) => post.author.id == widget.leader.id && post.videoUrl == null)
        .toList();
  }

  /// Get reels for this leader (Reels tab - video posts)
  List<PostModel> _getLeaderReels() {
    final allPosts = MockData.getMockPosts();
    // Filter posts by this leader, only video posts
    return allPosts
        .where((post) => post.author.id == widget.leader.id && post.videoUrl != null)
        .toList();
  }

  /// Build profile header section
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Profile image
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: widget.leader.profileImageUrl.isNotEmpty
                ? NetworkImage(widget.leader.profileImageUrl)
                : null,
            child: widget.leader.profileImageUrl.isEmpty
                ? Icon(
                    Icons.person,
                    color: Colors.grey[400],
                    size: 50,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Name with verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.leader.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (widget.leader.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Username
          Text(
            widget.leader.username,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // Bio/Description
          if (widget.leader.description != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.leader.description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else
            const SizedBox(height: 16),
          
          // Message button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle message action (no logic required)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message ${widget.leader.name}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build posts tab content
  Widget _buildPostsTab() {
    final posts = _getLeaderPosts();

    if (posts.isEmpty) {
      return Center(
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
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: posts[index],
          onComment: () {
            showCommentsBottomSheet(
              context,
              comments: MockData.getMockComments(),
              postTitle: '${widget.leader.name}\'s Post',
            );
          },
        );
      },
    );
  }

  /// Build reels tab content
  Widget _buildReelsTab() {
    final reels = _getLeaderReels();

    if (reels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No reels yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: reels.length,
      itemBuilder: (context, index) {
        return PostCard(
          post: reels[index],
          onComment: () {
            showCommentsBottomSheet(
              context,
              comments: MockData.getMockComments(),
              postTitle: '${widget.leader.name}\'s Reel',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.leader.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          tabs: const [
            Tab(
              text: 'Posts',
              icon: Icon(Icons.article_outlined),
            ),
            Tab(
              text: 'Reels',
              icon: Icon(Icons.video_library),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Profile header
          _buildProfileHeader(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildReelsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
