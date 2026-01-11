import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'user_role_provider.dart';

/// Global application state for authentication and role-based navigation.
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
  Future<void> initialize() async {
    debugPrint('🚀 AppStateProvider.initialize() called');
    final user = _authService.currentUser;
    if (user != null) {
      debugPrint('👤 Found existing user: ${user.uid}');
      await _loadUserData(user.uid);
    } else {
      debugPrint('❌ No existing user found');
    }
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    debugPrint('📥 Loading user data for UID: $uid');
    
    try {
      final userData = await _firestoreService.getUserData(uid);
      debugPrint('📄 User data received: $userData');
      
      if (userData != null) {
        _userId = uid;
        _isAuthenticated = true;
        
        final roleString = userData['role'] as String?;
        debugPrint('🎭 Role string from Firestore: "$roleString"');
        
        _userRole = roleString == 'worshiper' ? UserRole.worshiper : UserRole.leader;
        _community = userData['community'] as String?;

        debugPrint('✅ State updated:');
        debugPrint('   - _isAuthenticated: $_isAuthenticated');
        debugPrint('   - _userId: $_userId');
        debugPrint('   - _userRole: $_userRole');
        debugPrint('   - _community: $_community');

        // Load leader-specific data if user is a leader
        if (_userRole == UserRole.leader) {
          debugPrint('👔 User is a leader, loading leader data...');
          final leaderData = await _firestoreService.getLeaderData(uid);
          debugPrint('👔 Leader data: $leaderData');
          
          if (leaderData != null) {
            _isLeaderProfileComplete = leaderData['isProfileComplete'] as bool? ?? false;
            debugPrint('✅ Leader profile complete: $_isLeaderProfileComplete');
          }
        }

        debugPrint('🔔 Calling notifyListeners()...');
        notifyListeners();
        debugPrint('✅ notifyListeners() completed');
      } else {
        debugPrint('❌ User data is null - user document might not exist in Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
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
    debugPrint('📝 Sign up started for: $email, role: $role');
    
    try {
      // Create Firebase Auth user
      final user = await _authService.signUp(
        email: email,
        password: password,
      );
      debugPrint('✅ Firebase Auth user created: ${user.uid}');

      // Create user document in users collection
      await _firestoreService.createUser(
        uid: user.uid,
        name: name,
        email: email,
        role: role,
        community: community,
      );
      debugPrint('✅ User document created in Firestore');

      // Create role-specific document
      if (role == UserRole.worshiper) {
        await _firestoreService.createWorshiper(
          uid: user.uid,
          name: name,
          email: email,
          community: community,
        );
        debugPrint('✅ Worshiper document created');
      } else {
        await _firestoreService.createLeader(
          uid: user.uid,
          name: name,
          email: email,
          community: community,
        );
        debugPrint('✅ Leader document created');
      }

      // Update state
      _userId = user.uid;
      _isAuthenticated = true;
      _userRole = role;
      _community = community;
      _isLeaderProfileComplete = false;

      debugPrint('✅ Sign up complete, calling notifyListeners()');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🔑 Sign in started for: $email');
    
    try {
      // Authenticate with Firebase
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      debugPrint('✅ Firebase Auth sign in successful: ${user.uid}');

      // Load user data from Firestore
      await _loadUserData(user.uid);
      
      debugPrint('✅ Sign in process completed');
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Mark the leader's profile as completed after setup.
  Future<void> completeLeaderProfile() async {
    if (_userRole == UserRole.leader && _userId != null) {
      debugPrint('✅ Completing leader profile for: $_userId');
      
      _isLeaderProfileComplete = true;
      await _firestoreService.updateLeaderProfile(
        uid: _userId!,
        isProfileComplete: true,
      );
      
      debugPrint('🔔 Calling notifyListeners() after profile completion');
      notifyListeners();
    }
  }

  /// Sign out user and reset state.
  Future<void> signOut() async {
    debugPrint('👋 Sign out started');
    
    try {
      await _authService.signOut();
      _isAuthenticated = false;
      _userId = null;
      _userRole = null;
      _community = null;
      _isLeaderProfileComplete = false;
      
      debugPrint('🔔 Calling notifyListeners() after sign out');
      notifyListeners();
      debugPrint('✅ Sign out completed');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      rethrow;
    }
  }
}