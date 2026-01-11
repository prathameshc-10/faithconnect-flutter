import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/posts_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';
import 'chat_screen.dart';
import 'sign_in_screen.dart';

/// Leader Profile Screen
/// Displays leader profile with Posts & Reels tabs
/// Supports profile image picking + logout
class LeaderProfileScreen extends StatefulWidget {
  final UserModel leader;

  const LeaderProfileScreen({super.key, required this.leader});

  @override
  State<LeaderProfileScreen> createState() => _LeaderProfileScreenState();
}

class _LeaderProfileScreenState extends State<LeaderProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  /// IMAGE PICKER
  final ImagePicker _imagePicker = ImagePicker();
  File? _localProfileImage;

  UserModel? _loadedLeader;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isCheckingFollow = true;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfOwnProfile();
    _loadLeaderData();
    _loadPostsAndReels();
    _checkFollowingStatus();
  }

  void _checkIfOwnProfile() {
    final appState = context.read<AppStateProvider>();
    _isOwnProfile = appState.userId == widget.leader.id;
  }

  Future<void> _checkFollowingStatus() async {
    if (_isOwnProfile) {
      setState(() {
        _isCheckingFollow = false;
      });
      return;
    }

    final appState = context.read<AppStateProvider>();
    if (appState.userId == null || appState.userRole != UserRole.worshiper) {
      setState(() {
        _isCheckingFollow = false;
      });
      return;
    }

    try {
      final following = await _firestoreService.isFollowingLeader(
        worshiperId: appState.userId!,
        leaderId: widget.leader.id,
      );
      if (mounted) {
        setState(() {
          _isFollowing = following;
          _isCheckingFollow = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingFollow = false;
        });
      }
    }
  }

  Future<void> _handleFollow() async {
    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) return;

    setState(() {
      _isFollowing = true;
    });

    try {
      await _firestoreService.followLeader(
        worshiperId: appState.userId!,
        leaderId: widget.leader.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Following ${_currentLeader.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleUnfollow() async {
    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) return;

    setState(() {
      _isFollowing = false;
    });

    try {
      await _firestoreService.unfollowLeader(
        worshiperId: appState.userId!,
        leaderId: widget.leader.id,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleMessage() async {
    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) return;

    try {
      final conversationId = await _firestoreService.getOrCreateConversation(
        participant1Id: appState.userId!,
        participant2Id: widget.leader.id,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            title: _currentLeader.name,
            receiverId: widget.leader.id,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load posts & reels
  void _loadPostsAndReels() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<AppStateProvider>();
      if (appState.community != null) {
        final postsProvider = context.read<PostsProvider>();
        postsProvider.loadPosts(appState.community!);
        postsProvider.loadReels(appState.community!);
      }
    });
  }

  /// Load leader data from Firestore
  Future<void> _loadLeaderData() async {
    try {
      final leaderData =
          await _firestoreService.getLeaderData(widget.leader.id);

      if (!mounted) return;

      if (leaderData != null) {
        setState(() {
          _loadedLeader = UserModel(
            id: widget.leader.id,
            name: leaderData['name'] ?? widget.leader.name,
            username:
                '@${(leaderData['name'] ?? widget.leader.name).toLowerCase().replaceAll(' ', '_')}',
            profileImageUrl: leaderData['profileImageUrl'] ?? '',
            isVerified: false,
            description: leaderData['bio'],
            community: leaderData['community'],
            role: leaderData['role'],
          );
          _isLoading = false;
        });
      } else {
        _loadedLeader = widget.leader;
        _isLoading = false;
      }
    } catch (_) {
      _loadedLeader = widget.leader;
      _isLoading = false;
    }
  }

  UserModel get _currentLeader => _loadedLeader ?? widget.leader;

  /// IMAGE PICK (only for own profile)
  Future<void> _pickProfileImage() async {
    if (!_isOwnProfile) return;

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null || !mounted) return;

    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) return;

    setState(() {
      _localProfileImage = File(image.path);
    });

    try {
      // Upload to Firebase Storage
      final imageUrl = await _storageService.uploadProfileImage(
        userId: appState.userId!,
        imageFile: _localProfileImage!,
      );

      // Save to Firestore
      await _firestoreService.updateLeaderProfile(
        uid: appState.userId!,
        profileImageUrl: imageUrl,
      );

      if (mounted) {
        setState(() {
          _loadedLeader = _loadedLeader?.copyWith(profileImageUrl: imageUrl) ?? widget.leader;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localProfileImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  /// POSTS
  List<PostModel> _getLeaderPosts() {
    if (!mounted) return [];
    return context.read<PostsProvider>().postsForLeader(_currentLeader.id);
  }

  /// REELS
  List<PostModel> _getLeaderReels() {
    if (!mounted) return [];
    return context.read<PostsProvider>().reelsForLeader(_currentLeader.id);
  }

  /// PROFILE HEADER
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          /// PROFILE IMAGE
          GestureDetector(
            onTap: _isOwnProfile ? _pickProfileImage : null,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _localProfileImage != null
                      ? FileImage(_localProfileImage!)
                      : (_currentLeader.profileImageUrl.isNotEmpty
                          ? NetworkImage(_currentLeader.profileImageUrl)
                          : null) as ImageProvider?,
                  child: (_localProfileImage == null &&
                          _currentLeader.profileImageUrl.isEmpty)
                      ? Icon(Icons.person,
                          size: 56, color: Colors.grey.shade500)
                      : null,
                ),

                /// VERIFIED BADGE
                if (_currentLeader.isVerified)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.verified,
                        size: 18, color: Colors.white),
                  ),

                /// CAMERA ICON (only for own profile)
                if (_isOwnProfile)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// NAME
          Text(
            _currentLeader.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          /// USERNAME
          Text(
            _currentLeader.username,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 16),

          /// BIO
          if (_currentLeader.description != null &&
              _currentLeader.description!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                _currentLeader.description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),

          const SizedBox(height: 20),

          /// ACTION BUTTONS (Follow/Message for worshipers viewing other leaders)
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              if (_isOwnProfile || appState.userRole != UserRole.worshiper) {
                // Show logout only on own profile
                if (_isOwnProfile) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      onPressed: () async {
                        await appState.signOut();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                          (_) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              // Show Follow/Message buttons for worshipers
              return Row(
                children: [
                  if (_isCheckingFollow)
                    Expanded(
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isFollowing ? _handleUnfollow : _handleFollow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isFollowing ? 'Unfollow' : 'Follow',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isFollowing ? _handleMessage : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: const Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// POSTS TAB
  Widget _buildPostsTab() {
    final posts = _getLeaderPosts();
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
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
      itemBuilder: (_, i) {
        final post = posts[i];
        final postsProvider = context.read<PostsProvider>();
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
              postsProvider.fetchComments(post.id, isReel: false);
              showCommentsBottomSheet(
                context,
                postId: post.id,
                postTitle: '${_currentLeader.name}\'s Post',
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
    );
  }

  /// REELS TAB
  Widget _buildReelsTab() {
    final reels = _getLeaderReels();
    if (reels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
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
      itemBuilder: (_, i) {
        final reel = reels[i];
        final postsProvider = context.read<PostsProvider>();
        final appState = context.read<AppStateProvider>();
        final isLiked = postsProvider.isReelLiked(reel.id);
        
        return PostCard(
          post: reel,
          isLiked: isLiked,
          onLike: appState.userId != null
              ? () async {
                  try {
                    await postsProvider.toggleLike(reel, appState.userId!);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to like reel. Please try again.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              : null,
          onComment: () {
            if (appState.userId != null) {
              postsProvider.fetchComments(reel.id, isReel: true);
              showCommentsBottomSheet(
                context,
                postId: reel.id,
                postTitle: '${_currentLeader.name}\'s Reel',
                isReel: true,
              );
            }
          },
          onShare: () async {
            try {
              await postsProvider.share(reel);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to share reel. Please try again.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Reels'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
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
            ),
    );
  }
}
