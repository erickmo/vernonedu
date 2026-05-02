import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../course_batch/domain/entities/course_batch_entity.dart';
import '../../../course_batch/presentation/cubit/course_batch_cubit.dart';
import '../../../enrollment/domain/entities/enrollment_entity.dart';
import '../../../enrollment/presentation/cubit/enrollment_cubit.dart';
import '../../../enrollment/presentation/cubit/enrollment_state.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_cubit.dart';
import '../cubit/certificate_issue_cubit.dart';
import '../widgets/enrollment_checkbox_list.dart';
import '../widgets/issue_step_card.dart';
import '../widgets/participant_steps.dart';

// TODO: move to env config
const String kVerificationBaseUrl = 'https://vernonedu.com/sertifikat';

class IssueParticipantPage extends StatelessWidget {
  const IssueParticipantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CourseBatchCubit>()..loadBatches()),
        BlocProvider(create: (_) => getIt<EnrollmentCubit>()),
        BlocProvider(create: (_) => getIt<CertificateCubit>()..loadAll()),
        BlocProvider(create: (_) => getIt<CertificateIssueCubit>()),
      ],
      child: const _IssueParticipantView(),
    );
  }
}

class _IssueParticipantView extends StatefulWidget {
  const _IssueParticipantView();

  @override
  State<_IssueParticipantView> createState() => _IssueParticipantViewState();
}

class _IssueParticipantViewState extends State<_IssueParticipantView> {
  CourseBatchEntity? _selectedBatch;
  final Set<String> _selectedStudentIds = <String>{};
  String? _selectedTemplateId;

  void _onBatchChanged(CourseBatchEntity? batch) {
    setState(() {
      _selectedBatch = batch;
      _selectedStudentIds.clear();
    });
    if (batch != null) {
      context.read<EnrollmentCubit>().loadEnrollments();
    }
  }

  void _toggleStudent(String id, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedStudentIds.add(id);
      } else {
        _selectedStudentIds.remove(id);
      }
    });
  }

  void _toggleAll(List<EnrollmentEntity> all, bool? checked) {
    setState(() {
      _selectedStudentIds.clear();
      if (checked == true) {
        _selectedStudentIds.addAll(all.map((e) => e.studentId));
      }
    });
  }

  bool get _canSubmit =>
      _selectedBatch != null &&
      _selectedStudentIds.isNotEmpty &&
      _selectedTemplateId != null;

  Future<bool> _confirm(CertificateTemplateEntity template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penerbitan'),
        content: Text(
          'Terbitkan ${_selectedStudentIds.length} sertifikat partisipan '
          'untuk batch "${_selectedBatch!.code}" '
          'menggunakan template "${template.name}"?\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Terbitkan'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _onIssueStateChanged(BuildContext ctx, CertificateIssueState state) {
    if (state is CertificateIssueSuccess) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text('${state.issuedCount} sertifikat diterbitkan'),
      ));
      setState(_selectedStudentIds.clear);
      ctx.read<CertificateIssueCubit>().reset();
    } else if (state is CertificateIssueError) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(state.message),
      ));
      ctx.read<CertificateIssueCubit>().reset();
    }
  }

  Future<void> _onSubmit() async {
    final certState = context.read<CertificateCubit>().state;
    if (certState is! CertificateLoaded) return;
    final template = certState.templates.firstWhere(
      (t) => t.id == _selectedTemplateId,
      orElse: () => certState.templates.first,
    );
    if (!await _confirm(template) || !mounted) return;
    await context.read<CertificateIssueCubit>().issueParticipant(
          batchId: _selectedBatch!.id,
          studentIds: _selectedStudentIds.toList(),
          courseId: _selectedBatch!.courseId,
          templateId: _selectedTemplateId,
          verificationBaseUrl: kVerificationBaseUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateIssueCubit, CertificateIssueState>(
      listener: _onIssueStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Terbitkan Sertifikat Partisipan')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BatchSelectStep(
                  selected: _selectedBatch,
                  onChanged: _onBatchChanged,
                ),
                const SizedBox(height: AppDimensions.md),
                IssueStepCard(
                  number: 2,
                  title: 'Pilih Siswa',
                  child: _buildStudentSection(),
                ),
                const SizedBox(height: AppDimensions.md),
                ParticipantTemplateStep(
                  selectedTemplateId: _selectedTemplateId,
                  onChanged: (v) =>
                      setState(() => _selectedTemplateId = v),
                ),
                const SizedBox(height: AppDimensions.lg),
                _SubmitButton(
                  enabled: _canSubmit,
                  count: _selectedStudentIds.length,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSection() {
    if (_selectedBatch == null) {
      return const Text('Pilih batch terlebih dahulu.');
    }
    return BlocBuilder<EnrollmentCubit, EnrollmentState>(
      builder: (context, state) {
        if (state is EnrollmentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is! EnrollmentLoaded) {
          return const Text('Belum ada data enrollment.');
        }
        final filtered = state.enrollments
            .where((e) => e.courseBatchId == _selectedBatch!.id)
            .toList();
        return EnrollmentCheckboxList(
          enrollments: filtered,
          selectedIds: _selectedStudentIds,
          onToggle: _toggleStudent,
          onToggleAll: (v) => _toggleAll(filtered, v),
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final int count;
  final Future<void> Function() onPressed;
  const _SubmitButton({
    required this.enabled,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CertificateIssueCubit, CertificateIssueState>(
      builder: (context, state) {
        final loading = state is CertificateIssueLoading;
        return SizedBox(
          height: AppDimensions.buttonHeightLg,
          child: ElevatedButton.icon(
            key: const Key('submit-button'),
            onPressed: !enabled || loading ? null : onPressed,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.workspace_premium),
            label: Text(loading
                ? 'Menerbitkan...'
                : 'Terbitkan Sertifikat ($count)'),
          ),
        );
      },
    );
  }
}
