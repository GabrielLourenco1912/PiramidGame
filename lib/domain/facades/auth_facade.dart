import '../../core/result/result.dart';
import '../models/app_user.dart';
import '../models/profile_photo_source.dart';
import '../use_cases/auth_use_cases.dart';

class AuthFacade {
  const AuthFacade({
    required this.registerUser,
    required this.loginUser,
    required this.loginGoogle,
    required this.restore,
    required this.watch,
    required this.signOut,
    required this.changePhoto,
    required this.recoverPhoto,
    required this.removePhoto,
  });

  final RegisterUserUseCase registerUser;
  final LoginUseCase loginUser;
  final LoginWithGoogleUseCase loginGoogle;
  final RestoreSessionUseCase restore;
  final WatchSessionUseCase watch;
  final LogoutUseCase signOut;
  final ChangeProfilePhotoUseCase changePhoto;
  final RecoverProfilePhotoUseCase recoverPhoto;
  final RemoveProfilePhotoUseCase removePhoto;

  Future<Result<AppUser>> register(AuthCredentials input) =>
      registerUser(input);
  Future<Result<AppUser>> login(AuthCredentials input) => loginUser(input);
  Future<Result<AppUser>> google() => loginGoogle();
  Future<Result<AppUser?>> current() => restore();
  Stream<Result<AppUser?>> session() => watch();
  Future<Result<void>> logout() => signOut();
  Future<Result<AppUser?>> changeProfilePhoto(ProfilePhotoSource source) =>
      changePhoto(source);
  Future<Result<AppUser?>> recoverProfilePhoto() => recoverPhoto();
  Future<Result<AppUser>> removeProfilePhoto() => removePhoto();
}
