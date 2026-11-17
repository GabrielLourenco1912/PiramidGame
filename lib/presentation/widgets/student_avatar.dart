import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../app/app_dependencies.dart';

class StudentAvatar extends SignalWidget {
  const StudentAvatar({
    required this.name,
    this.size = 52,
    this.highlighted = false,
    this.photoUrl,
    this.userUid,
    super.key,
  });

  final String name;
  final double size;
  final bool highlighted;
  final String? photoUrl;
  final String? userUid;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var photo = photoUrl;
    if (userUid != null) {
      final currentUser = AppDependencies.of(context).authViewModel.user.value;
      if (currentUser?.uid == userUid) photo = currentUser!.foto;
    }
    final background = highlighted
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
    final foreground = highlighted
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    final initials = Center(
      child: Text(
        _initials(name),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
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
        child: ClipOval(
          child: photo == null || photo.isEmpty
              ? initials
              : Image.network(
                  photo,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => initials,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : initials,
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
