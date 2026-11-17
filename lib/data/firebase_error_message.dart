import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

String firebaseErrorMessage(Object error, String fallback) {
  if (error is StateError) return error.message.toString();
  if (error is PlatformException) {
    return switch (error.code) {
      'camera_access_denied' || 'camera_access_restricted' =>
        'Acesso à câmera negado. Autorize a câmera nas configurações do celular e tente novamente.',
      'photo_access_denied' || 'photo_access_restricted' =>
        'Acesso às fotos negado. Autorize as fotos nas configurações do celular e tente novamente.',
      'no_available_camera' || 'camera_unavailable' =>
        'Não há uma câmera disponível. Escolha uma foto da galeria.',
      'already_active' =>
        'A câmera ou galeria já está aberta. Conclua a seleção atual.',
      _ => fallback,
    };
  }
  if (error is GoogleSignInException) {
    return error.code == GoogleSignInExceptionCode.canceled
        ? 'Login com Google cancelado.'
        : 'Não foi possível entrar com Google. Confira a configuração do aplicativo.';
  }
  if (error is FirebaseException) {
    if (error.plugin == 'firebase_storage') {
      return switch (error.code) {
        'unauthorized' =>
          'Sem permissão para salvar a foto. Confira as regras do Firebase Storage.',
        'unauthenticated' =>
          'Entre novamente na sua conta para alterar a foto.',
        'bucket-not-found' || 'project-not-found' || 'no-default-bucket' =>
          'O armazenamento de fotos ainda não foi configurado no Firebase.',
        'quota-exceeded' =>
          'O armazenamento de fotos está indisponível. Confira a cota e o plano do Firebase.',
        'retry-limit-exceeded' =>
          'O envio da foto demorou demais. Confira a conexão e tente novamente.',
        'canceled' => 'Envio da foto cancelado.',
        _ => fallback,
      };
    }
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
