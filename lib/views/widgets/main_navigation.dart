import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../screens/home_feed_screen.dart';
import '../screens/religious_leaders_screen.dart';
import '../screens/reels_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/worshiper_profile_screen.dart';
import 'animated_bottom_nav_bar.dart';

/// Main Navigation Widget
///
/// - Provides a floating, animated bottom navigation bar.
/// - Uses [NavigationProvider] for tab state.
/// - Uses [UserRoleProvider] for role-based behavior on the 4th tab.
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    // Worshiper navigation only (leaders use LeaderMainNavigation).
    // Tabs: Home | Religious Leaders | Reels | Messages | Profile
    final screens = <Widget>[
      const HomeFeedScreen(),
      const ReligiousLeadersScreen(),
      const ReelsScreen(),
      const MessagesScreen(),
      const WorshiperProfileScreen(),
    ];

    final int safeIndex =
        navigationProvider.currentIndex.clamp(0, screens.length - 1);

    final items = const [
      BottomNavItemData(icon: Icons.home_outlined, label: 'Home'),
      BottomNavItemData(icon: Icons.people_alt_outlined, label: 'Leaders'),
      BottomNavItemData(icon: Icons.play_circle_outline, label: 'Reels'),
      BottomNavItemData(icon: Icons.chat_bubble_outline, label: 'Messages'),
      BottomNavItemData(icon: Icons.person_outline, label: 'Profile'),
    ];

    return Scaffold(
      // Allow content (e.g., Reels) to extend behind the floating bottom bar
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
