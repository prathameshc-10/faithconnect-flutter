import 'package:flutter/foundation.dart';

/// Feed Provider for managing home feed tab selection (Explore/Following)
/// Uses Provider pattern for state management
class FeedProvider with ChangeNotifier {
  int _selectedTab = 0; // 0: Explore, 1: Following

  /// Current selected feed tab (0: Explore, 1: Following)
  int get selectedTab => _selectedTab;

  /// Check if Explore tab is selected
  bool get isExploreSelected => _selectedTab == 0;

  /// Check if Following tab is selected
  bool get isFollowingSelected => _selectedTab == 1;

  /// Update the selected feed tab
  void setSelectedTab(int index) {
    if (_selectedTab != index && index >= 0 && index < 2) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  /// Select Explore tab
  void selectExplore() {
    setSelectedTab(0);
  }

  /// Select Following tab
  void selectFollowing() {
    setSelectedTab(1);
  }
}
