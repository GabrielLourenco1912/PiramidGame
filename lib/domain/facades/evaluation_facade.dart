import '../../core/result/result.dart';
import '../models/evaluation.dart';
import '../use_cases/evaluation_use_cases.dart';

class EvaluationFacade {
  const EvaluationFacade({
    required this.saveEvaluation,
    required this.getEvaluation,
    required this.getMyEvaluations,
  });
  final SaveEvaluationUseCase saveEvaluation;
  final GetEvaluationUseCase getEvaluation;
  final GetMyEvaluationsUseCase getMyEvaluations;

  Future<Result<Evaluation>> save(EvaluationInput input) =>
      saveEvaluation(input);
  Future<Result<Evaluation?>> byPerson(String id) => getEvaluation(id);
  Future<Result<List<Evaluation>>> mine() => getMyEvaluations();
}
