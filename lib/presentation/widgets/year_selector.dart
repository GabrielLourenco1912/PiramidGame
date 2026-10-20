import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class YearSelector extends StatelessWidget {
  const YearSelector({required this.value, required this.onChanged, super.key});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: const InputDecoration(
        labelText: 'Turma/ano',
        prefixIcon: Icon(Icons.calendar_month_rounded),
      ),
      items: [
        for (
          var year = AppConstants.maxClassYear;
          year >= AppConstants.minClassYear;
          year--
        )
          DropdownMenuItem(value: year, child: Text(year.toString())),
      ],
      onChanged: (year) {
        if (year != null) {
          onChanged(year);
        }
      },
    );
  }
}
