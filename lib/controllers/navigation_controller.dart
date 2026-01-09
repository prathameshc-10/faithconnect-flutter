import 'package:flutter/foundation.dart';

/// Navigation Controller - Legacy class (deprecated, use NavigationProvider instead)
/// Kept for backwards compatibility
@Deprecated('Use NavigationProvider instead')
class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    if (_currentIndex != index && index >= 0 && index < 5) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToHome() {
    setCurrentIndex(0);
  }
}
