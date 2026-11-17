import '../../core/result/result.dart';
import '../models/app_user.dart';
import '../models/profile_photo_source.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<Result<AppUser?>> watchSession();
  Future<Result<AppUser?>> restoreSession();
  Future<Result<AppUser>> register(AuthCredentials credentials);
  Future<Result<AppUser>> login(AuthCredentials credentials);
  Future<Result<AppUser>> loginWithGoogle();

  /// Retorna null quando a seleção é cancelada ou não há foto a recuperar.
  Future<Result<AppUser?>> changeProfilePhoto(ProfilePhotoSource source);
  Future<Result<AppUser?>> recoverProfilePhoto();
  Future<Result<AppUser>> removeProfilePhoto();
  Future<Result<void>> logout();
}
