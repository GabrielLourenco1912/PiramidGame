import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/popularity_criteria.dart';
import '../../core/result/result.dart';
import '../../domain/models/evaluation.dart';
import '../../domain/models/popularity_score.dart';
import '../../domain/models/student.dart';
import '../widgets/responsive_page.dart';
import '../widgets/star_rating.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({required this.studentId, super.key});
  final String studentId;
  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  Student? _person;
  PopularityScore _scores = PopularityScore.initial();
  bool _loaded = false;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(EvaluationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _person = null;
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
    final person = (personResult as Success<Student>).data;
    if (person.usuarioUid == dependencies.authViewModel.user.value?.uid) {
      setState(() {
        _error = 'Você não pode avaliar a si próprio.';
        _loading = false;
      });
      return;
    }
    final result = await dependencies.evaluationViewModel.loadEvaluationCommand
        .execute(id);
    if (!mounted || id != widget.studentId) return;
    if (result case Success<Evaluation?>(:final data)) {
      _person = person;
      _scores = data?.notas ?? PopularityScore.initial();
      _editing = data != null;
    } else if (result case Failure(:final message)) {
      _error = message;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await AppDependencies.of(context)
        .evaluationViewModel
        .saveEvaluationCommand
        .execute(EvaluationInput(pessoaId: widget.studentId, notas: _scores));
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação salva com sucesso.')),
      );
      context.go(AppRoutes.studentDetail(widget.studentId));
    } else if (result case Failure(:final message)) {
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_person == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Não foi possível carregar a avaliação.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
              TextButton(
                onPressed: () =>
                    context.go(AppRoutes.studentDetail(widget.studentId)),
                child: const Text('Voltar ao perfil'),
              ),
            ],
          ),
        ),
      );
    }
    return ResponsivePage(
      maxWidth: 760,
      child: ListView(
        padding: ResponsivePage.padding(context),
        children: [
          Text(_person!.nome, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _editing
                ? 'Altere sua opinião. A avaliação existente será atualizada.'
                : 'Sua opinião nos 15 critérios. Cada nota vai de 1 a 5 estrelas.',
          ),
          const SizedBox(height: 16),
          Text(
            'Nível Lenda: ${_scores.total} / 75',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final criterion in PopularityCriteria.criteria)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      criterion.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(criterion.description),
                    const SizedBox(height: 8),
                    IgnorePointer(
                      ignoring: _saving,
                      child: StarRating(
                        value: _scores.scoreFor(criterion.id),
                        onChanged: (value) => setState(
                          () => _scores = _scores.copyWithCriterion(
                            criterion.id,
                            value,
                          ),
                        ),
                      ),
                    ),
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
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_editing ? 'Salvar nova opinião' : 'Salvar avaliação'),
          ),
          TextButton(
            onPressed: _saving
                ? null
                : () => context.go(AppRoutes.studentDetail(widget.studentId)),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
