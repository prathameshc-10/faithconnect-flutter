import 'package:flutter/foundation.dart';

/// Navigation Provider for managing bottom navigation bar state
/// Uses Provider pattern for state management
class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  /// Current selected tab index
  /// 0: Home, 1: Create, 2: Reels, 3: Messages, 4: Notifications
  int get currentIndex => _currentIndex;

  /// Update the current navigation index
  void setCurrentIndex(int index) {
    if (_currentIndex != index && index >= 0 && index < 5) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Reset to home screen
  void goToHome() {
    setCurrentIndex(0);
  }
}
