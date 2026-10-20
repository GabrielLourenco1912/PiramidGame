import 'package:signals_flutter/signals_flutter.dart';
import '../../core/command/command.dart';
import '../../domain/facades/ranking_facade.dart';
import '../../domain/models/ranking_entry.dart';
import 'async_viewmodel.dart';

class RankingViewModel extends AsyncViewModel {
  RankingViewModel(this._facade) {
    loadPersonalRankingCommand = Command(
      () => run(
        _facade.personal,
        onSuccess: (entries) => personalRanking.value = entries,
      ),
    );
    loadGlobalRankingCommand = Command(
      () => run(
        _facade.global,
        onSuccess: (entries) => globalRanking.value = entries,
      ),
    );
  }

  final RankingFacade _facade;
  final personalRanking = signal<List<RankingEntry>>([]);
  final globalRanking = signal<List<RankingEntry>>([]);
  late final Command<List<RankingEntry>> loadPersonalRankingCommand;
  late final Command<List<RankingEntry>> loadGlobalRankingCommand;

  @override
  void clearData() {
    personalRanking.value = [];
    globalRanking.value = [];
  }
}
