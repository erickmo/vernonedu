import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../course/domain/entities/course_entity.dart';
import '../../../course/presentation/cubit/course_cubit.dart';
import '../../../course/presentation/cubit/course_state.dart';
import '../../../course_batch/domain/entities/course_batch_entity.dart';
import '../../../course_batch/presentation/cubit/course_batch_cubit.dart';
import '../../../course_batch/presentation/cubit/course_batch_state.dart';
import '../../../student/domain/entities/student_entity.dart';
import '../../../student/presentation/cubit/student_cubit.dart';
import '../../../student/presentation/cubit/student_state.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_cubit.dart';

const String _kCompetencyType = 'competency';

class StudentAutocompleteField extends StatelessWidget {
  final StudentEntity? selected;
  final ValueChanged<StudentEntity> onSelected;
  const StudentAutocompleteField({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentCubit, StudentState>(
      builder: (context, state) {
        final students =
            state is StudentLoaded ? state.students : <StudentEntity>[];
        return Autocomplete<StudentEntity>(
          key: const Key('student-autocomplete'),
          displayStringForOption: (s) => s.name,
          optionsBuilder: (q) {
            if (q.text.isEmpty) return students.take(20);
            final lower = q.text.toLowerCase();
            return students.where((s) =>
                s.name.toLowerCase().contains(lower) ||
                s.email.toLowerCase().contains(lower));
          },
          onSelected: onSelected,
          fieldViewBuilder: (_, controller, focusNode, __) => TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Siswa',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_search),
            ),
            validator: (_) => selected == null ? 'Pilih siswa' : null,
          ),
        );
      },
    );
  }
}

class CourseDropdownField extends StatelessWidget {
  final CourseEntity? selected;
  final ValueChanged<CourseEntity?> onChanged;
  const CourseDropdownField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      builder: (context, state) {
        final courses =
            state is CourseLoaded ? state.courses : <CourseEntity>[];
        return DropdownButtonFormField<CourseEntity>(
          key: const Key('course-dropdown'),
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Course',
            border: OutlineInputBorder(),
          ),
          items: courses
              .map((c) =>
                  DropdownMenuItem(value: c, child: Text(c.courseName)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Pilih course' : null,
        );
      },
    );
  }
}

class BatchOptionalField extends StatelessWidget {
  final CourseEntity? course;
  final CourseBatchEntity? selected;
  final ValueChanged<CourseBatchEntity?> onChanged;
  const BatchOptionalField({
    super.key,
    required this.course,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseBatchCubit, CourseBatchState>(
      builder: (context, state) {
        final all = state is CourseBatchLoaded
            ? state.batches
            : <CourseBatchEntity>[];
        final filtered = course == null
            ? <CourseBatchEntity>[]
            : all.where((b) => b.courseId == course!.id).toList();
        return DropdownButtonFormField<CourseBatchEntity>(
          key: const Key('batch-dropdown'),
          value: selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Batch (opsional)',
            border: OutlineInputBorder(),
            helperText: 'Kosongkan jika kompetensi non-batch',
          ),
          items: filtered
              .map((b) => DropdownMenuItem(value: b, child: Text(b.code)))
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class CompetencyTemplateField extends StatelessWidget {
  final String? selectedTemplateId;
  final ValueChanged<String?> onChanged;
  const CompetencyTemplateField({
    super.key,
    required this.selectedTemplateId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CertificateCubit, CertificateState>(
      builder: (context, state) {
        final templates = state is CertificateLoaded
            ? state.templates.where((t) => t.type == _kCompetencyType).toList()
            : <CertificateTemplateEntity>[];
        return DropdownButtonFormField<String>(
          key: const Key('template-dropdown'),
          value: selectedTemplateId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Template Sertifikat (Kompetensi)',
            border: OutlineInputBorder(),
          ),
          items: templates
              .map((t) =>
                  DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Pilih template' : null,
        );
      },
    );
  }
}

class PassedIndicator extends StatelessWidget {
  final bool passed;
  final int passingScore;
  const PassedIndicator({
    super.key,
    required this.passed,
    required this.passingScore,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.error;
    final bg = passed ? AppColors.successSurface : AppColors.errorSurface;
    final icon = passed ? Icons.check_circle : Icons.cancel;
    final label = passed ? 'Lulus' : 'Tidak Lulus';
    final note = passed
        ? 'Skor memenuhi syarat minimum ($passingScore).'
        : 'Sertifikat hanya bisa diterbitkan jika lulus (skor >= $passingScore).';
    return Container(
      key: const Key('passed-indicator'),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color),
      ),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: color, fontWeight: FontWeight.w700)),
              Text(note, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }
}
