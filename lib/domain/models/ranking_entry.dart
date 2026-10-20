import 'student.dart';

class RankingEntry {
  const RankingEntry({
    required this.pessoa,
    required this.pontuacao,
    required this.quantidadeAvaliacoes,
  });

  final Student pessoa;
  final double pontuacao;
  final int quantidadeAvaliacoes;

  String get formattedScore =>
      pontuacao.toStringAsFixed(1).replaceAll('.', ',');
}
