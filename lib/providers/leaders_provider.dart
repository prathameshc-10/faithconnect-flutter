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
  List<String> _followedLeaderIds = [];
  bool _isLoading = false;
  String? _currentCommunity;
  String? _currentUserId;

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

  /// All leaders from Firestore (filtered by tab)
  List<UserModel> get allLeaders {
    if (isMyLeadersSelected) {
      // Return only followed leaders
      return _allLeaders.where((leader) => _followedLeaderIds.contains(leader.id)).toList();
    } else {
      // Return all leaders in community
      return List.unmodifiable(_allLeaders);
    }
  }

  /// Loading state
  bool get isLoading => _isLoading;

  /// Load leaders from Firestore filtered by community
  Future<void> loadLeaders(String community, String? userId) async {
    if (community.isEmpty) return;
    if (_currentCommunity == community && _currentUserId == userId && _allLeaders.isNotEmpty) {
      // Already loaded, just update followed list if userId changed
      if (userId != null && userId != _currentUserId) {
        await _loadFollowedLeaders(userId);
      }
      return;
    }

    _currentCommunity = community;
    _currentUserId = userId;
    _isLoading = true;
    _allLeaders = [];
    notifyListeners();

    // Load followed leaders if user is a worshiper
    if (userId != null) {
      await _loadFollowedLeaders(userId);
    }

    try {
      // Listen to leaders stream
      _firestoreService.getLeadersByCommunity(community).listen(
        (leadersData) {
          _allLeaders = leadersData.map((data) {
            return UserModel(
              id: data['id'] as String? ?? data['uid'] as String? ?? '',
              name: data['name'] as String? ?? '',
              username: '@${(data['name'] as String? ?? '').toLowerCase().replaceAll(' ', '_')}',
              profileImageUrl: data['profileImageUrl'] as String? ?? '',
              isVerified: false,
              description: data['bio'] as String?,
              community: data['community'] as String?,
              role: data['role'] as String?,
            );
          }).toList();
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error loading leaders: $error');
          _isLoading = false;
          _allLeaders = [];
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading leaders: $e');
      _isLoading = false;
      _allLeaders = [];
      notifyListeners();
    }
  }

  Future<void> _loadFollowedLeaders(String userId) async {
    try {
      _followedLeaderIds = await _firestoreService.getFollowedLeaders(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading followed leaders: $e');
    }
  }

  /// Refresh leaders list
  Future<void> refresh(String community, String? userId) async {
    _allLeaders = [];
    _followedLeaderIds = [];
    _currentCommunity = null;
    _currentUserId = null;
    await loadLeaders(community, userId);
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
