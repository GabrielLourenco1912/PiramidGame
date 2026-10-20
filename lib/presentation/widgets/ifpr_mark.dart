import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class IfprMark extends StatelessWidget {
  const IfprMark({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final unit = size / 4;
    return Semantics(
      image: true,
      label: 'Marca do IFPR',
      child: ExcludeSemantics(
        child: SizedBox(
          width: unit * 3,
          height: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _Module(
                    size: unit,
                    color: AppColors.institutionalRed,
                    shape: BoxShape.circle,
                  ),
                  _Module(size: unit, color: AppColors.institutionalGreen),
                  _Module(size: unit, color: AppColors.institutionalGreen),
                ],
              ),
              for (var row = 0; row < 3; row++)
                Row(
                  children: [
                    _Module(size: unit, color: AppColors.institutionalGreen),
                    _Module(size: unit, color: AppColors.institutionalGreen),
                    if (row == 1)
                      _Module(size: unit, color: AppColors.institutionalGreen)
                    else
                      SizedBox(width: unit, height: unit),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Module extends StatelessWidget {
  const _Module({
    required this.size,
    required this.color,
    this.shape = BoxShape.rectangle,
  });

  final double size;
  final Color color;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(size * 0.08),
      child: Container(
        width: size * 0.84,
        height: size * 0.84,
        decoration: BoxDecoration(
          color: color,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(2)
              : null,
        ),
      ),
    );
  }
}
