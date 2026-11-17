import 'dart:ui' as ui;

import 'package:atividade_mobile/data/services/profile_image_service.dart';
import 'package:atividade_mobile/domain/models/profile_photo_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Picker extends ImagePicker {
  XFile? file;
  Object? error;
  ImageSource? selectedSource;
  bool? fullMetadata;
  CameraDevice? camera;
  LostDataResponse lost = LostDataResponse.empty();

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    selectedSource = source;
    camera = preferredCameraDevice;
    fullMetadata = requestFullMetadata;
    if (error != null) throw error!;
    return file;
  }

  @override
  Future<LostDataResponse> retrieveLostData() async => lost;
}

Future<XFile> _image({int width = 1600, int height = 800}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xff00aa55), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png');
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late _Picker picker;
  late ProfileImageService service;
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    picker = _Picker();
    service = ProfileImageService(picker, preferences);
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final source in ProfilePhotoSource.values) {
    test(
      'usa seletor nativo para ${source.name} e limita a imagem mantendo proporção',
      () async {
        picker.file = await _image();
        final bytes = await service.pick(source, 'alice');
        expect(
          picker.selectedSource,
          source == ProfilePhotoSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
        );
        expect(picker.camera, CameraDevice.front);
        expect(picker.fullMetadata, isFalse);
        expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 768);
        expect(frame.image.height, 384);
        frame.image.dispose();
        codec.dispose();
        expect(preferences.getKeys(), isEmpty);
      },
    );
  }

  test('não amplia uma imagem pequena', () async {
    picker.file = await _image(width: 40, height: 20);
    final bytes = await service.pick(ProfilePhotoSource.gallery, 'alice');
    final codec = await ui.instantiateImageCodec(bytes!);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 40);
    expect(frame.image.height, 20);
    frame.image.dispose();
    codec.dispose();
  });

  test(
    'cancelar seletor e negar permissão limpam marcador de recuperação',
    () async {
      expect(await service.pick(ProfilePhotoSource.gallery, 'alice'), isNull);
      expect(preferences.getKeys(), isEmpty);
      picker.error = PlatformException(code: 'camera_access_denied');
      await expectLater(
        service.pick(ProfilePhotoSource.camera, 'alice'),
        throwsA(isA<PlatformException>()),
      );
      expect(preferences.getKeys(), isEmpty);
    },
  );

  test('rejeita arquivo inválido ou maior que 20 MB antes do upload', () async {
    picker.file = XFile.fromData(Uint8List.fromList([1, 2, 3]));
    await expectLater(
      service.pick(ProfilePhotoSource.gallery, 'alice'),
      throwsA(isA<StateError>()),
    );
    picker.file = XFile.fromData(Uint8List(20 * 1024 * 1024 + 1));
    await expectLater(
      service.pick(ProfilePhotoSource.gallery, 'alice'),
      throwsA(isA<StateError>()),
    );
    expect(preferences.getKeys(), isEmpty);
  });

  test(
    'recupera foto interrompida apenas para a conta que iniciou a seleção',
    () async {
      await preferences.setString(
        'piramidgame_pending_profile_photo_uid',
        'alice',
      );
      picker.lost = LostDataResponse(
        files: [await _image(width: 80, height: 80)],
      );
      expect(await service.recover('alice'), isNotNull);
      expect(preferences.getKeys(), isEmpty);
      await preferences.setString(
        'piramidgame_pending_profile_photo_uid',
        'alice',
      );
      expect(await service.recover('bob'), isNull);
      expect(preferences.getKeys(), isEmpty);
      expect(await service.recover('alice'), isNull);
    },
  );

  test(
    'erro recuperado não permanece preso na próxima inicialização',
    () async {
      await preferences.setString(
        'piramidgame_pending_profile_photo_uid',
        'alice',
      );
      picker.lost = LostDataResponse(
        exception: PlatformException(code: 'camera_access_denied'),
      );
      await expectLater(
        service.recover('alice'),
        throwsA(isA<PlatformException>()),
      );
      expect(preferences.getKeys(), isEmpty);
      expect(await service.recover('alice'), isNull);
    },
  );
}
