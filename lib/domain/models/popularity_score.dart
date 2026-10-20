import '../../core/constants/popularity_criteria.dart';

class PopularityScore {
  PopularityScore(Map<String, int> values) : values = Map.unmodifiable(values);

  factory PopularityScore.initial({int value = 1}) {
    return PopularityScore({
      for (final criterion in PopularityCriteria.criteria) criterion.id: value,
    });
  }

  factory PopularityScore.fromJson(Map<String, dynamic> json) {
    if (json.values.any((value) => value is! int)) {
      throw const FormatException('As notas devem ser números inteiros.');
    }
    return PopularityScore(json.cast<String, int>());
  }

  final Map<String, int> values;

  int get total => values.values.fold<int>(0, (sum, score) => sum + score);

  bool get isComplete {
    return values.length == PopularityCriteria.criteria.length &&
        PopularityCriteria.criteria.every((criterion) {
          final score = values[criterion.id];
          return score != null && score >= 1 && score <= 5;
        });
  }

  int scoreFor(String criterionId) => values[criterionId] ?? 1;

  PopularityScore copyWithCriterion(String criterionId, int score) {
    return PopularityScore({...values, criterionId: score});
  }

  Map<String, int> toJson() => Map<String, int>.from(values);
}
