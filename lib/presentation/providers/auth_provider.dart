import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepositoryImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> checkSession() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay
    bool isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      _currentUser = await _repository.getUser();
    }
    _setLoading(false);
    return isLoggedIn;
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String confirmPassword,
    String? imagePath,
  }) async {
    _setLoading(true);
    _setError(null);

    // Basic Validation
    if (name.isEmpty || email.isEmpty || mobile.isEmpty || password.isEmpty) {
      _setError("All fields are required.");
      _setLoading(false);
      return false;
    }
    if (password != confirmPassword) {
      _setError("Passwords do not match.");
      _setLoading(false);
      return false;
    }

    // Save User
    final user = UserModel(
      name: name,
      email: email,
      mobile: mobile,
      password: password,
      imagePath: imagePath,
    );

    await _repository.saveUser(user);
    // Auto login after signup
    await _repository.setLoggedIn(true);
    _currentUser = user;

    _setLoading(false);
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    if (email.isEmpty || password.isEmpty) {
      _setError("Email and password are required.");
      _setLoading(false);
      return false;
    }

    final storedUser = await _repository.getUser();
    
    if (storedUser != null) {
      if (storedUser.email == email && storedUser.password == password) {
        await _repository.setLoggedIn(true);
        _currentUser = storedUser;
        _setLoading(false);
        return true;
      } else {
        _setError("Invalid email or password.");
        _setLoading(false);
        return false;
      }
    } else {
      _setError("No user found. Please sign up.");
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String mobile,
    String? imagePath,
    String? homeAddress,
    String? workAddress,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _setError(null);

    if (name.isEmpty || email.isEmpty || mobile.isEmpty) {
      _setError("All fields are required.");
      _setLoading(false);
      return false;
    }

    final updatedUser = UserModel(
      name: name,
      email: email,
      mobile: mobile,
      password: _currentUser!.password, // keep old password
      imagePath: imagePath ?? _currentUser!.imagePath,
      homeAddress: homeAddress ?? _currentUser!.homeAddress,
      workAddress: workAddress ?? _currentUser!.workAddress,
    );

    await _repository.saveUser(updatedUser);
    _currentUser = updatedUser;
    
    _setLoading(false);
    return true;
  }

  Future<void> logout() async {
    await _repository.clearSession();
    _currentUser = null;
    notifyListeners();
  }
}
