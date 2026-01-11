import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../services/firestore_service.dart';
import '../screens/chat_screen.dart';

/// LeaderCard Widget
/// Reusable, minimal widget for displaying a religious leader
/// Mobile-first design with circular profile image, name, bio, and action button
class LeaderCard extends StatefulWidget {
  final UserModel leader;

  /// Whether to show "Message" (true) or "Follow" (false) button
  final bool showMessageButton;

  /// Callback when action button is tapped
  final VoidCallback? onAction;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  const LeaderCard({
    super.key,
    required this.leader,
    this.showMessageButton = false,
    this.onAction,
    this.onTap,
  });

  @override
  State<LeaderCard> createState() => _LeaderCardState();
}

class _LeaderCardState extends State<LeaderCard> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFollowing = false;
  bool _isCheckingFollow = true;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
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
    if (appState.userId == null || appState.userRole != UserRole.worshiper)
      return;

    setState(() {
      _isFollowing = true;
    });

    try {
      await _firestoreService.followLeader(
        worshiperId: appState.userId!,
        leaderId: widget.leader.id,
      );
      if (mounted && widget.onAction != null) {
        widget.onAction!();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleMessage() async {
    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) return;

    try {
      // Get or create conversation
      final conversationId = await _firestoreService.getOrCreateConversation(
        participant1Id: appState.userId!,
        participant2Id: widget.leader.id,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                conversationId: conversationId,
                title: widget.leader.name,
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final leader = widget.leader;

    final isOwnProfile = appState.userId == leader.id;
    final showActionButton =
        !isOwnProfile && appState.userRole == UserRole.worshiper;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Profile Image
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  leader.profileImageUrl.isNotEmpty
                      ? NetworkImage(leader.profileImageUrl)
                      : null,
              child:
                  leader.profileImageUrl.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[400], size: 32)
                      : null,
            ),

            const SizedBox(width: 12),

            /// Leader Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          leader.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (leader.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  if (leader.community != null || leader.role != null) ...[
                    Text(
                      [
                        leader.community,
                        leader.role,
                      ].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (leader.description != null)
                    Text(
                      leader.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            if (showActionButton) _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  /// Build action button (Follow or Message)
  Widget _buildActionButton(BuildContext context) {
    if (_isCheckingFollow) {
      return const SizedBox(
        height: 36,
        width: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.showMessageButton || _isFollowing) {
      // Show Message button if in My Leaders or already following
      return SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: _handleMessage,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Message',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      // Show Follow button
      return SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: _handleFollow,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Follow',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }
}
