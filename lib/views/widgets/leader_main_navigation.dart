import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../screens/leader_dashboard_screen.dart';
import '../screens/create_content_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/leader_profile_screen.dart';
import 'animated_bottom_nav_bar.dart';

/// Bottom navigation for religious leaders.
///
/// Tabs:
/// 0: Dashboard
/// 1: Create
/// 2: Messages
/// 3: Profile
class LeaderMainNavigation extends StatelessWidget {
  const LeaderMainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Create a LOCAL NavigationProvider for leader navigation
    // This is separate from the worshiper's NavigationProvider
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: const _LeaderMainNavigationScaffold(),
    );
  }
}

/// Internal scaffold widget that builds the actual navigation UI
class _LeaderMainNavigationScaffold extends StatefulWidget {
  const _LeaderMainNavigationScaffold({Key? key}) : super(key: key);

  @override
  State<_LeaderMainNavigationScaffold> createState() =>
      _LeaderMainNavigationScaffoldState();
}

class _LeaderMainNavigationScaffoldState
    extends State<_LeaderMainNavigationScaffold> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _currentLeader;

  @override
  void initState() {
    super.initState();
    _loadLeaderData();
  }

  Future<void> _loadLeaderData() async {
    final appState = context.read<AppStateProvider>();
    if (appState.userId == null) return;

    try {
      final leaderData =
          await _firestoreService.getLeaderData(appState.userId!);
      if (leaderData != null && mounted) {
        setState(() {
          _currentLeader = UserModel(
            id: appState.userId!,
            name: leaderData['name'] as String? ?? 'Leader',
            username:
                '@${(leaderData['name'] as String? ?? 'leader').toLowerCase().replaceAll(' ', '_')}',
            profileImageUrl: leaderData['profileImageUrl'] as String? ?? '',
            isVerified: false,
            description: leaderData['bio'] as String?,
            community: leaderData['community'] as String?,
            role: leaderData['role'] as String?,
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading leader data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final appState = context.watch<AppStateProvider>();

    // Create a placeholder leader model from current user data
    final leader = _currentLeader ??
        UserModel(
          id: appState.userId ?? '',
          name: 'Loading...',
          username: '@loading',
          profileImageUrl: '',
          isVerified: false,
        );

    final screens = <Widget>[
      LeaderDashboardScreen(leader: leader),
      const CreateContentScreen(),
      const MessagesScreen(),
      LeaderProfileScreen(leader: leader),
    ];

    final int safeIndex =
        navigationProvider.currentIndex.clamp(0, screens.length - 1);

    final items = const [
      BottomNavItemData(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      BottomNavItemData(icon: Icons.add_circle_outline, label: 'Create'),
      BottomNavItemData(icon: Icons.chat_bubble_outline, label: 'Messages'),
      BottomNavItemData(icon: Icons.person_outline, label: 'Profile'),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: safeIndex,
        onItemSelected: (index) => navigationProvider.setCurrentIndex(index),
        items: items,
      ),
    );
  }
}