import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/posts_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class CreateContentScreen extends StatelessWidget {
  const CreateContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final leaderId = appState.userId;
    
    if (leaderId == null || appState.userRole != UserRole.leader) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Only leaders can create content'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      /// TOP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Leader Content Hub',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      /// BODY
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            /// HEADLINE
            const Text(
              'What would you like to share?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose a format to engage your congregation and spread the Word.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            /// ACTION CARDS
            Expanded(
              child: ListView(
                children: [
                  _CreateVerticalCard(
                    icon: Icons.edit_note,
                    title: 'Create Post',
                    subtitle:
                        'Share a message, image, or video directly to the community feed.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CreatePostScreen(leaderId: leaderId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _CreateVerticalCard(
                    icon: Icons.movie_edit,
                    title: 'Create Reel',
                    subtitle:
                        'Engage worshipers with short inspirational video clips.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CreateReelScreen(leaderId: leaderId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _CreateVerticalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateVerticalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black),
              ),
              child: Icon(
                icon,
                size: 36,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Select',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _CreateReelScreen extends StatefulWidget {
  final String leaderId;

  const _CreateReelScreen({required this.leaderId});

  @override
  State<_CreateReelScreen> createState() => _CreateReelScreenState();
}


class _CreateReelScreenState extends State<_CreateReelScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  File? _videoFile;
  bool _isPublishing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );

    if (video == null) return;

    setState(() {
      _videoFile = File(video.path);
    });
  }

  Future<void> _publish() async {
    final caption = _captionController.text.trim();

    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video')),
      );
      return;
    }

    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final appState = context.read<AppStateProvider>();
      final community = appState.community;
      
      if (community == null) {
        throw Exception('Community not set');
      }

      // Upload video to Firebase Storage
      final videoUrl = await _storageService.uploadVideo(
        contentId: DateTime.now().millisecondsSinceEpoch.toString(),
        videoFile: _videoFile!,
        isReel: true,
      );

      // Save reel to Firestore
      await _firestoreService.createReel(
        authorId: widget.leaderId,
        content: caption,
        videoUrl: videoUrl,
        community: community,
      );

      // Refresh posts provider
      if (mounted) {
        await context.read<PostsProvider>().refresh(community);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel published successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publishing reel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Create Reel',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publish,
            child: _isPublishing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(color: Colors.black),
                  ),
          ),
        ],
      ),

      /// BODY
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// VIDEO PICKER
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Center(
                    child: _videoFile == null
                        ? const Icon(
                            Icons.videocam_outlined,
                            size: 48,
                            color: Colors.black54,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 40,
                                color: Colors.black,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _videoFile!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
        
              const SizedBox(height: 20),
        
              /// CAPTION
              const Text(
                'Caption',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write something inspiring...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
        
              const SizedBox(height: 12),
        
              /// INFO
              const Text(
                'Tap the box above to select a video (max 2 minutes).',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePostScreen extends StatefulWidget {
  final String leaderId;

  const _CreatePostScreen({required this.leaderId});

  @override
  State<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<_CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  File? _mediaFile;
  bool _isVideo = false;
  bool _isPublishing = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _mediaFile = File(image.path);
      _isVideo = false;
    });
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );

    if (video == null) return;

    setState(() {
      _mediaFile = File(video.path);
      _isVideo = true;
    });
  }

  Future<void> _publish() async {
    final text = _contentController.text.trim();

    if (text.isEmpty && _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text or media to publish')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final appState = context.read<AppStateProvider>();
      final community = appState.community;
      
      if (community == null) {
        throw Exception('Community not set');
      }

      String? imageUrl;
      String? videoUrl;

      // Upload media if present
      if (_mediaFile != null) {
        final postId = DateTime.now().millisecondsSinceEpoch.toString();
        if (_isVideo) {
          videoUrl = await _storageService.uploadVideo(
            contentId: postId,
            videoFile: _mediaFile!,
            isReel: false,
          );
        } else {
          imageUrl = await _storageService.uploadPostImage(
            postId: postId,
            imageFile: _mediaFile!,
          );
        }
      }

      // Save post to Firestore
      await _firestoreService.createPost(
        authorId: widget.leaderId,
        content: text.isEmpty ? 'Shared a post' : text,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        community: community,
      );

      // Refresh posts provider
      if (mounted) {
        await context.read<PostsProvider>().refresh(community);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error publishing post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publish,
            child: _isPublishing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),

      /// BODY
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// MEDIA ACTIONS
            Row(
              children: [
                _MediaButton(
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  onTap: _pickImage,
                ),
                const SizedBox(width: 12),
                _MediaButton(
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  onTap: _pickVideo,
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// MEDIA PREVIEW
            if (_mediaFile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                  color: Colors.grey.shade200,
                ),
                child: _isVideo
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            _mediaFile!.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _mediaFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),

            /// TEXT INPUT
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText:
                      'Share a message, verse, or reflection with your community...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'You can post text, images, videos, or a combination.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

