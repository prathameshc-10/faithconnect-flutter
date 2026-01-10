import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'create_content_screen.dart';

class LeaderDashboardScreen extends StatefulWidget {
  final UserModel leader;

  const LeaderDashboardScreen({
    super.key,
    required this.leader,
  });

  @override
  State<LeaderDashboardScreen> createState() => _LeaderDashboardScreenState();
}

class _LeaderDashboardScreenState extends State<LeaderDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _loadedLeader;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderData();
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
      if (!mounted) return;
      setState(() {
        _loadedLeader = widget.leader;
        _isLoading = false;
      });
    }
  }

  UserModel get _currentLeader => _loadedLeader ?? widget.leader;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      /// TOP HEADER
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.black12,
              backgroundImage: _currentLeader.profileImageUrl.isNotEmpty
                  ? NetworkImage(_currentLeader.profileImageUrl)
                  : null,
              child: _currentLeader.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FaithConnect Creator',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentLeader.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      /// BODY
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          /// GREETING
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Text(
              'Welcome back,\n${_currentLeader.name}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),

          /// QUICK ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _QuickActionCard(
                  title: 'Create Post',
                  subtitle: 'Share thoughts or verses',
                  icon: Icons.edit_square,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateContentScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _QuickActionCard(
                  title: 'Create Reel',
                  subtitle: 'Short video stories',
                  icon: Icons.movie,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateContentScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          /// RECENT ACTIVITY HEADER
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 36, 20, 12),
            child: Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          _ActivityTile(
            title: 'Sunday Morning Worship',
            subtitle: '2.4k views • 12m ago',
            icon: Icons.visibility,
          ),
          _divider(),
          _ActivityTile(
            title: 'Daily Devotional: Hope',
            subtitle: '842 Blessings • 4h ago',
            icon: Icons.favorite_border,
          ),
          _divider(),
          _ActivityTile(
            title: 'Community Prayer Night',
            subtitle: '156 Comments • 1d ago',
            icon: Icons.chat_bubble_outline,
          ),
        ],
      ),
    );
  }

  static Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1),
    );
  }
}

/// ACTIVITY TILE
class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
    );
  }
}

/// QUICK ACTION CARD
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
