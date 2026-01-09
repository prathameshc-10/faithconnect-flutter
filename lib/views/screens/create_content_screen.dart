import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/mock_data.dart';
import '../../providers/posts_provider.dart';

/// Screen for religious leaders to create new content.
///
/// Provides two primary actions:
/// - Create Post
/// - Create Reel
///
/// All created content is stored in [PostsProvider] so it appears
/// in worshiper feeds, followers feeds, and leader profiles.
class CreateContentScreen extends StatelessWidget {
  const CreateContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockLeader = MockData.getMockMyLeaders().first;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Create',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const SizedBox(height: 8),
          _CreateCard(
            icon: Icons.article_outlined,
            title: 'Create Post',
            subtitle: 'Text with image or video',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CreatePostScreen(author: mockLeader),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _CreateCard(
            icon: Icons.videocam_outlined,
            title: 'Create Reel',
            subtitle: 'Short vertical video',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _CreateReelScreen(author: mockLeader),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Reusable large action card widget for create options.
class _CreateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateCard({
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.blueAccent.shade400,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Create Post flow writing into [PostsProvider].
class _CreatePostScreen extends StatefulWidget {
  final dynamic author;

  const _CreatePostScreen({required this.author});

  @override
  State<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<_CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _publish() {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    context.read<PostsProvider>().addContent(
          author: widget.author,
          content: text,
          isReel: false,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post published')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _publish,
            child: const Text('Publish'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          controller: _contentController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Share a message with your community...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

/// Create Reel flow writing into [PostsProvider].
class _CreateReelScreen extends StatefulWidget {
  final dynamic author;

  const _CreateReelScreen({required this.author});

  @override
  State<_CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends State<_CreateReelScreen> {
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _publish() {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    context.read<PostsProvider>().addContent(
          author: widget.author,
          content: text,
          isReel: true,
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reel published')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reel'),
        actions: [
          TextButton(
            onPressed: _publish,
            child: const Text('Publish'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          controller: _contentController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Describe your short vertical video...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

