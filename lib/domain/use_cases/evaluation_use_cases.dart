import '../../core/result/result.dart';
import '../models/evaluation.dart';
import '../repositories/auth_repository.dart';
import '../repositories/evaluation_repository.dart';
import '../repositories/student_repository.dart';

class SaveEvaluationUseCase {
  const SaveEvaluationUseCase(this._evaluations, this._people, this._auth);
  final EvaluationRepository _evaluations;
  final StudentRepository _people;
  final AuthRepository _auth;

  Future<Result<Evaluation>> call(EvaluationInput input) async {
    final user = _auth.currentUser;
    if (user == null) return const Failure('Entre para avaliar uma pessoa.');
    if (!input.notas.isComplete) {
      return const Failure(
        'Avalie os 15 critérios com notas inteiras de 1 a 5.',
      );
    }
    final result = await _people.getStudentById(input.pessoaId);
    if (result case Failure(:final message)) return Failure(message);
    final person = (result as Success).data;
    if (person == null || !person.ativo) {
      return const Failure('Pessoa não encontrada.');
    }
    if (person.usuarioUid == user.uid) {
      return const Failure('Você não pode avaliar a si próprio.');
    }
    final now = DateTime.now();
    return _evaluations.save(
      Evaluation(
        avaliadorUid: user.uid,
        pessoaId: input.pessoaId,
        notas: input.notas,
        dataAvaliacao: now,
        atualizadoEm: now,
      ),
    );
  }
}

class GetEvaluationUseCase {
  const GetEvaluationUseCase(this._evaluations, this._auth);
  final EvaluationRepository _evaluations;
  final AuthRepository _auth;

  Future<Result<Evaluation?>> call(String pessoaId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Future.value(const Failure('Entre para continuar.'));
    }
    return _evaluations.byPerson(user.uid, pessoaId);
  }
}

class GetMyEvaluationsUseCase {
  const GetMyEvaluationsUseCase(this._evaluations, this._auth);
  final EvaluationRepository _evaluations;
  final AuthRepository _auth;

  Future<Result<List<Evaluation>>> call() {
    final user = _auth.currentUser;
    if (user == null) {
      return Future.value(const Failure('Entre para continuar.'));
    }
    return _evaluations.byUser(user.uid);
  }
}
