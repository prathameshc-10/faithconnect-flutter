import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

/// Leaders Provider for managing Religious Leaders screen tab selection
/// Uses Provider pattern for state management
/// Fetches leaders from Firestore filtered by community
class LeadersProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _selectedTab = 0; // 0: My Leaders, 1: Explore
  String _selectedSortBy = 'Trending'; // Trending, Near you, New
  String _searchQuery = '';
  List<UserModel> _allLeaders = [];
  bool _isLoading = false;

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

  /// All leaders from Firestore
  List<UserModel> get allLeaders => List.unmodifiable(_allLeaders);

  /// Loading state
  bool get isLoading => _isLoading;

  /// Load leaders from Firestore filtered by community
  Future<void> loadLeaders(String community) async {
    if (community.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Get leaders stream and convert to list
      final stream = _firestoreService.getLeadersByCommunity(community);
      await for (final leadersData in stream) {
        _allLeaders = leadersData.map((data) {
          return UserModel(
            id: data['id'] as String? ?? data['uid'] as String? ?? '',
            name: data['name'] as String? ?? '',
            username: '@${(data['name'] as String? ?? '').toLowerCase().replaceAll(' ', '_')}',
            profileImageUrl: data['profileImageUrl'] as String? ?? '',
            isVerified: false, // Can be added to Firestore later
            description: data['bio'] as String?,
            community: data['community'] as String?,
            role: data['role'] as String?,
          );
        }).toList();
        _isLoading = false;
        notifyListeners();
        break; // Get first snapshot and break
      }
    } catch (e) {
      debugPrint('Error loading leaders: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

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
