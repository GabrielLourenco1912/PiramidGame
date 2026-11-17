import 'dart:typed_data';

import '../../core/result/result.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/profile_photo_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../firebase_error_message.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/profile_image_service.dart';
import '../services/profile_photo_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._firestore, this._images, this._photos);
  final AuthService _auth;
  final FirestoreService _firestore;
  final ProfileImageService _images;
  final ProfilePhotoStorageService _photos;
  AppUser? _profile;

  @override
  AppUser? get currentUser {
    final session = _auth.currentUser;
    return session?.uid == _profile?.uid ? _profile : session;
  }

  @override
  Stream<Result<AppUser?>> watchSession() =>
      _auth.watchSession().asyncMap(_persistSession);

  Future<Result<AppUser?>> _persistSession(AppUser? user) async {
    try {
      final profile = user == null ? null : await _firestore.saveUser(user);
      if (_auth.currentUser?.uid == user?.uid) _profile = profile;
      return Success(currentUser);
    } catch (error) {
      return Failure(
        firebaseErrorMessage(error, 'Não foi possível carregar sua conta.'),
        cause: error,
      );
    }
  }

  @override
  Future<Result<AppUser?>> restoreSession() async {
    try {
      return await _persistSession(await _auth.restoreSession());
    } catch (error) {
      return Failure(
        firebaseErrorMessage(error, 'Não foi possível restaurar a sessão.'),
        cause: error,
      );
    }
  }

  Future<Result<AppUser>> _authenticate(
    Future<AppUser> Function() action,
  ) async {
    try {
      final user = await action();
      final profile = await _firestore.saveUser(user);
      _ensureSession(user.uid);
      _profile = profile;
      return Success(profile);
    } catch (error) {
      return Failure(
        firebaseErrorMessage(error, 'Não foi possível acessar sua conta.'),
        cause: error,
      );
    }
  }

  @override
  Future<Result<AppUser>> register(AuthCredentials input) =>
      _authenticate(() => _auth.register(input));
  @override
  Future<Result<AppUser>> login(AuthCredentials input) =>
      _authenticate(() => _auth.login(input));
  @override
  Future<Result<AppUser>> loginWithGoogle() =>
      _authenticate(_auth.loginWithGoogle);

  @override
  Future<Result<AppUser?>> changeProfilePhoto(ProfilePhotoSource source) =>
      _changePhoto((uid) => _images.pick(source, uid));

  @override
  Future<Result<AppUser?>> recoverProfilePhoto() =>
      _changePhoto(_images.recover);

  Future<Result<AppUser?>> _changePhoto(
    Future<Uint8List?> Function(String uid) select,
  ) async {
    final user = currentUser;
    if (user == null) {
      return const Failure('Entre na sua conta para alterar a foto.');
    }
    String? uploadedUrl;
    var committed = false;
    try {
      final bytes = await select(user.uid);
      if (bytes == null) return const Success(null);
      _ensureSession(user.uid);
      uploadedUrl = await _photos.upload(user.uid, bytes);
      _ensureSession(user.uid);
      final saved = await _firestore.updateUserPhoto(user, uploadedUrl);
      committed = true;
      if (_auth.currentUser?.uid == user.uid) _profile = saved.user;
      await _deletePhotoQuietly(user.uid, saved.previousPhoto);
      _ensureSession(user.uid);
      return Success(saved.user);
    } catch (error) {
      if (!committed && uploadedUrl != null) {
        await _deletePhotoQuietly(user.uid, uploadedUrl);
      }
      return Failure(
        firebaseErrorMessage(
          error,
          'Não foi possível salvar sua foto. Tente novamente.',
        ),
        cause: error,
      );
    }
  }

  @override
  Future<Result<AppUser>> removeProfilePhoto() async {
    final user = currentUser;
    if (user == null) {
      return const Failure('Entre na sua conta para alterar a foto.');
    }
    try {
      final saved = await _firestore.updateUserPhoto(user, null);
      if (_auth.currentUser?.uid == user.uid) _profile = saved.user;
      await _deletePhotoQuietly(user.uid, saved.previousPhoto);
      _ensureSession(user.uid);
      return Success(saved.user);
    } catch (error) {
      return Failure(
        firebaseErrorMessage(
          error,
          'Não foi possível remover sua foto. Tente novamente.',
        ),
        cause: error,
      );
    }
  }

  void _ensureSession(String uid) {
    if (_auth.currentUser?.uid != uid) {
      throw StateError(
        'Sua sessão mudou. Entre novamente para alterar a foto.',
      );
    }
  }

  Future<void> _deletePhotoQuietly(String uid, String? url) async {
    try {
      await _photos.delete(uid, url);
    } catch (_) {
      // A foto confirmada no Firestore permanece válida se a limpeza falhar.
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _auth.logout();
      _profile = null;
      return const Success(null);
    } catch (error) {
      return Failure(
        firebaseErrorMessage(error, 'Não foi possível sair.'),
        cause: error,
      );
    }
  }
}
