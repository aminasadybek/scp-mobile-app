import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';

class UserProvider with ChangeNotifier {
  // register user
  Future<bool> registerUser({required String name, required String email, required String password, String phone = '', String role = 'consumer', int companyId = 0, String? inviteCode}) async {
    _isLoading = true;
    notifyListeners();
    final success = await ApiService.registerUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      companyId: companyId,
    );
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // login user
  Future<bool> loginUser(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // first try main login
      final user = await ApiService.loginUser(email, password);
      if (user != null) {
        _currentUser = user;
        try {
          await _databaseHelper.saveUser(user.toJson());
        } catch (e) {
          // ignore save errors for now
        }
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      try {
        final result = await ApiService.login(email: email, password: password);
        if (result['user'] != null) {
          final userMap = result['user'] as Map<String, dynamic>;
          _currentUser = User.fromJson(userMap);
          try {
            await _databaseHelper.saveUser(userMap);
          } catch (_) {}
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (_) {
        // ignore fallback errors here, handle below
      }

      _errorMessage = 'Неверный email или пароль';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, st) {
      try {
        print('UserProvider.loginUser error: $e');
        print(st);
      } catch (_) {}
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  // try demo login
  Future<void> loginDemoUser() async {
    _isLoading = true;
    notifyListeners();

    final demoUser = User(
      id: -1,
      name: 'Mock Account',
      email: 'mock@example.com',
      password: '',
      phone: '',
      role: 'consumer',
      companyId: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = demoUser;
    await _databaseHelper.saveUser(demoUser.toJson());
    _isLoading = false;
    notifyListeners();
  }
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  final DatabaseHelper _databaseHelper = DatabaseHelper();



  // Load saved user from local database
  Future<void> loadSavedUser() async {
    try {
      final userData = await _databaseHelper.getUser();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved user: $e');
    }
  }

  // Register new consumer
  Future<bool> registerConsumer({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String companyName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.registerConsumer(
        name: name,
        email: email,
        password: password,
        phone: phone,
        companyName: companyName,
      );

      final user = User.fromJson(result['user']);
      _currentUser = user;

      // Сохраняем пользователя
      await _databaseHelper.saveUser(result['user']);

      _isLoading = false;
      notifyListeners();
      // update UI after current frame
      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.login(
        email: email,
        password: password,
      );

      final user = User.fromJson(result['user']);
      _currentUser = user;

      // save user
      await _databaseHelper.saveUser(result['user']);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
      await _databaseHelper.logoutUser();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // update user info
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}