import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/popularity_criteria.dart';
import '../../core/result/result.dart';
import '../../core/utils/date_formatters.dart';
import '../../domain/models/student.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/responsive_page.dart';
import '../widgets/star_rating.dart';
import '../widgets/student_avatar.dart';

class StudentDetailPage extends SignalStatefulWidget {
  const StudentDetailPage({required this.studentId, super.key});
  final String studentId;
  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  bool _loaded = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(StudentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final dependencies = AppDependencies.of(context);
    final id = widget.studentId;
    final personResult = await dependencies
        .studentViewModel
        .loadStudentByIdCommand
        .execute(id);
    if (!mounted || id != widget.studentId) return;
    if (personResult case Failure(:final message)) {
      setState(() {
        _error = message;
        _loading = false;
      });
      return;
    }
    final evaluationResult = await dependencies
        .evaluationViewModel
        .loadEvaluationCommand
        .execute(id);
    if (!mounted || id != widget.studentId) return;
    if (evaluationResult case Failure(:final message)) _error = message;
    setState(() => _loading = false);
  }

  Future<void> _delete(Student person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(studentName: person.nome),
    );
    if (confirmed != true || !mounted) return;
    final result = await AppDependencies.of(
      context,
    ).studentViewModel.deleteStudentCommand.execute(person.id);
    if (!mounted) return;
    if (result.isSuccess) {
      context.go(AppRoutes.students);
    } else if (result case Failure(:final message)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final selected = dependencies.studentViewModel.selectedStudent.value;
    final person = selected?.id == widget.studentId ? selected : null;
    final evaluation =
        dependencies.evaluationViewModel.selectedEvaluation.value;
    final ownEvaluation = evaluation?.pessoaId == widget.studentId
        ? evaluation
        : null;
    final uid = dependencies.authViewModel.user.value?.uid;
    final isSelf = person?.usuarioUid != null && person?.usuarioUid == uid;
    final canEdit = person?.criadoPor == uid;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (person == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Pessoa não encontrada.'),
            TextButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    return ResponsivePage(
      maxWidth: 760,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsivePage.padding(context),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    StudentAvatar(name: person.nome, size: 80),
                    const SizedBox(height: 16),
                    Text(
                      person.nome,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text('@${person.apelido}'),
                    const SizedBox(height: 12),
                    Text('${person.curso} · Turma ${person.turmaAno}'),
                    Text(
                      'Nascimento: ${formatBrazilianDate(person.dataNascimento)}',
                    ),
                    const SizedBox(height: 20),
                    if (isSelf)
                      const Text(
                        'Este perfil está vinculado à sua conta. Você não pode se avaliar.',
                        textAlign: TextAlign.center,
                      )
                    else
                      FilledButton.icon(
                        onPressed: () =>
                            context.go(AppRoutes.studentEvaluation(person.id)),
                        icon: const Icon(Icons.star_outline_rounded),
                        label: Text(
                          ownEvaluation == null
                              ? 'Avaliar pessoa'
                              : 'Alterar minha avaliação',
                        ),
                      ),
                    if (canEdit) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.studentEdit(person.id)),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar perfil'),
                          ),
                          TextButton.icon(
                            onPressed:
                                dependencies.studentViewModel.loading.value
                                ? null
                                : () => _delete(person),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remover'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Minha avaliação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (ownEvaluation == null)
              const Text('Você ainda não avaliou esta pessoa.')
            else ...[
              Text(
                'Nível Lenda: ${ownEvaluation.pontuacaoTotal} de 75 pontos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Atualizada em ${formatBrazilianDate(ownEvaluation.atualizadoEm)}',
              ),
              const SizedBox(height: 12),
              for (final criterion in PopularityCriteria.criteria)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Text(criterion.title)),
                        const SizedBox(width: 16),
                        StarRating(
                          value: ownEvaluation.notas.scoreFor(criterion.id),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
