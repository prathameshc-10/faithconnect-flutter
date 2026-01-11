import 'package:flutter/material.dart';
import '../../models/post_model.dart';

/// PostCard Widget
/// Reusable widget for displaying a post in the feed
/// Matches the reference screenshot layout
class PostCard extends StatelessWidget {
  final PostModel post;

  /// Optional callback for when user taps on the post
  final VoidCallback? onTap;

  /// Optional callback for like action
  final VoidCallback? onLike;

  /// Optional callback for comment action
  final VoidCallback? onComment;

  /// Optional callback for save action
  final VoidCallback? onSave;

  /// Optional callback for share action
  final VoidCallback? onShare;

  /// Whether the post is liked by the current user
  final bool isLiked;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onSave,
    this.onShare,
    this.isLiked = false,
  });

  /// Format number for display (e.g., 160000 -> 160K, 16000 -> 16K)
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format time ago (e.g., "1 hour ago", "2 hours ago")
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  /// Build the header row with avatar, name, and timestamp
  Widget _buildHeader() {
    return Row(
      children: [
        // Leader avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              post.author.profileImageUrl.isNotEmpty
                  ? NetworkImage(post.author.profileImageUrl)
                  : null,
          child:
              post.author.profileImageUrl.isEmpty
                  ? Icon(
                    Icons.person,
                    color:
                        post.author.isVerified ? Colors.blue : Colors.grey[600],
                    size: 20,
                  )
                  : null,
        ),
        const SizedBox(width: 12),
        // Leader name and timestamp
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.author.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.author.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatTimeAgo(post.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build optional image or video thumbnail
  Widget? _buildMedia() {
    // Video thumbnail
    if (post.videoUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Placeholder video thumbnail background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Play icon overlay
                Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Video title
          const Text(
            'Video Title Goes Here...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      );
    }

    // Image thumbnail
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            post.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
      );
    }

    return null;
  }

  /// Build action row with like, comment, save, and share icons
  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Like
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          count: formatNumber(post.likes),
          onTap: onLike,
          isHighlighted: isLiked,
        ),

        // Comment
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          count: formatNumber(post.comments),
          onTap: onComment,
        ),

        // Save
        _buildActionButton(
          icon: Icons.bookmark_border,
          onTap: onSave,
          isIconOnly: true,
        ),

        // Share
        _buildActionButton(icon: Icons.share, onTap: onShare, isIconOnly: true),
      ],
    );
  }

  /// Build individual action button (like, comment, save, share)
  Widget _buildActionButton({
    required IconData icon,
    String? count,
    VoidCallback? onTap,
    bool isIconOnly = false,
    bool isHighlighted = false,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted ? Colors.blue : Colors.grey[700],
          ),
          if (count != null && !isIconOnly) ...[
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                color: isHighlighted ? Colors.blue : Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );

    return button;
  }

  @override
  Widget build(BuildContext context) {
    final media = _buildMedia();

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Name + Timestamp
              _buildHeader(),
              const SizedBox(height: 12),

              // Optional media (video or image thumbnail)
              if (media != null) ...[media, const SizedBox(height: 12)],

              // Text content
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Action row: Like, Comment, Save, Share
              _buildActionRow(),
            ],
          ),
        ),
      ),
    );
  }
}
