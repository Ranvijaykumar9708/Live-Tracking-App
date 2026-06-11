import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJson());
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }
    return null;
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    // Note: We might not want to remove user_data so they can log in again,
    // or we can remove it if we want to wipe everything on logout.
  }
}
