import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'profile_image_service.dart';

class ProfilePhotoStorageService {
  const ProfilePhotoStorageService(this._storage);
  final FirebaseStorage _storage;

  Future<String> upload(String uid, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > ProfileImageService.maxPhotoBytes) {
      throw StateError('A foto deve ter entre 1 byte e 5 MB.');
    }
    final random = Random.secure();
    final version = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final reference = _storage.ref('usuarios/$uid/perfil/$version.png');
    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/png',
        cacheControl: 'private,max-age=86400',
      ),
    );
    try {
      return await reference.getDownloadURL();
    } catch (_) {
      try {
        await reference.delete();
      } catch (_) {
        // A indisponibilidade do Storage não deve esconder o erro original.
      }
      rethrow;
    }
  }

  Future<void> delete(String uid, String? url) async {
    if (url == null) return;
    Reference reference;
    try {
      reference = _storage.refFromURL(url);
    } on ArgumentError {
      return; // Fotos do Google não pertencem ao bucket do aplicativo.
    } on FirebaseException catch (error) {
      if (error.code == 'invalid-url') return;
      rethrow;
    }
    if (reference.bucket != _storage.ref().bucket ||
        !RegExp(
          '^usuarios/${RegExp.escape(uid)}/perfil/[a-f0-9]{32}\\.png\$',
        ).hasMatch(reference.fullPath)) {
      return;
    }
    try {
      await reference.delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
