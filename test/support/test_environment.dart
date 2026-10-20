import 'dart:async';
import 'package:atividade_mobile/app/app_viewmodels.dart';
import 'package:atividade_mobile/core/result/result.dart';
import 'package:atividade_mobile/data/repositories/evaluation_repository_impl.dart';
import 'package:atividade_mobile/data/repositories/student_repository_impl.dart';
import 'package:atividade_mobile/data/repositories/theme_repository_impl.dart';
import 'package:atividade_mobile/data/services/firestore_service.dart';
import 'package:atividade_mobile/data/services/theme_local_service.dart';
import 'package:atividade_mobile/domain/models/app_user.dart';
import 'package:atividade_mobile/domain/models/evaluation.dart';
import 'package:atividade_mobile/domain/models/popularity_score.dart';
import 'package:atividade_mobile/domain/models/student.dart';
import 'package:atividade_mobile/domain/repositories/auth_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAuthRepository implements AuthRepository {
  TestAuthRepository({AppUser? user}) : currentUser = user;
  final _changes = StreamController<Result<AppUser?>>.broadcast(sync: true);
  int loginCalls = 0;
  int registerCalls = 0;

  @override
  AppUser? currentUser;
  void setUser(AppUser? user) {
    currentUser = user;
    _changes.add(Success(user));
  }

  @override
  Stream<Result<AppUser?>> watchSession() async* {
    yield Success(currentUser);
    yield* _changes.stream;
  }

  @override
  Future<Result<AppUser?>> restoreSession() async => Success(currentUser);

  @override
  Future<Result<AppUser>> login(AuthCredentials input) async {
    loginCalls++;
    final user = AppUser(uid: 'alice', email: input.email.trim());
    setUser(user);
    return Success(user);
  }

  @override
  Future<Result<AppUser>> register(AuthCredentials input) async {
    registerCalls++;
    final user = AppUser(uid: 'alice', email: input.email.trim());
    setUser(user);
    return Success(user);
  }

  @override
  Future<Result<AppUser>> loginWithGoogle() async {
    const user = AppUser(
      uid: 'google-user',
      email: 'google@example.com',
      provider: 'google.com',
    );
    setUser(user);
    return const Success(user);
  }

  @override
  Future<Result<void>> logout() async {
    setUser(null);
    return const Success(null);
  }

  Future<void> close() => _changes.close();
}

class TestEnvironment {
  TestEnvironment({AppUser? user})
    : auth = TestAuthRepository(user: user),
      firestore = FakeFirebaseFirestore() {
    service = FirestoreService(firestore);
    people = StudentRepositoryImpl(service, auth);
    evaluations = EvaluationRepositoryImpl(service, auth);
  }

  final TestAuthRepository auth;
  final FakeFirebaseFirestore firestore;
  late final FirestoreService service;
  late final StudentRepositoryImpl people;
  late final EvaluationRepositoryImpl evaluations;

  Future<AppViewModels> models() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    return AppViewModels(
      authRepository: auth,
      studentRepository: people,
      evaluationRepository: evaluations,
      themeRepository: ThemeRepositoryImpl(ThemeLocalService(preferences)),
    );
  }

  Future<Student> createPerson(
    String name, {
    String uid = 'owner',
    String? usuarioUid,
  }) {
    return service.createStudent(
      Student(
        id: '',
        nome: name,
        apelido: name.toLowerCase(),
        curso: 'INFO',
        turmaAno: 2026,
        dataNascimento: DateTime(2005, 4, 2),
        usuarioUid: usuarioUid,
      ),
      uid,
    );
  }

  Future<Evaluation> rate(Student person, String uid, int stars) {
    final now = DateTime.now();
    return service.saveEvaluation(
      Evaluation(
        avaliadorUid: uid,
        pessoaId: person.id,
        notas: PopularityScore.initial(value: stars),
        dataAvaliacao: now,
        atualizadoEm: now,
      ),
    );
  }
}

const alice = AppUser(uid: 'alice', email: 'alice@example.com');
const bob = AppUser(uid: 'bob', email: 'bob@example.com');
