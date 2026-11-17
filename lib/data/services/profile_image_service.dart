import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/profile_photo_source.dart';

/// Usa a câmera e o seletor de fotos do sistema. Só a foto escolhida é lida.
class ProfileImageService {
  const ProfileImageService(this._picker, this._preferences);

  final ImagePicker _picker;
  final SharedPreferences _preferences;
  static const _pendingUidKey = 'piramidgame_pending_profile_photo_uid';
  static const maxPhotoBytes = 5 * 1024 * 1024;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<Uint8List?> pick(ProfilePhotoSource source, String uid) async {
    if (source == ProfilePhotoSource.camera &&
        !kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw StateError('Use um celular Android ou iOS para tirar uma foto.');
    }
    if (_isAndroid) await _preferences.setString(_pendingUidKey, uid);
    try {
      final file = await _picker.pickImage(
        source: source == ProfilePhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      return file == null ? null : await _prepare(file);
    } finally {
      if (_isAndroid) await _preferences.remove(_pendingUidKey);
    }
  }

  /// O Android pode encerrar o app enquanto a câmera/galeria está aberta.
  /// O marcador impede que a foto seja recuperada na conta de outra pessoa.
  Future<Uint8List?> recover(String uid) async {
    if (!_isAndroid) return null;
    final pendingUid = _preferences.getString(_pendingUidKey);
    try {
      final response = await _picker.retrieveLostData();
      if (pendingUid != uid || response.isEmpty) return null;
      if (response.exception != null) throw response.exception!;
      final files = response.files;
      return files == null || files.isEmpty
          ? null
          : await _prepare(files.first);
    } finally {
      await _preferences.remove(_pendingUidKey);
    }
  }

  Future<Uint8List> _prepare(XFile file) async {
    if (await file.length() > 20 * 1024 * 1024) {
      throw StateError('Escolha uma foto de até 20 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw StateError('A foto selecionada está vazia.');
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final scale = math.min(
        1.0,
        768 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      final frame = await codec.getNextFrame();
      try {
        // Reencodar remove metadados, como a localização EXIF, e padroniza o MIME.
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null || data.lengthInBytes > maxPhotoBytes) {
          throw StateError('Não foi possível preparar uma foto de até 5 MB.');
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } catch (error) {
      if (error is StateError) rethrow;
      throw StateError('Não foi possível ler esta imagem. Escolha outra foto.');
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
