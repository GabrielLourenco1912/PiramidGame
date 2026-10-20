import 'package:flutter/material.dart';

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    required this.name,
    this.size = 52,
    this.highlighted = false,
    super.key,
  });

  final String name;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlighted
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final foreground = highlighted
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Semantics(
      image: true,
      label: 'Avatar de $name',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: foreground.withValues(alpha: 0.12)),
        ),
        child: Text(
          _initials(name),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
