import 'package:flutter/material.dart';

/// Keeps page content readable on large screens while preserving a compact
/// mobile gutter.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({required this.child, this.maxWidth = 960, super.key});

  final Widget child;
  final double maxWidth;

  static EdgeInsets padding(
    BuildContext context, {
    double top = 12,
    double bottom = 28,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 900
        ? 32.0
        : width >= 600
        ? 24.0
        : 16.0;
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
