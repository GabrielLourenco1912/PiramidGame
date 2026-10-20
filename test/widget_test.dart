import 'package:atividade_mobile/app/app_widget.dart';
import 'package:atividade_mobile/app/app_viewmodels.dart';
import 'package:atividade_mobile/app/app_dependencies.dart';
import 'package:atividade_mobile/core/constants/app_constants.dart';
import 'package:atividade_mobile/presentation/widgets/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'support/test_environment.dart';

Future<AppViewModels> openApp(
  WidgetTester tester,
  TestEnvironment environment,
) async {
  final models = await environment.models();
  await tester.pumpWidget(AppWidget(models: models));
  await tester.pump();
  return models;
}

Future<void> finishSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2100));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash verifica sessão e abre login quando não autenticado', (
    tester,
  ) async {
    final environment = TestEnvironment();
    await openApp(tester, environment);
    expect(find.text('Verificando sua sessão…'), findsOneWidget);
    await finishSplash(tester);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await environment.auth.close();
  });

  testWidgets(
    'login por e-mail abre área principal e logout limpa dados da sessão',
    (tester) async {
      final environment = TestEnvironment();
      final models = await openApp(tester, environment);
      await finishSplash(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'alice@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('O campus no mesmo ranking.'), findsOneWidget);
      final person = await environment.createPerson('Ana');
      await models.students.loadStudentsCommand.execute();
      await environment.rate(person, 'alice', 4);
      await models.evaluations.loadMyEvaluationsCommand.execute();
      await models.rankings.loadPersonalRankingCommand.execute();
      await tester.pumpAndSettle();
      expect(models.students.students.value, isNotEmpty);
      await tester.tap(find.byTooltip('Sair da conta'));
      await tester.pumpAndSettle();
      expect(find.text('Entrar'), findsOneWidget);
      expect(models.students.students.value, isEmpty);
      expect(models.evaluations.myEvaluations.value, isEmpty);
      expect(models.rankings.personalRanking.value, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await environment.auth.close();
    },
  );

  testWidgets('cadastro valida confirmação de senha e permite criar conta', (
    tester,
  ) async {
    final environment = TestEnvironment();
    await openApp(tester, environment);
    await finishSplash(tester);
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alice@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(find.byType(TextFormField).at(2), 'diferente');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas devem ser iguais.'), findsOneWidget);
    expect(environment.auth.registerCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(2), '123456');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('O campus no mesmo ranking.'), findsOneWidget);
    expect(environment.auth.registerCalls, 1);
    await tester.pumpWidget(const SizedBox());
    await environment.auth.close();
  });

  testWidgets('Google usa o Command e abre a área principal', (tester) async {
    final environment = TestEnvironment();
    final models = await openApp(tester, environment);
    await finishSplash(tester);
    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();
    expect(models.auth.user.value?.provider, 'google.com');
    expect(find.text('O campus no mesmo ranking.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await environment.auth.close();
  });

  testWidgets('rota protegida redireciona acesso sem conta para login', (
    tester,
  ) async {
    final environment = TestEnvironment();
    await openApp(tester, environment);
    await finishSplash(tester);
    final context = tester.element(find.text('Entrar'));
    GoRouter.of(context).go(AppRoutes.globalRanking);
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('A opinião de todo o campus'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await environment.auth.close();
  });

  testWidgets(
    'restaura sessão e distingue ranking pessoal do global em tela móvel',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final environment = TestEnvironment(user: alice);
      final person = await environment.createPerson('Ana');
      await environment.rate(person, 'alice', 4);
      await environment.rate(person, 'bob', 5);
      await openApp(tester, environment);
      await finishSplash(tester);
      final context = tester.element(find.text('O campus no mesmo ranking.'));
      GoRouter.of(context).go(AppRoutes.ranking);
      await tester.pumpAndSettle();
      expect(find.text('O campus na sua opinião'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      await tester.tap(find.text('Global'));
      await tester.pumpAndSettle();
      expect(find.text('A opinião de todo o campus'), findsOneWidget);
      expect(find.text('67,5'), findsOneWidget);
      expect(find.text('2 avaliações'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await environment.auth.close();
    },
  );

  testWidgets(
    'cadastro separa perfil de notas e impede avaliar seu próprio perfil',
    (tester) async {
      final environment = TestEnvironment(user: alice);
      await openApp(tester, environment);
      await finishSplash(tester);
      await tester.tap(find.text('Cadastrar pessoa'));
      await tester.pumpAndSettle();
      expect(find.byType(StarRating), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
      await tester.enterText(find.byType(TextFormField).at(1), 'alice');
      await tester.ensureVisible(find.text('Escolher data de nascimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher data de nascimento'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Este é meu perfil'));
      await tester.tap(find.text('Este é meu perfil'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Cadastrar pessoa');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Este perfil está vinculado à sua conta. Você não pode se avaliar.',
        ),
        findsOneWidget,
      );
      expect(find.text('Avaliar pessoa'), findsNothing);
      final docs =
          (await environment.firestore.collection('pessoas').get()).docs;
      expect(docs.single.data()['usuarioUid'], 'alice');
      await tester.pumpWidget(const SizedBox());
      await environment.auth.close();
    },
  );

  testWidgets(
    'avaliação existente carrega estrelas e alteração mantém registro único',
    (tester) async {
      final environment = TestEnvironment(user: alice);
      final person = await environment.createPerson('Ana');
      await environment.rate(person, 'alice', 4);
      await openApp(tester, environment);
      await finishSplash(tester);
      final context = tester.element(find.text('O campus no mesmo ranking.'));
      GoRouter.of(context).go(AppRoutes.studentEvaluation(person.id));
      await tester.pumpAndSettle();
      expect(find.text('Nível Lenda: 60 / 75'), findsOneWidget);
      await tester.tap(find.byTooltip('Dar 5 estrelas').first);
      await tester.pumpAndSettle();
      expect(find.text('Nível Lenda: 61 / 75'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Salvar nova opinião'), 600);
      await tester.tap(find.text('Salvar nova opinião'));
      await tester.pumpAndSettle();
      expect(find.text('Nível Lenda: 61 de 75 pontos'), findsOneWidget);
      expect(
        (await environment.firestore.collection('avaliacoes').get()).docs,
        hasLength(1),
      );
      expect(
        (await environment.service.fetchEvaluation(
          'alice',
          person.id,
        ))!.pontuacaoTotal,
        61,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await environment.auth.close();
    },
  );

  testWidgets('alternância de tema é reativa e salva preferência local', (
    tester,
  ) async {
    final environment = TestEnvironment(user: alice);
    final models = await openApp(tester, environment);
    await finishSplash(tester);
    await tester.tap(find.byTooltip('Usar tema escuro'));
    await tester.pumpAndSettle();
    expect(models.theme.currentTheme.value.isDark, isTrue);
    expect(find.byTooltip('Usar tema claro'), findsOneWidget);
    expect(
      AppDependencies.of(
        tester.element(find.text('O campus no mesmo ranking.')),
      ).authViewModel.isAuthenticated,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await environment.auth.close();
  });
}
