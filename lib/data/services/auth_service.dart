import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/app_user.dart';

class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  AppUser? get currentUser => _mapUser(_auth.currentUser);
  Stream<AppUser?> watchSession() => _auth.authStateChanges().map(_mapUser);

  Future<AppUser?> restoreSession() async {
    return _mapUser(await _auth.authStateChanges().first);
  }

  Future<AppUser> register(AuthCredentials input) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: input.email.trim(),
      password: input.password,
    );
    return _mapUser(result.user)!;
  }

  Future<AppUser> login(AuthCredentials input) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: input.email.trim(),
      password: input.password,
    );
    return _mapUser(result.user)!;
  }

  Future<AppUser> loginWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      return _mapUser((await _auth.signInWithPopup(provider)).user)!;
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      throw StateError(
        'Use Android, iOS ou a versão web para entrar com Google.',
      );
    }
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    _googleInitialization ??= GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
      clientId: clientId.isEmpty ? null : clientId,
    );
    await _googleInitialization;
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw StateError('Não foi possível obter a conta Google.');
    }
    final credential = GoogleAuthProvider.credential(idToken: token);
    return _mapUser((await _auth.signInWithCredential(credential)).user)!;
  }

  Future<void> logout() async {
    await _auth.signOut();
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // A sessão válida pertence ao Firebase e já foi encerrada.
      }
    }
  }

  static AppUser? _mapUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      nome: user.displayName ?? '',
      foto: user.photoURL,
      provider:
          user.providerData.any(
            (provider) => provider.providerId == 'google.com',
          )
          ? 'google.com'
          : 'password',
    );
  }
}
