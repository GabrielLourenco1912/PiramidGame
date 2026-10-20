import 'package:atividade_mobile/core/result/result.dart';
import 'package:atividade_mobile/data/services/firestore_service.dart';
import 'package:atividade_mobile/data/services/theme_local_service.dart';
import 'package:atividade_mobile/domain/models/app_user.dart';
import 'package:atividade_mobile/domain/models/evaluation.dart';
import 'package:atividade_mobile/domain/models/popularity_score.dart';
import 'package:atividade_mobile/domain/models/ranking_entry.dart';
import 'package:atividade_mobile/domain/models/theme_preference.dart';
import 'package:atividade_mobile/domain/use_cases/auth_use_cases.dart';
import 'package:atividade_mobile/domain/use_cases/evaluation_use_cases.dart';
import 'package:atividade_mobile/domain/use_cases/ranking_use_cases.dart';
import 'package:atividade_mobile/domain/use_cases/student_validation.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:shared_preferences/shared_preferences.dart';
import 'support/test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnvironment environment;
  setUp(() => environment = TestEnvironment(user: alice));
  tearDown(() => environment.auth.close());

  test('valida credenciais antes de chamar o repositório', () async {
    final login = LoginUseCase(environment.auth);
    final register = RegisterUserUseCase(environment.auth);
    expect(
      (await login(
        const AuthCredentials(email: 'invalido', password: '123456'),
      )).isFailure,
      isTrue,
    );
    expect(
      (await register(
        const AuthCredentials(email: 'a@b.com', password: '123'),
      )).isFailure,
      isTrue,
    );
    expect(environment.auth.loginCalls, 0);
    expect(environment.auth.registerCalls, 0);
    expect(
      (await register(
        const AuthCredentials(email: 'a@b.com', password: '123456'),
      )).isSuccess,
      isTrue,
    );
  });

  test(
    'preserva notas inválidas para rejeição em vez de corrigi-las silenciosamente',
    () {
      expect(PopularityScore.initial().total, 15);
      expect(PopularityScore.initial(value: 5).total, 75);
      expect(PopularityScore.initial(value: 0).isComplete, isFalse);
      expect(PopularityScore.initial(value: 6).isComplete, isFalse);
      expect(PopularityScore({}).isComplete, isFalse);
      expect(
        PopularityScore({
          ...PopularityScore.initial().values,
          'extra': 3,
        }).isComplete,
        isFalse,
      );
      expect(
        () => PopularityScore.fromJson({'resenha': 3.5}),
        throwsFormatException,
      );
    },
  );

  test(
    'valida curso, turma, nome e nascimento sem exigir avaliação no cadastro',
    () async {
      final person = await environment.createPerson('Ana');
      expect(StudentValidation.validate(person), isNull);
      expect(
        StudentValidation.validate(person.copyWith(curso: 'Outro')),
        isNotNull,
      );
      expect(
        StudentValidation.validate(person.copyWith(turmaAno: 2027)),
        isNotNull,
      );
      expect(StudentValidation.validate(person.copyWith(nome: ' ')), isNotNull);
      expect(
        StudentValidation.validate(
          person.copyWith(dataNascimento: DateTime(2100)),
        ),
        isNotNull,
      );
      final document =
          (await environment.firestore
                  .collection('pessoas')
                  .doc(person.id)
                  .get())
              .data()!;
      expect(document.containsKey('scores'), isFalse);
      expect(document.containsKey('notas'), isFalse);
      expect(document['criadoPor'], 'owner');
    },
  );

  test(
    'impede avaliação sem sessão, de si próprio e com critérios inválidos',
    () async {
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      final other = await environment.createPerson('Ana');
      final save = SaveEvaluationUseCase(
        environment.evaluations,
        environment.people,
        environment.auth,
      );
      expect(
        (await save(
          EvaluationInput(pessoaId: own.id, notas: PopularityScore.initial()),
        )).isFailure,
        isTrue,
      );
      expect(
        (await save(
          EvaluationInput(
            pessoaId: other.id,
            notas: PopularityScore.initial(value: 0),
          ),
        )).isFailure,
        isTrue,
      );
      environment.auth.setUser(null);
      expect(
        (await save(
          EvaluationInput(pessoaId: other.id, notas: PopularityScore.initial()),
        )).isFailure,
        isTrue,
      );
      expect(
        (await environment.firestore.collection('avaliacoes').get()).docs,
        isEmpty,
      );
    },
  );

  test('uma conta só pode ser vinculada a uma pessoa', () async {
    final own = await environment.createPerson(
      'Alice',
      uid: 'alice',
      usuarioUid: 'alice',
    );
    final result = await environment.people.createStudent(
      own.copyWith(id: '', nome: 'Outro perfil'),
    );
    expect(result, isA<Failure>());
    expect(
      (result as Failure).message,
      'Sua conta já está vinculada a uma pessoa.',
    );
    expect(
      (await environment.firestore.collection('pessoas').get()).docs,
      hasLength(1),
    );
    final link = await environment.firestore
        .collection('vinculosUsuarios')
        .doc('alice')
        .get();
    expect(link.data(), {'pessoaId': own.id});
  });

  test(
    'contas distintas têm perfis próprios e podem cadastrar terceiros',
    () async {
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      await environment.createPerson('Ana', uid: 'alice');
      await environment.createPerson('Bruno', uid: 'alice');
      await environment.createPerson('Bob', uid: 'bob', usuarioUid: 'bob');
      expect(
        (await environment.firestore.collection('pessoas').get()).docs,
        hasLength(4),
      );
      expect(
        (await environment.firestore.collection('vinculosUsuarios').get()).docs,
        hasLength(2),
      );
      await expectLater(
        environment.service.createStudent(own.copyWith(id: ''), 'bob'),
        throwsStateError,
      );
    },
  );

  test(
    'remoção lógica preserva o vínculo e impede um segundo perfil',
    () async {
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      expect(
        (await environment.people.deleteStudent(own.id)).isSuccess,
        isTrue,
      );
      expect(
        (await environment.people.createStudent(
          own.copyWith(id: ''),
        )).isFailure,
        isTrue,
      );
      expect(
        (await environment.firestore.collection('vinculosUsuarios').get()).docs,
        hasLength(1),
      );
      expect(
        (await environment.firestore.collection('pessoas').get()).docs,
        hasLength(1),
      );
    },
  );

  for (final active in [true, false]) {
    test('bloqueia vínculo legado sem índice, com ativo=$active', () async {
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      // Simula dados anteriores à criação da coleção de vínculos.
      await environment.firestore
          .collection('vinculosUsuarios')
          .doc('alice')
          .delete();
      await environment.firestore.collection('pessoas').doc(own.id).update({
        'ativo': active,
      });
      final result = await environment.people.createStudent(
        own.copyWith(id: ''),
      );
      expect(result, isA<Failure>());
      expect(
        (result as Failure).message,
        'Sua conta já está vinculada a uma pessoa.',
      );
      expect(
        (await environment.firestore.collection('pessoas').get()).docs,
        hasLength(1),
      );
    });
  }

  test(
    'o serviço também bloqueia autoavaliação quando o caso de uso é contornado',
    () async {
      final own = await environment.createPerson(
        'Alice',
        uid: 'alice',
        usuarioUid: 'alice',
      );
      await expectLater(environment.rate(own, 'alice', 5), throwsStateError);
    },
  );

  test(
    'alterar opinião mantém uma avaliação por usuário/pessoa e a data original',
    () async {
      final person = await environment.createPerson('Ana');
      final original = await environment.rate(person, 'alice', 3);
      final edited = await environment.rate(person, 'alice', 5);
      await environment.rate(person, 'bob', 4);
      final mine =
          (await environment.evaluations.byUser('alice')
                  as Success<List<Evaluation>>)
              .data;
      expect(mine, hasLength(1));
      expect(mine.single.pontuacaoTotal, 75);
      expect(edited.id, original.id);
      expect(edited.dataAvaliacao, original.dataAvaliacao);
      expect(
        (await environment.firestore.collection('avaliacoes').get()).docs,
        hasLength(2),
      );
      final otherDevice = FirestoreService(environment.firestore);
      expect(
        (await otherDevice.fetchEvaluation('alice', person.id))!.pontuacaoTotal,
        75,
      );
    },
  );

  test(
    'ranking pessoal isola contas; global usa a média e conta usuários distintos',
    () async {
      final ana = await environment.createPerson('Ana');
      final bruno = await environment.createPerson('Bruno');
      await environment.createPerson('Sem avaliação');
      await environment.rate(ana, 'alice', 4); // 60
      await environment.rate(ana, 'bob', 5); // 75
      await environment.rate(bruno, 'alice', 5); // 75
      await environment.rate(bruno, 'bob', 1); // 15
      final personal = CalculatePersonalRankingUseCase(
        environment.people,
        environment.evaluations,
        environment.auth,
      );
      final global = CalculateGlobalRankingUseCase(
        environment.people,
        environment.evaluations,
        environment.auth,
      );
      final myEntries = (await personal() as Success<List<RankingEntry>>).data;
      expect(myEntries.map((entry) => entry.pessoa.nome), ['Bruno', 'Ana']);
      expect(myEntries.map((entry) => entry.pontuacao), [75, 60]);
      final globalEntries =
          (await global() as Success<List<RankingEntry>>).data;
      expect(globalEntries.map((entry) => entry.pessoa.nome), ['Ana', 'Bruno']);
      expect(globalEntries.map((entry) => entry.pontuacao), [67.5, 45]);
      expect(globalEntries.first.quantidadeAvaliacoes, 2);
      expect(globalEntries.first.formattedScore, '67,5');
      environment.auth.setUser(bob);
      final bobsEntries =
          (await personal() as Success<List<RankingEntry>>).data;
      expect(bobsEntries.map((entry) => entry.pontuacao), [75, 15]);
      await environment.rate(ana, 'alice', 2);
      final updated = (await global() as Success<List<RankingEntry>>).data;
      expect(updated.first.pontuacao, 52.5);
      expect(updated.first.quantidadeAvaliacoes, 2);
    },
  );

  test(
    'somente criador edita/remove; remoção preserva histórico e exclui do ranking',
    () async {
      final person = await environment.createPerson('Ana', uid: 'alice');
      await environment.rate(person, 'bob', 5);
      environment.auth.setUser(bob);
      expect(
        (await environment.people.updateStudent(
          person.copyWith(nome: 'Outro'),
        )).isFailure,
        isTrue,
      );
      expect(
        (await environment.people.deleteStudent(person.id)).isFailure,
        isTrue,
      );
      environment.auth.setUser(alice);
      expect(
        (await environment.people.updateStudent(
          person.copyWith(nome: 'Ana Lima'),
        )).isSuccess,
        isTrue,
      );
      expect(
        (await environment.people.deleteStudent(person.id)).isSuccess,
        isTrue,
      );
      expect((await environment.people.getStudents() as Success).data, isEmpty);
      final global = CalculateGlobalRankingUseCase(
        environment.people,
        environment.evaluations,
        environment.auth,
      );
      expect((await global() as Success).data, isEmpty);
      expect(
        (await environment.firestore.collection('avaliacoes').get()).docs,
        hasLength(1),
      );
      await expectLater(environment.rate(person, 'bob', 5), throwsStateError);
    },
  );

  test(
    'vínculo realizado pelo administrador bloqueia autoavaliação de cadastro existente',
    () async {
      final person = await environment.createPerson('Alice');
      await environment.firestore.collection('pessoas').doc(person.id).update({
        'usuarioUid': 'alice',
      });
      final save = SaveEvaluationUseCase(
        environment.evaluations,
        environment.people,
        environment.auth,
      );
      expect(
        (await save(
          EvaluationInput(
            pessoaId: person.id,
            notas: PopularityScore.initial(value: 5),
          ),
        )).isFailure,
        isTrue,
      );
    },
  );

  test(
    'empates usam ordem alfabética e pessoas sem avaliação ficam fora',
    () async {
      final z = await environment.createPerson('Zoe');
      final a = await environment.createPerson('Ana');
      await environment.rate(z, 'alice', 4);
      await environment.rate(a, 'alice', 4);
      final global = CalculateGlobalRankingUseCase(
        environment.people,
        environment.evaluations,
        environment.auth,
      );
      expect(
        (await global() as Success<List<RankingEntry>>).data.map(
          (entry) => entry.pessoa.nome,
        ),
        ['Ana', 'Zoe'],
      );
    },
  );

  test(
    'SharedPreferences salva somente tema; dados principais ficam no Firestore',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = ThemeLocalService(preferences);
      expect(await service.fetchThemePreference(), AppThemePreference.light);
      await service.saveThemePreference(AppThemePreference.dark);
      expect(
        await ThemeLocalService(preferences).fetchThemePreference(),
        AppThemePreference.dark,
      );
      expect(preferences.getKeys(), {'piramidgame_theme_mode'});
    },
  );
}
