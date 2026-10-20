import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

String firebaseErrorMessage(Object error, String fallback) {
  if (error is StateError) return error.message.toString();
  if (error is GoogleSignInException) {
    return error.code == GoogleSignInExceptionCode.canceled
        ? 'Login com Google cancelado.'
        : 'Não foi possível entrar com Google. Confira a configuração do aplicativo.';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'E-mail ou senha incorretos.',
      'email-already-in-use' => 'Este e-mail já possui uma conta.',
      'invalid-email' => 'Informe um e-mail válido.',
      'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
      'user-disabled' => 'Esta conta foi desativada.',
      'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
      'network-request-failed' ||
      'unavailable' => 'Confira sua conexão e tente novamente.',
      'permission-denied' =>
        'Acesso negado. Confira sua sessão e as regras do Firestore.',
      'operation-not-allowed' =>
        'Ative este método de login no Firebase Authentication.',
      'popup-closed-by-user' ||
      'cancelled-popup-request' => 'Login com Google cancelado.',
      'unauthorized-domain' =>
        'Adicione este domínio aos domínios autorizados do Firebase.',
      _ => fallback,
    };
  }
  return fallback;
}
