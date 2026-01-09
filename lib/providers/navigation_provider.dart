import 'package:flutter/foundation.dart';

/// Navigation Provider for managing bottom navigation bar state.
///
/// Index mapping is interpreted by each navigation shell:
/// - Worshiper main nav uses 5 tabs (0‑4)
/// - Leader main nav uses 4 tabs  (0‑3)
class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  /// Current selected tab index.
  int get currentIndex => _currentIndex;

  /// Update the current navigation index.
  void setCurrentIndex(int index) {
    // Guard against negative indices; upper bound is enforced by each shell.
    if (_currentIndex != index && index >= 0) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Reset to home screen.
  void goToHome() {
    setCurrentIndex(0);
  }
}
