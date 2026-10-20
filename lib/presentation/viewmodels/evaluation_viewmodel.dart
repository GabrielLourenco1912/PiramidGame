import 'package:signals_flutter/signals_flutter.dart';
import '../../core/command/command.dart';
import '../../domain/facades/evaluation_facade.dart';
import '../../domain/models/evaluation.dart';
import 'async_viewmodel.dart';

class EvaluationViewModel extends AsyncViewModel {
  EvaluationViewModel(this._facade) {
    loadEvaluationCommand = Command1((String id) {
      selectedEvaluation.value = null;
      return run(
        () => _facade.byPerson(id),
        onSuccess: (evaluation) => selectedEvaluation.value = evaluation,
      );
    });
    loadMyEvaluationsCommand = Command(
      () => run(
        _facade.mine,
        onSuccess: (evaluations) => myEvaluations.value = evaluations,
      ),
    );
    saveEvaluationCommand = Command1(
      (EvaluationInput input) => run(
        () => _facade.save(input),
        onSuccess: (evaluation) {
          selectedEvaluation.value = evaluation;
          myEvaluations.value = [
            ...myEvaluations.value.where(
              (item) => item.pessoaId != evaluation.pessoaId,
            ),
            evaluation,
          ];
        },
        successText: 'Avaliação salva. Sua opinião atualizou os rankings.',
      ),
    );
  }

  final EvaluationFacade _facade;
  final selectedEvaluation = signal<Evaluation?>(null);
  final myEvaluations = signal<List<Evaluation>>([]);

  late final Command1<String, Evaluation?> loadEvaluationCommand;
  late final Command<List<Evaluation>> loadMyEvaluationsCommand;
  late final Command1<EvaluationInput, Evaluation> saveEvaluationCommand;

  @override
  void clearData() {
    selectedEvaluation.value = null;
    myEvaluations.value = [];
  }
}
