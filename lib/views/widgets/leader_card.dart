import 'package:flutter/material.dart';
import '../../models/user_model.dart';

/// LeaderCard Widget
/// Reusable, minimal widget for displaying a religious leader
/// Mobile-first design with circular profile image, name, bio, and action button
class LeaderCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            // Circular profile image
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey[200],
              backgroundImage: leader.profileImageUrl.isNotEmpty
                  ? NetworkImage(leader.profileImageUrl)
                  : null,
              child: leader.profileImageUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      color: Colors.grey[400],
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Leader info: Name, Community, Role, and Bio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Leader name with optional verification badge
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
                        Icon(
                          Icons.verified,
                          color: Colors.grey[700],
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Community and Role
                  if (leader.community != null || leader.role != null) ...[
                    Text(
                      [
                        leader.community,
                        leader.role,
                      ].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Short bio/description
                  if (leader.description != null) ...[
                    Text(
                      leader.description!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Action button: Follow or Message
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  /// Build action button (Follow or Message)
  Widget _buildActionButton(BuildContext context) {
    final buttonText = showMessageButton ? 'Message' : 'Follow';

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onAction,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
