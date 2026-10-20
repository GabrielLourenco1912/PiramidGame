import 'package:flutter/material.dart';

import '../../core/constants/course_constants.dart';

class CourseSelector extends StatelessWidget {
  const CourseSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      decoration: const InputDecoration(
        labelText: 'Curso',
        prefixIcon: Icon(Icons.school_rounded),
      ),
      items: [
        for (final course in CourseConstants.courses)
          DropdownMenuItem(
            value: course,
            child: Text(course, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (course) {
        if (course != null) {
          onChanged(course);
        }
      },
    );
  }
}
