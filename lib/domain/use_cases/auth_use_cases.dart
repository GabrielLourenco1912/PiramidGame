import '../../core/result/result.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

String? _validateCredentials(
  AuthCredentials input, {
  bool registration = false,
}) {
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input.email.trim())) {
    return 'Informe um e-mail válido.';
  }
  if (input.password.isEmpty) return 'Informe a senha.';
  if (registration && input.password.length < 6) {
    return 'A senha deve ter pelo menos 6 caracteres.';
  }
  return null;
}

class RegisterUserUseCase {
  const RegisterUserUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call(AuthCredentials input) {
    final error = _validateCredentials(input, registration: true);
    return error == null
        ? _repository.register(input)
        : Future.value(Failure(error));
  }
}

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<AppUser>> call(AuthCredentials input) {
    final error = _validateCredentials(input);
    return error == null
        ? _repository.login(input)
        : Future.value(Failure(error));
  }
}

class LoginWithGoogleUseCase {
  const LoginWithGoogleUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<AppUser>> call() => _repository.loginWithGoogle();
}

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<AppUser?>> call() => _repository.restoreSession();
}

class WatchSessionUseCase {
  const WatchSessionUseCase(this._repository);
  final AuthRepository _repository;
  Stream<Result<AppUser?>> call() => _repository.watchSession();
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);
  final AuthRepository _repository;
  Future<Result<void>> call() => _repository.logout();
}
