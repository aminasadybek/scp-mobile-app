import 'package:flutter/foundation.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void navigateToCart() {
    _currentIndex = 2;
    notifyListeners();
  }

  void navigateToHome() {
    _currentIndex = 0;
    notifyListeners();
  }
}