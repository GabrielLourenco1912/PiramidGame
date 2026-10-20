import '../../core/result/result.dart';
import '../models/evaluation.dart';
import '../models/ranking_entry.dart';
import '../models/student.dart';
import '../repositories/auth_repository.dart';
import '../repositories/evaluation_repository.dart';
import '../repositories/student_repository.dart';

class CalculatePersonalRankingUseCase {
  const CalculatePersonalRankingUseCase(
    this._people,
    this._evaluations,
    this._auth,
  );
  final StudentRepository _people;
  final EvaluationRepository _evaluations;
  final AuthRepository _auth;

  Future<Result<List<RankingEntry>>> call() async {
    final user = _auth.currentUser;
    if (user == null) return const Failure('Entre para ver seu ranking.');
    final people = await _people.getStudents();
    if (people case Failure(:final message)) return Failure(message);
    final evaluations = await _evaluations.byUser(user.uid);
    if (evaluations case Failure(:final message)) return Failure(message);
    return Success(
      _calculate(
        (people as Success<List<Student>>).data,
        (evaluations as Success<List<Evaluation>>).data
            .where((evaluation) => evaluation.avaliadorUid == user.uid)
            .toList(),
      ),
    );
  }
}

class CalculateGlobalRankingUseCase {
  const CalculateGlobalRankingUseCase(
    this._people,
    this._evaluations,
    this._auth,
  );
  final StudentRepository _people;
  final EvaluationRepository _evaluations;
  final AuthRepository _auth;

  Future<Result<List<RankingEntry>>> call() async {
    if (_auth.currentUser == null) {
      return const Failure('Entre para ver o ranking.');
    }
    final people = await _people.getStudents();
    if (people case Failure(:final message)) return Failure(message);
    final evaluations = await _evaluations.all();
    if (evaluations case Failure(:final message)) return Failure(message);
    return Success(
      _calculate(
        (people as Success<List<Student>>).data,
        (evaluations as Success<List<Evaluation>>).data,
      ),
    );
  }
}

List<RankingEntry> _calculate(
  List<Student> people,
  List<Evaluation> evaluations,
) {
  final grouped = <String, Map<String, Evaluation>>{};
  for (final evaluation in evaluations) {
    if (!evaluation.notas.isComplete) continue;
    // A identidade é única mesmo se uma fonte retornar registros repetidos.
    (grouped[evaluation.pessoaId] ??= {})[evaluation.avaliadorUid] = evaluation;
  }
  final entries = <RankingEntry>[];
  for (final person in people.where((person) => person.ativo)) {
    final ratings = grouped[person.id]?.values
        .where((rating) => rating.avaliadorUid != person.usuarioUid)
        .toList();
    if (ratings == null || ratings.isEmpty) continue;
    final total = ratings.fold<int>(
      0,
      (sum, rating) => sum + rating.pontuacaoTotal,
    );
    entries.add(
      RankingEntry(
        pessoa: person,
        pontuacao: total / ratings.length,
        quantidadeAvaliacoes: ratings.length,
      ),
    );
  }
  entries.sort((a, b) {
    final scoreOrder = b.pontuacao.compareTo(a.pontuacao);
    if (scoreOrder != 0) return scoreOrder;
    final nameOrder = a.pessoa.nome.toLowerCase().compareTo(
      b.pessoa.nome.toLowerCase(),
    );
    return nameOrder != 0 ? nameOrder : a.pessoa.id.compareTo(b.pessoa.id);
  });
  return entries;
}
