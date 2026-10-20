import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../app/app_dependencies.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/ranking_card.dart';
import '../widgets/responsive_page.dart';

class RankingPage extends SignalStatefulWidget {
  const RankingPage({this.global = false, super.key});
  final bool global;
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(RankingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.global != widget.global) Future.microtask(_load);
  }

  Future<void> _load() async {
    final viewModel = AppDependencies.of(context).rankingViewModel;
    await (widget.global
            ? viewModel.loadGlobalRankingCommand
            : viewModel.loadPersonalRankingCommand)
        .execute();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppDependencies.of(context).rankingViewModel;
    final entries = widget.global
        ? viewModel.globalRanking.value
        : viewModel.personalRanking.value;
    final error = viewModel.errorMessage.value;
    return ResponsivePage(
      maxWidth: 780,
      child: Padding(
        padding: ResponsivePage.padding(context, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.person_outline),
                  label: Text('Pessoal'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.public),
                  label: Text('Global'),
                ),
              ],
              selected: {widget.global},
              onSelectionChanged: (value) => context.go(
                value.first ? AppRoutes.globalRanking : AppRoutes.ranking,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.global
                  ? 'A opinião de todo o campus'
                  : 'O campus na sua opinião',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.global
                  ? 'Média das notas totais de todos os usuários. Cada pessoa mostra a quantidade de avaliações.'
                  : 'Somente as avaliações feitas pela sua conta, em ordem de maior Nível Lenda.',
            ),
            const SizedBox(height: 12),
            if (viewModel.loading.value) const LinearProgressIndicator(),
            if (error != null) ...[
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? EmptyState(
                      icon: Icons.leaderboard_outlined,
                      title: 'Ainda não há avaliações neste ranking',
                      message: widget.global
                          ? 'As pessoas entram no ranking ao receberem a primeira avaliação.'
                          : 'Avalie uma pessoa para começar seu ranking pessoal.',
                      action: FilledButton(
                        onPressed: () => context.go(AppRoutes.students),
                        child: const Text('Ver pessoas'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => RankingCard(
                          position: index + 1,
                          entry: entries[index],
                          global: widget.global,
                          onTap: () => context.go(
                            AppRoutes.studentDetail(entries[index].pessoa.id),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
