import 'package:flutter/foundation.dart';

/// Leaders Provider for managing Religious Leaders screen tab selection
/// Uses Provider pattern for state management
class LeadersProvider with ChangeNotifier {
  int _selectedTab = 0; // 0: My Leaders, 1: Explore
  String _selectedSortBy = 'Trending'; // Trending, Near you, New
  String _searchQuery = '';

  /// Current selected tab (0: My Leaders, 1: Explore)
  int get selectedTab => _selectedTab;

  /// Check if My Leaders tab is selected
  bool get isMyLeadersSelected => _selectedTab == 0;

  /// Check if Explore tab is selected
  bool get isExploreSelected => _selectedTab == 1;

  /// Current sort by option
  String get selectedSortBy => _selectedSortBy;

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Update the selected tab
  void setSelectedTab(int index) {
    if (_selectedTab != index && index >= 0 && index < 2) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  /// Select My Leaders tab
  void selectMyLeaders() {
    setSelectedTab(0);
  }

  /// Select Explore tab
  void selectExplore() {
    setSelectedTab(1);
  }

  /// Set sort by option
  void setSortBy(String sortBy) {
    if (_selectedSortBy != sortBy) {
      _selectedSortBy = sortBy;
      notifyListeners();
    }
  }

  /// Set search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }
}
