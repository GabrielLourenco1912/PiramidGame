import 'popularity_score.dart';

class Evaluation {
  const Evaluation({
    required this.avaliadorUid,
    required this.pessoaId,
    required this.notas,
    required this.dataAvaliacao,
    required this.atualizadoEm,
  });

  final String avaliadorUid;
  final String pessoaId;
  final PopularityScore notas;
  final DateTime dataAvaliacao;
  final DateTime atualizadoEm;

  String get id => '${avaliadorUid}_$pessoaId';
  int get pontuacaoTotal => notas.total;
}

class EvaluationInput {
  const EvaluationInput({required this.pessoaId, required this.notas});

  final String pessoaId;
  final PopularityScore notas;
}
