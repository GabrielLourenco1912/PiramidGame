import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    required this.value,
    this.onChanged,
    this.size = 28,
    super.key,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    final outline = Theme.of(context).colorScheme.outline;
    if (onChanged == null) {
      return Semantics(
        label: '$value de 5 estrelas',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final selected = index < value;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: selected ? color : outline,
                  size: size,
                ),
              );
            }),
          ),
        ),
      );
    }

    final tapTarget = size + 16 < 48 ? 48.0 : size + 16;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final score = index + 1;
        final selected = score <= value;
        return SizedBox(
          width: tapTarget,
          height: tapTarget,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(Size.square(tapTarget)),
            tooltip: 'Dar $score estrela${score == 1 ? '' : 's'}',
            onPressed: () => onChanged!(score),
            icon: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: selected ? color : outline,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
