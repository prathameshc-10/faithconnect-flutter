import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/posts_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_bottom_sheet.dart';

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

  /// IMAGE PICKER
  final ImagePicker _imagePicker = ImagePicker();
  File? _localProfileImage;

  UserModel? _loadedLeader;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderData();
    _loadPostsAndReels();
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

  /// IMAGE PICK
  Future<void> _pickProfileImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _localProfileImage = File(image.path);
    });

    // 🔥 NEXT STEP (optional)
    // Upload to Firebase Storage
    // Save download URL to Firestore
  }

  /// POSTS
  List<PostModel> _getLeaderPosts() {
    return context.read<PostsProvider>().postsForLeader(_currentLeader.id);
  }

  /// REELS
  List<PostModel> _getLeaderReels() {
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
            onTap: _pickProfileImage,
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

                /// CAMERA ICON
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

          /// LOGOUT
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () async {
                final appState = context.read<AppStateProvider>();
                await appState.signOut();
                if (!mounted) return;

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (_) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// POSTS TAB
  Widget _buildPostsTab() {
    final posts = _getLeaderPosts();
    if (posts.isEmpty) {
      return const Center(child: Text('No posts yet'));
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        onComment: () {
          showCommentsBottomSheet(
            context,
            comments: [],
            postTitle: '${_currentLeader.name}\'s Post',
          );
        },
      ),
    );
  }

  /// REELS TAB
  Widget _buildReelsTab() {
    final reels = _getLeaderReels();
    if (reels.isEmpty) {
      return const Center(child: Text('No reels yet'));
    }

    return ListView.builder(
      itemCount: reels.length,
      itemBuilder: (_, i) => PostCard(
        post: reels[i],
        onComment: () {
          showCommentsBottomSheet(
            context,
            comments: [],
            postTitle: '${_currentLeader.name}\'s Reel',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 50),
          _buildProfileHeader(),
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
