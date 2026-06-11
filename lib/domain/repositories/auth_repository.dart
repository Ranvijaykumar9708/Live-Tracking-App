import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<bool> isLoggedIn();
  Future<UserModel?> getUser();
  Future<void> saveUser(UserModel user);
  Future<void> setLoggedIn(bool value);
  Future<void> clearSession();
}
