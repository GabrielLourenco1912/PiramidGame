import '../../core/result/result.dart';
import '../models/ranking_entry.dart';
import '../use_cases/ranking_use_cases.dart';

class RankingFacade {
  const RankingFacade({
    required this.personalRanking,
    required this.globalRanking,
  });
  final CalculatePersonalRankingUseCase personalRanking;
  final CalculateGlobalRankingUseCase globalRanking;

  Future<Result<List<RankingEntry>>> personal() => personalRanking();
  Future<Result<List<RankingEntry>>> global() => globalRanking();
}
