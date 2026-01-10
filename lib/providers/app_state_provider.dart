import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'user_role_provider.dart';

/// Global application state for authentication and role-based navigation.
///
/// This provider is the single source of truth for:
/// - Whether the user is authenticated
/// - Which role they are using the app as (worshiper or leader)
/// - User ID and community
/// - Whether the leader has completed their profile setup flow
class AppStateProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isAuthenticated = false;
  String? _userId;
  UserRole? _userRole;
  String? _community;
  bool _isLeaderProfileComplete = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  UserRole? get userRole => _userRole;
  String? get community => _community;
  bool get isLeaderProfileComplete => _isLeaderProfileComplete;

  /// Initialize app state from Firebase Auth
  /// Call this on app start to check if user is already signed in
  Future<void> initialize() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _loadUserData(user.uid);
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _firestoreService.getUserData(uid);
      if (userData != null) {
        _userId = uid;
        _isAuthenticated = true;
        _userRole = userData['role'] == 'worshiper' ? UserRole.worshiper : UserRole.leader;
        _community = userData['community'] as String?;

        // Load leader-specific data if user is a leader
        if (_userRole == UserRole.leader) {
          final leaderData = await _firestoreService.getLeaderData(uid);
          if (leaderData != null) {
            _isLeaderProfileComplete = leaderData['isProfileComplete'] as bool? ?? false;
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Sign up with email, password, name, role, and community
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required String community,
  }) async {
    try {
      // Create Firebase Auth user
      final user = await _authService.signUp(
        email: email,
        password: password,
      );

      // Create user document in users collection
      await _firestoreService.createUser(
        uid: user.uid,
        name: name,
        email: email,
        role: role,
        community: community,
      );

      // Create role-specific document
      if (role == UserRole.worshiper) {
        await _firestoreService.createWorshiper(
          uid: user.uid,
          name: name,
          email: email,
          community: community,
        );
      } else {
        await _firestoreService.createLeader(
          uid: user.uid,
          name: name,
          email: email,
          community: community,
        );
      }

      // Update state
      _userId = user.uid;
      _isAuthenticated = true;
      _userRole = role;
      _community = community;
      _isLeaderProfileComplete = false;

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Firebase
      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      // Load user data from Firestore
      await _loadUserData(user.uid);
    } catch (e) {
      rethrow;
    }
  }

  /// Mark the leader's profile as completed after setup.
  Future<void> completeLeaderProfile() async {
    if (_userRole == UserRole.leader && _userId != null) {
      _isLeaderProfileComplete = true;
      await _firestoreService.updateLeaderProfile(
        uid: _userId!,
        isProfileComplete: true,
      );
      notifyListeners();
    }
  }

  /// Sign out user and reset state.
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _isAuthenticated = false;
      _userId = null;
      _userRole = null;
      _community = null;
      _isLeaderProfileComplete = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}

