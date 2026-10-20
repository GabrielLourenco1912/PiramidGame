import '../../core/result/result.dart';
import '../models/evaluation.dart';

abstract interface class EvaluationRepository {
  Future<Result<Evaluation>> save(Evaluation evaluation);
  Future<Result<Evaluation?>> byPerson(String uid, String pessoaId);
  Future<Result<List<Evaluation>>> byUser(String uid);
  Future<Result<List<Evaluation>>> all();
}
