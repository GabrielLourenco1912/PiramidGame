import '../../core/result/result.dart';
import '../../domain/models/evaluation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/evaluation_repository.dart';
import '../firebase_error_message.dart';
import '../services/firestore_service.dart';

class EvaluationRepositoryImpl implements EvaluationRepository {
  const EvaluationRepositoryImpl(this._service, this._auth);
  final FirestoreService _service;
  final AuthRepository _auth;

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    if (_auth.currentUser == null) {
      return const Failure('Entre para continuar.');
    }
    try {
      return Success(await action());
    } catch (error) {
      return Failure(
        firebaseErrorMessage(
          error,
          'Não foi possível carregar ou salvar a avaliação.',
        ),
        cause: error,
      );
    }
  }

  @override
  Future<Result<Evaluation>> save(Evaluation evaluation) {
    if (evaluation.avaliadorUid != _auth.currentUser?.uid) {
      return Future.value(
        const Failure('Você só pode alterar suas próprias avaliações.'),
      );
    }
    return _run(() => _service.saveEvaluation(evaluation));
  }

  @override
  Future<Result<Evaluation?>> byPerson(String uid, String pessoaId) {
    if (uid != _auth.currentUser?.uid) {
      return Future.value(const Failure('Acesso negado.'));
    }
    return _run(() => _service.fetchEvaluation(uid, pessoaId));
  }

  @override
  Future<Result<List<Evaluation>>> byUser(String uid) {
    if (uid != _auth.currentUser?.uid) {
      return Future.value(const Failure('Acesso negado.'));
    }
    return _run(() => _service.fetchEvaluations(uid: uid));
  }

  @override
  Future<Result<List<Evaluation>>> all() =>
      _run(() => _service.fetchEvaluations());
}
