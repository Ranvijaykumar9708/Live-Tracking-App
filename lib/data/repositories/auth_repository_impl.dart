import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalStorageService _storageService = LocalStorageService();

  @override
  Future<bool> isLoggedIn() {
    return _storageService.isLoggedIn();
  }

  @override
  Future<UserModel?> getUser() {
    return _storageService.getUser();
  }

  @override
  Future<void> saveUser(UserModel user) {
    return _storageService.saveUser(user);
  }

  @override
  Future<void> setLoggedIn(bool value) {
    return _storageService.setLoggedIn(value);
  }

  @override
  Future<void> clearSession() {
    return _storageService.clearSession();
  }
}
