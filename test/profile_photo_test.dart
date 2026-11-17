import 'dart:async';

import 'package:atividade_mobile/core/result/result.dart';
import 'package:atividade_mobile/data/repositories/auth_repository_impl.dart';
import 'package:atividade_mobile/data/services/auth_service.dart';
import 'package:atividade_mobile/data/services/firestore_service.dart';
import 'package:atividade_mobile/data/services/profile_image_service.dart';
import 'package:atividade_mobile/data/services/profile_photo_storage_service.dart';
import 'package:atividade_mobile/domain/models/app_user.dart';
import 'package:atividade_mobile/domain/models/profile_photo_source.dart';
import 'package:atividade_mobile/domain/use_cases/auth_use_cases.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_environment.dart';

const oldPhoto = 'https://example.com/previous.png';
const newPhoto = 'https://example.com/new.png';

class _AuthService implements AuthService {
  @override
  AppUser? currentUser = alice;
  @override
  Stream<AppUser?> watchSession() => Stream.value(currentUser);
  @override
  Future<AppUser?> restoreSession() async => currentUser;
  @override
  Future<AppUser> login(AuthCredentials input) async => currentUser!;
  @override
  Future<AppUser> register(AuthCredentials input) async => currentUser!;
  @override
  Future<AppUser> loginWithGoogle() async => currentUser!;
  @override
  Future<void> logout() async => currentUser = null;
}

class _Images implements ProfileImageService {
  Uint8List? bytes = Uint8List.fromList([1, 2, 3]);
  Object? error;
  Completer<Uint8List?>? pending;
  @override
  Future<Uint8List?> pick(ProfilePhotoSource source, String uid) async {
    if (error != null) throw error!;
    return pending == null ? bytes : await pending!.future;
  }

  @override
  Future<Uint8List?> recover(String uid) async => bytes;
}

class _Photos implements ProfilePhotoStorageService {
  final deleted = <String>[];
  int uploads = 0;
  Object? error;
  bool failCleanup = false;
  @override
  Future<String> upload(String uid, Uint8List bytes) async {
    uploads++;
    if (error != null) throw error!;
    return newPhoto;
  }

  @override
  Future<void> delete(String uid, String? url) async {
    if (url != null) deleted.add(url);
    if (failCleanup) throw StateError('Sem rede.');
  }
}

class _FailingFirestore extends FirestoreService {
  _FailingFirestore(super.firestore);
  @override
  Future<({AppUser user, String? previousPhoto})> updateUserPhoto(
    AppUser user,
    String? photo,
  ) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment environment;
  late _AuthService session;
  late _Images images;
  late _Photos photos;
  late AuthRepositoryImpl repository;
  setUp(() async {
    environment = TestEnvironment(user: alice);
    session = _AuthService();
    images = _Images();
    photos = _Photos();
    repository = AuthRepositoryImpl(
      session,
      environment.service,
      images,
      photos,
    );
    await environment.service.saveUser(alice.withPhoto(oldPhoto));
    await repository.restoreSession();
  });
  tearDown(() => environment.auth.close());

  test(
    'troca sincroniza conta e pessoa vinculada e preserva outros perfis',
    () async {
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      final other = await environment.createPerson('Ana', uid: 'alice');
      final result = await repository.changeProfilePhoto(
        ProfilePhotoSource.camera,
      );
      expect(result, isA<Success<AppUser?>>());
      expect(repository.currentUser?.foto, newPhoto);
      expect(
        (await environment.service.fetchStudentById(own.id))?.foto,
        newPhoto,
      );
      expect(
        (await environment.service.fetchStudentById(other.id))?.foto,
        isNull,
      );
      expect(photos.deleted, [oldPhoto]);
      expect(
        (await environment.firestore.doc('usuarios/alice').get())
            .data()?['foto'],
        newPhoto,
      );
      await repository.restoreSession();
      expect(repository.currentUser?.foto, newPhoto);
    },
  );

  test('perfil criado depois da troca já recebe a foto da conta', () async {
    await repository.changeProfilePhoto(ProfilePhotoSource.gallery);
    final own = await environment.createPerson(
      'Alice',
      uid: 'alice',
      usuarioUid: 'alice',
    );
    expect(own.foto, newPhoto);
    expect(own.toJson()['foto'], newPhoto);
    expect(
      (await environment.service.fetchStudentById(own.id))?.foto,
      newPhoto,
    );
  });

  test(
    'a pessoa vinculada recebe a foto mesmo quando cadastrada por outra conta',
    () async {
      final own = await environment.createPerson('Alice', uid: 'bob');
      await environment.firestore.doc('pessoas/${own.id}').update({
        'usuarioUid': 'alice',
      });
      await repository.changeProfilePhoto(ProfilePhotoSource.gallery);
      expect(
        (await environment.service.fetchStudentById(own.id))?.foto,
        newPhoto,
      );
      expect(
        (await environment.firestore.doc('pessoas/${own.id}').get())
            .data()?['criadoPor'],
        'bob',
      );
    },
  );

  test(
    'remover foto restaura iniciais e novo login Google preserva a remoção',
    () async {
      session.currentUser = const AppUser(
        uid: 'alice',
        email: 'alice@example.com',
        foto: oldPhoto,
        provider: 'google.com',
      );
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      expect((await repository.removeProfilePhoto()).isSuccess, isTrue);
      expect(
        (await environment.service.fetchStudentById(own.id))?.foto,
        isNull,
      );
      await repository.loginWithGoogle();
      expect(repository.currentUser?.foto, isNull);
      expect(photos.deleted, [oldPhoto]);
    },
  );

  test('login Google mantém a foto personalizada salva no Firestore', () async {
    await repository.changeProfilePhoto(ProfilePhotoSource.gallery);
    session.currentUser = const AppUser(
      uid: 'alice',
      email: 'alice@example.com',
      foto: oldPhoto,
      provider: 'google.com',
    );
    final result = await repository.loginWithGoogle();
    expect((result as Success<AppUser>).data.foto, newPhoto);
    expect(repository.currentUser?.foto, newPhoto);
  });

  test('cancelar seleção mantém foto e não envia arquivo', () async {
    images.bytes = null;
    final result = await repository.changeProfilePhoto(
      ProfilePhotoSource.gallery,
    );
    expect((result as Success<AppUser?>).data, isNull);
    expect(repository.currentUser?.foto, oldPhoto);
    expect(photos.uploads, 0);
    expect(photos.deleted, isEmpty);
  });

  test(
    'permissão negada mantém sessão e explica como autorizar a câmera',
    () async {
      images.error = PlatformException(code: 'camera_access_denied');
      final result = await repository.changeProfilePhoto(
        ProfilePhotoSource.camera,
      );
      expect((result as Failure).message, contains('configurações do celular'));
      expect(repository.currentUser?.uid, 'alice');
      expect(repository.currentUser?.foto, oldPhoto);
      expect(photos.uploads, 0);
    },
  );

  test('erro de upload mantém a foto anterior', () async {
    photos.error = FirebaseException(
      plugin: 'firebase_storage',
      code: 'unauthorized',
    );
    final result = await repository.changeProfilePhoto(
      ProfilePhotoSource.gallery,
    );
    expect((result as Failure).message, contains('Firebase Storage'));
    expect(repository.currentUser?.foto, oldPhoto);
    expect(photos.deleted, isEmpty);
    expect(
      (await environment.firestore.doc('usuarios/alice').get()).data()?['foto'],
      oldPhoto,
    );
  });

  test(
    'erro no Firestore remove só o novo arquivo e mantém a foto anterior',
    () async {
      final failing = AuthRepositoryImpl(
        session,
        _FailingFirestore(environment.firestore),
        images,
        photos,
      );
      await failing.restoreSession();
      expect(
        (await failing.changeProfilePhoto(
          ProfilePhotoSource.gallery,
        )).isFailure,
        isTrue,
      );
      expect(photos.deleted, [newPhoto]);
      expect(failing.currentUser?.foto, oldPhoto);
      expect(
        (await environment.firestore.doc('usuarios/alice').get())
            .data()?['foto'],
        oldPhoto,
      );
    },
  );

  test(
    'falha ao limpar foto antiga não invalida a nova foto confirmada',
    () async {
      photos.failCleanup = true;
      expect(
        (await repository.changeProfilePhoto(
          ProfilePhotoSource.gallery,
        )).isSuccess,
        isTrue,
      );
      expect(repository.currentUser?.foto, newPhoto);
    },
  );

  test(
    'troca de conta durante a seleção impede envio para a conta errada',
    () async {
      images.pending = Completer<Uint8List?>();
      final pending = repository.changeProfilePhoto(ProfilePhotoSource.gallery);
      session.currentUser = bob;
      images.pending!.complete(Uint8List.fromList([1, 2, 3]));
      expect((await pending).isFailure, isTrue);
      expect(photos.uploads, 0);
      expect(repository.currentUser?.uid, 'bob');
    },
  );

  test(
    'recuperação da seleção interrompida usa o mesmo fluxo de persistência',
    () async {
      expect((await repository.recoverProfilePhoto()).isSuccess, isTrue);
      expect(repository.currentUser?.foto, newPhoto);
      expect(photos.uploads, 1);
    },
  );

  test('casos de uso bloqueiam alteração e remoção sem sessão', () async {
    environment.auth.setUser(null);
    expect(
      (await ChangeProfilePhotoUseCase(environment.auth)(
        ProfilePhotoSource.gallery,
      )).isFailure,
      isTrue,
    );
    expect(
      (await RemoveProfilePhotoUseCase(environment.auth)()).isFailure,
      isTrue,
    );
    expect(environment.auth.photoCalls, 0);
  });
}
