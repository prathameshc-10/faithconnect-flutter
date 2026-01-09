import 'package:flutter/foundation.dart';
import 'user_role_provider.dart';

/// Global application state for authentication and role-based navigation.
///
/// This provider is the single source of truth for:
/// - Whether the user is authenticated
/// - Which role they are using the app as (worshiper or leader)
/// - Whether the leader has completed their profile setup flow
class AppStateProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  UserRole _userRole = UserRole.worshiper;
  bool _isLeaderProfileComplete = false;

  bool get isAuthenticated => _isAuthenticated;
  UserRole get userRole => _userRole;
  bool get isLeaderProfileComplete => _isLeaderProfileComplete;

  /// Mock sign-in that sets authentication status and role.
  void signIn({required UserRole role}) {
    _userRole = role;
    _isAuthenticated = true;

    // By default assume profile is not complete for leaders until setup.
    if (role == UserRole.leader) {
      _isLeaderProfileComplete = false;
    }

    notifyListeners();
  }

  /// Mock sign-up behaves like sign-in for this demo.
  void signUp({required UserRole role}) {
    signIn(role: role);
  }

  /// Mark the leader's profile as completed after setup.
  void completeLeaderProfile() {
    if (_userRole == UserRole.leader) {
      _isLeaderProfileComplete = true;
      notifyListeners();
    }
  }

  /// Sign out user and reset state.
  void signOut() {
    _isAuthenticated = false;
    _userRole = UserRole.worshiper;
    _isLeaderProfileComplete = false;
    notifyListeners();
  }
}

