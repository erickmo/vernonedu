import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../course/domain/entities/course_entity.dart';
import '../../../course/presentation/cubit/course_cubit.dart';
import '../../../course_batch/domain/entities/course_batch_entity.dart';
import '../../../course_batch/presentation/cubit/course_batch_cubit.dart';
import '../../../student/domain/entities/student_entity.dart';
import '../../../student/presentation/cubit/student_cubit.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_cubit.dart';
import '../cubit/certificate_issue_cubit.dart';
import '../widgets/competency_form_fields.dart';

// TODO: move to env config
const String kVerificationBaseUrl = 'https://vernonedu.com/sertifikat';
// TODO: read from course config
const int kPassingScore = 70;
const int _kMinScore = 0;
const int _kMaxScore = 100;

class IssueCompetencyPage extends StatelessWidget {
  const IssueCompetencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<StudentCubit>()..loadStudents()),
        BlocProvider(create: (_) => getIt<CourseCubit>()..loadCourses()),
        BlocProvider(create: (_) => getIt<CourseBatchCubit>()..loadBatches()),
        BlocProvider(create: (_) => getIt<CertificateCubit>()..loadAll()),
        BlocProvider(create: (_) => getIt<CertificateIssueCubit>()),
      ],
      child: const _IssueCompetencyView(),
    );
  }
}

class _IssueCompetencyView extends StatefulWidget {
  const _IssueCompetencyView();

  @override
  State<_IssueCompetencyView> createState() => _IssueCompetencyViewState();
}

class _IssueCompetencyViewState extends State<_IssueCompetencyView> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();

  StudentEntity? _selectedStudent;
  CourseEntity? _selectedCourse;
  CourseBatchEntity? _selectedBatch;
  String? _selectedTemplateId;
  DateTime _testDate = DateTime.now();
  int _score = 0;

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  bool get _passed => _score >= kPassingScore;

  bool get _canSubmit =>
      _selectedStudent != null &&
      _selectedCourse != null &&
      _selectedTemplateId != null &&
      _passed;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _testDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _testDate = picked);
  }

  Future<bool> _confirm(CertificateTemplateEntity template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Penerbitan'),
        content: Text(
          'Terbitkan sertifikat kompetensi untuk:\n\n'
          '• Siswa: ${_selectedStudent!.name}\n'
          '• Course: ${_selectedCourse!.courseName}\n'
          '• Batch: ${_selectedBatch?.code ?? "-"}\n'
          '• Template: ${template.name}\n'
          '• Skor: $_score (Lulus)\n\n'
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
        content: Text(state.message),
      ));
      _resetForm();
      ctx.read<CertificateIssueCubit>().reset();
    } else if (state is CertificateIssueError) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(state.message),
      ));
      ctx.read<CertificateIssueCubit>().reset();
    }
  }

  void _resetForm() {
    setState(() {
      _selectedStudent = null;
      _selectedCourse = null;
      _selectedBatch = null;
      _selectedTemplateId = null;
      _score = 0;
      _scoreController.clear();
      _testDate = DateTime.now();
    });
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final certState = context.read<CertificateCubit>().state;
    if (certState is! CertificateLoaded) return;
    final template = certState.templates
        .firstWhere((t) => t.id == _selectedTemplateId);
    if (!await _confirm(template) || !mounted) return;
    await context.read<CertificateIssueCubit>().issueCompetency(
          studentId: _selectedStudent!.id,
          courseId: _selectedCourse!.id,
          batchId: _selectedBatch?.id,
          templateId: _selectedTemplateId,
          testPassed: _passed,
          verificationBaseUrl: kVerificationBaseUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateIssueCubit, CertificateIssueState>(
      listener: _onIssueStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar:
            AppBar(title: const Text('Terbitkan Sertifikat Kompetensi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: AppDimensions.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Form(key: _formKey, child: _buildFormBody()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentAutocompleteField(
          selected: _selectedStudent,
          onSelected: (s) => setState(() => _selectedStudent = s),
        ),
        const SizedBox(height: AppDimensions.md),
        CourseDropdownField(
          selected: _selectedCourse,
          onChanged: (v) => setState(() {
            _selectedCourse = v;
            _selectedBatch = null;
          }),
        ),
        const SizedBox(height: AppDimensions.md),
        BatchOptionalField(
          course: _selectedCourse,
          selected: _selectedBatch,
          onChanged: (v) => setState(() => _selectedBatch = v),
        ),
        const SizedBox(height: AppDimensions.md),
        CompetencyTemplateField(
          selectedTemplateId: _selectedTemplateId,
          onChanged: (v) => setState(() => _selectedTemplateId = v),
        ),
        const SizedBox(height: AppDimensions.md),
        _buildScoreField(),
        const SizedBox(height: AppDimensions.md),
        _buildDateField(),
        const SizedBox(height: AppDimensions.md),
        PassedIndicator(passed: _passed, passingScore: kPassingScore),
        const SizedBox(height: AppDimensions.lg),
        _SubmitButton(enabled: _canSubmit, onPressed: _onSubmit),
      ],
    );
  }

  Widget _buildScoreField() {
    return TextFormField(
      key: const Key('score-field'),
      controller: _scoreController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Skor Tes (0-100)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.grade),
      ),
      onChanged: (v) => setState(() => _score = int.tryParse(v) ?? 0),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null) return 'Skor wajib diisi';
        if (n < _kMinScore || n > _kMaxScore) return 'Skor 0-100';
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal Tes',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_testDate.year}-${_testDate.month.toString().padLeft(2, '0')}-${_testDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final Future<void> Function() onPressed;
  const _SubmitButton({required this.enabled, required this.onPressed});

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
                : 'Terbitkan Sertifikat Kompetensi'),
          ),
        );
      },
    );
  }
}
