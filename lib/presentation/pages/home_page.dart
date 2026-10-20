import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/ifpr_mark.dart';
import '../widgets/responsive_page.dart';

class HomePage extends SignalStatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    final dependencies = AppDependencies.of(context);
    await Future.wait([
      dependencies.studentViewModel.loadStudentsCommand.execute(),
      dependencies.evaluationViewModel.loadMyEvaluationsCommand.execute(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final user = dependencies.authViewModel.user.value;
    final people = dependencies.studentViewModel.students.value;
    final evaluations = dependencies.evaluationViewModel.myEvaluations.value;
    final activeIds = people.map((person) => person.id).toSet();
    final evaluationCount = evaluations
        .where((item) => activeIds.contains(item.pessoaId))
        .length;
    final error =
        dependencies.studentViewModel.errorMessage.value ??
        dependencies.evaluationViewModel.errorMessage.value;
    final colors = Theme.of(context).colorScheme;
    return ResponsivePage(
      maxWidth: 800,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsivePage.padding(context),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IfprMark(size: 44),
                  const SizedBox(height: 16),
                  Text(
                    'O campus no mesmo ranking.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.nome.isNotEmpty == true
                        ? 'Olá, ${user!.nome}!'
                        : user?.email ?? '',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cadastre pessoas, compartilhe sua opinião e descubra quem alcançou o Nível Lenda.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(label: Text('${people.length} pessoas no campus')),
                Chip(label: Text('$evaluationCount avaliações suas')),
              ],
            ),
            if (dependencies.studentViewModel.loading.value ||
                dependencies.evaluationViewModel.loading.value)
              const LinearProgressIndicator(),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: colors.error)),
              TextButton(
                onPressed: _refresh,
                child: const Text('Tentar novamente'),
              ),
            ],
            const SizedBox(height: 16),
            _Destination(
              icon: Icons.groups_rounded,
              title: 'Pessoas',
              description: 'Conheça os perfis e avalie nos 15 critérios.',
              route: AppRoutes.students,
            ),
            _Destination(
              icon: Icons.person_add_alt_1_rounded,
              title: 'Cadastrar pessoa',
              description:
                  'Crie um perfil com nome, curso, turma, apelido e nascimento.',
              route: AppRoutes.newStudent,
            ),
            _Destination(
              icon: Icons.person_rounded,
              title: 'Ranking pessoal',
              description: 'Quem se destaca nas avaliações que você fez.',
              route: AppRoutes.ranking,
            ),
            _Destination(
              icon: Icons.public_rounded,
              title: 'Ranking global',
              description: 'A média das avaliações de todos os usuários.',
              route: AppRoutes.globalRanking,
            ),
            const SizedBox(height: 16),
            const Text(
              '15 critérios · 1 a 5 estrelas · 15 a 75 pontos\n'
              'Uma avaliação por pessoa. Você pode alterar sua opinião depois.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(route),
    ),
  );
}
