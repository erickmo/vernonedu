import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../course_batch/domain/entities/course_batch_entity.dart';
import '../../../course_batch/presentation/cubit/course_batch_cubit.dart';
import '../../../course_batch/presentation/cubit/course_batch_state.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_cubit.dart';
import 'issue_step_card.dart';

const String _kParticipantType = 'participant';

/// Step 1 — Batch dropdown.
class BatchSelectStep extends StatelessWidget {
  final CourseBatchEntity? selected;
  final ValueChanged<CourseBatchEntity?> onChanged;
  const BatchSelectStep(
      {super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseBatchCubit, CourseBatchState>(
      builder: (context, state) {
        final batches =
            state is CourseBatchLoaded ? state.batches : <CourseBatchEntity>[];
        return IssueStepCard(
          number: 1,
          title: 'Pilih Batch',
          child: state is CourseBatchLoading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<CourseBatchEntity>(
                  key: const Key('batch-dropdown'),
                  value: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Batch',
                    border: OutlineInputBorder(),
                  ),
                  items: batches
                      .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text('${b.code} — ${b.courseName}'),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
        );
      },
    );
  }
}

/// Step 3 — Template dropdown filtered by participant type.
class ParticipantTemplateStep extends StatelessWidget {
  final String? selectedTemplateId;
  final ValueChanged<String?> onChanged;
  const ParticipantTemplateStep({
    super.key,
    required this.selectedTemplateId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CertificateCubit, CertificateState>(
      builder: (context, state) {
        final templates = state is CertificateLoaded
            ? state.templates.where((t) => t.type == _kParticipantType).toList()
            : <CertificateTemplateEntity>[];
        return IssueStepCard(
          number: 3,
          title: 'Pilih Template',
          child: DropdownButtonFormField<String>(
            key: const Key('template-dropdown'),
            value: selectedTemplateId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Template Sertifikat (Partisipan)',
              border: OutlineInputBorder(),
            ),
            items: templates
                .map((t) =>
                    DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}
