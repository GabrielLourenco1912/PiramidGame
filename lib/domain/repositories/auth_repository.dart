import '../../core/result/result.dart';
import '../models/app_user.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<Result<AppUser?>> watchSession();
  Future<Result<AppUser?>> restoreSession();
  Future<Result<AppUser>> register(AuthCredentials credentials);
  Future<Result<AppUser>> login(AuthCredentials credentials);
  Future<Result<AppUser>> loginWithGoogle();
  Future<Result<void>> logout();
}
