import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../enrollment/domain/entities/enrollment_entity.dart';

/// Checkbox list of enrollments with master select-all + counter.
class EnrollmentCheckboxList extends StatelessWidget {
  final List<EnrollmentEntity> enrollments;
  final Set<String> selectedIds;
  final void Function(String id, bool? checked) onToggle;
  final ValueChanged<bool?> onToggleAll;
  const EnrollmentCheckboxList({
    super.key,
    required this.enrollments,
    required this.selectedIds,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.md),
        child: Text('Tidak ada siswa terdaftar di batch ini.'),
      );
    }
    final allSelected = selectedIds.length == enrollments.length;
    return Column(
      children: [
        CheckboxListTile(
          key: const Key('select-all'),
          value: allSelected,
          tristate: true,
          title: Text(
            'Pilih Semua (${selectedIds.length} dari ${enrollments.length} dipilih)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onChanged: onToggleAll,
        ),
        const Divider(height: 1),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: enrollments.length,
            itemBuilder: (_, i) {
              final e = enrollments[i];
              return CheckboxListTile(
                key: Key('student-${e.studentId}'),
                value: selectedIds.contains(e.studentId),
                title: Text(e.studentName),
                subtitle: Text(e.studentPhone),
                onChanged: (v) => onToggle(e.studentId, v),
              );
            },
          ),
        ),
      ],
    );
  }
}
