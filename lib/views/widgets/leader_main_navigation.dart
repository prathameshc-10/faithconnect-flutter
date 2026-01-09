import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../screens/leader_dashboard_screen.dart';
import '../screens/create_content_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/leader_profile_screen.dart';
import 'animated_bottom_nav_bar.dart';
import '../../models/mock_data.dart';

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
    final navigationProvider = context.watch<NavigationProvider>();

    // For the profile tab we use the first mock leader as the "current" leader.
    final mockLeader = MockData.getMockMyLeaders().first;

    final screens = <Widget>[
      const LeaderDashboardScreen(),
      const CreateContentScreen(),
      const MessagesScreen(),
      LeaderProfileScreen(leader: mockLeader),
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

