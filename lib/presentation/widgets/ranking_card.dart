import 'package:flutter/material.dart';
import '../../domain/models/ranking_entry.dart';
import 'student_avatar.dart';

class RankingCard extends StatelessWidget {
  const RankingCard({
    required this.position,
    required this.entry,
    this.global = false,
    this.onTap,
    super.key,
  });
  final int position;
  final RankingEntry entry;
  final bool global;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final person = entry.pessoa;
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '$positionº',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 12),
              StudentAvatar(
                name: person.nome,
                size: 42,
                highlighted: position <= 3,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${person.curso} · ${person.turmaAno}'),
                    if (global)
                      Text(
                        '${entry.quantidadeAvaliacoes} ${entry.quantidadeAvaliacoes == 1 ? "avaliação" : "avaliações"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    global
                        ? entry.formattedScore
                        : entry.pontuacao.toInt().toString(),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: colors.primary),
                  ),
                  const Text('pontos'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
