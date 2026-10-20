import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core/command/command.dart';
import '../../core/result/result.dart';
import '../../domain/facades/auth_facade.dart';
import '../../domain/models/app_user.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._facade) {
    loginCommand = Command1(
      (AuthCredentials input) => _authenticate(() => _facade.login(input)),
    );
    registerCommand = Command1(
      (AuthCredentials input) => _authenticate(() => _facade.register(input)),
    );
    loginGoogleCommand = Command(() => _authenticate(_facade.google));
    restoreSessionCommand = Command(_restore);
    finishSplashCommand = Command(() async {
      if (!initialized.value) await _restore();
      splashFinished.value = true;
      notifyListeners();
      return const Success<void>(null);
    });
    logoutCommand = Command(() async {
      if (busy.value) return const Failure('Aguarde a ação atual terminar.');
      busy.value = true;
      try {
        final result = await _facade.logout();
        if (result.isSuccess) {
          user.value = null;
          errorMessage.value = null;
          notifyListeners();
        } else if (result case Failure(:final message)) {
          errorMessage.value = message;
        }
        return result;
      } finally {
        busy.value = false;
      }
    });
    _subscription = _facade.session().listen(
      _applySession,
      onError: (Object error) {
        _applySession(
          Failure('Não foi possível verificar a sessão.', cause: error),
        );
      },
    );
  }

  final AuthFacade _facade;
  late final StreamSubscription<Result<AppUser?>> _subscription;
  final user = signal<AppUser?>(null);
  final initialized = signal(false);
  final splashFinished = signal(false);
  final busy = signal(false);
  final errorMessage = signal<String?>(null);

  late final Command1<AuthCredentials, AppUser> loginCommand;
  late final Command1<AuthCredentials, AppUser> registerCommand;
  late final Command<AppUser> loginGoogleCommand;
  late final Command<AppUser?> restoreSessionCommand;
  late final Command<void> logoutCommand;
  late final Command<void> finishSplashCommand;

  bool get isAuthenticated => user.value != null;

  void _applySession(Result<AppUser?> result) {
    if (result case Success<AppUser?>(:final data)) {
      user.value = data;
      errorMessage.value = null;
    } else if (result case Failure(:final message)) {
      user.value = null;
      errorMessage.value = message;
    }
    initialized.value = true;
    notifyListeners();
  }

  Future<Result<AppUser?>> _restore() async {
    final result = await _facade.current();
    _applySession(result);
    return result;
  }

  Future<Result<AppUser>> _authenticate(
    Future<Result<AppUser>> Function() action,
  ) async {
    if (busy.value) return const Failure('Aguarde a ação atual terminar.');
    busy.value = true;
    errorMessage.value = null;
    try {
      final result = await action();
      if (result case Success<AppUser>(:final data)) {
        _applySession(Success(data));
      } else if (result case Failure(:final message)) {
        errorMessage.value = message;
      }
      return result;
    } finally {
      busy.value = false;
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
