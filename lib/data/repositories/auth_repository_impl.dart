import '../../core/result/result.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../firebase_error_message.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._auth, this._firestore);
  final AuthService _auth;
  final FirestoreService _firestore;

  @override
  AppUser? get currentUser => _auth.currentUser;

  @override
  Stream<Result<AppUser?>> watchSession() =>
      _auth.watchSession().asyncMap(_persistSession);

  Future<Result<AppUser?>> _persistSession(AppUser? user) async {
    try {
      if (user != null) await _firestore.saveUser(user);
      return Success(currentUser?.uid == user?.uid ? user : currentUser);
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
      await _firestore.saveUser(user);
      return Success(user);
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
  Future<Result<void>> logout() async {
    try {
      await _auth.logout();
      return const Success(null);
    } catch (error) {
      return Failure(
        firebaseErrorMessage(error, 'Não foi possível sair.'),
        cause: error,
      );
    }
  }
}
