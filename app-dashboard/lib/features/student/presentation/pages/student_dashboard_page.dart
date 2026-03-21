import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/student_detail_entity.dart';
import '../../domain/entities/student_enrollment_history_entity.dart';
import '../../domain/entities/student_note_entity.dart';
import '../../domain/entities/recommended_course_entity.dart';
import '../../domain/entities/student_crm_log_entity.dart';
import '../../../talentpool/domain/entities/talentpool_entity.dart';
import '../cubit/student_dashboard_cubit.dart';
import '../cubit/student_dashboard_state.dart';

class StudentDashboardPage extends StatelessWidget {
  final String studentId;

  const StudentDashboardPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<StudentDashboardCubit>()..loadDashboard(studentId),
      child: _StudentDashboardView(studentId: studentId),
    );
  }
}

class _StudentDashboardView extends StatelessWidget {
  final String studentId;

  const _StudentDashboardView({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentDashboardCubit, StudentDashboardState>(
      listener: (context, state) {
        if (state is StudentDashboardError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<StudentDashboardCubit, StudentDashboardState>(
        builder: (context, state) {
          if (state is StudentDashboardLoading ||
              state is StudentDashboardInitial) {
            return _buildLoading();
          }
          if (state is StudentDashboardError) {
            return _buildError(context, state.message);
          }
          if (state is StudentDashboardLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          FilledButton.icon(
            onPressed: () => context
                .read<StudentDashboardCubit>()
                .loadDashboard(studentId),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, StudentDashboardLoaded state) {
    final cubit = context.read<StudentDashboardCubit>();
    showDialog(
      context: context,
      builder: (_) => _EditStudentDialog(
        student: state.student,
        onUpdate: ({required name, required email, required phone}) =>
            cubit.updateStudent(studentId, name: name, email: email, phone: phone),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StudentDashboardLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            studentName: state.student.name,
            onEdit: state.isUpdating ? null : () => _showEditDialog(context, state),
          ),
          const SizedBox(height: AppDimensions.lg),
          _StudentInfoCard(student: state.student),
          const SizedBox(height: AppDimensions.lg),
          _StatsRow(
            student: state.student,
            enrollmentHistory: state.enrollmentHistory,
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _EnrollmentHistorySection(
                        enrollments: state.enrollmentHistory),
                    const SizedBox(height: AppDimensions.lg),
                    _RecommendationsSection(
                        recommendations: state.recommendations),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _TalentPoolSection(talentPool: state.talentPool),
                    const SizedBox(height: AppDimensions.lg),
                    _NotesSection(
                      studentId: studentId,
                      notes: state.notes,
                      isAdding: state.isAddingNote,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          _CrmLogSection(
            studentId: studentId,
            crmLogs: state.crmLogs,
            isAdding: state.isAddingCrmLog,
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String studentName;
  final VoidCallback? onEdit;

  const _TopBar({required this.studentName, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
          tooltip: AppStrings.back,
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Siswa',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                studentName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: AppDimensions.iconMd),
          label: const Text('Edit'),
        ),
      ],
    );
  }
}

// ── Student Info Card ─────────────────────────────────────────────────────────

class _StudentInfoCard extends StatelessWidget {
  final StudentDetailEntity student;

  const _StudentInfoCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: AppDimensions.lg),
          Expanded(child: _buildInfo(context)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        student.initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              student.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: AppDimensions.sm),
            _StatusBadge(isActive: student.isActive),
          ],
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          student.email,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.md),
        Wrap(
          spacing: AppDimensions.xl,
          runSpacing: AppDimensions.sm,
          children: [
            _InfoItem(
                icon: Icons.phone_outlined,
                label: 'Telepon',
                value: student.phone.isEmpty ? '-' : student.phone),
            _InfoItem(
                icon: Icons.business_outlined,
                label: 'Departemen',
                value: student.departmentName.isEmpty
                    ? '-'
                    : student.departmentName),
            _InfoItem(
                icon: Icons.calendar_today_outlined,
                label: 'Bergabung',
                value: DateFormat('dd MMM yyyy', 'id_ID')
                    .format(student.joinedAt)),
            if (student.gender != null && student.gender!.isNotEmpty)
              _InfoItem(
                  icon: Icons.person_outline,
                  label: 'Jenis Kelamin',
                  value: student.genderLabel),
            if (student.birthDate != null && student.birthDate!.isNotEmpty)
              _InfoItem(
                  icon: Icons.cake_outlined,
                  label: 'Tanggal Lahir',
                  value: student.birthDate!),
            if (student.address != null && student.address!.isNotEmpty)
              _InfoItem(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: student.address!),
            if (student.nik != null && student.nik!.isNotEmpty)
              _InfoItem(
                  icon: Icons.badge_outlined, label: 'NIK', value: student.nik!),
          ],
        ),
      ],
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final StudentDetailEntity student;
  final List<StudentEnrollmentHistoryEntity> enrollmentHistory;

  const _StatsRow({
    required this.student,
    required this.enrollmentHistory,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount =
        enrollmentHistory.where((e) => e.isCompleted).length;
    final activeCount = enrollmentHistory.where((e) => e.isActive).length;
    final avgAttendance = enrollmentHistory.isEmpty
        ? 0.0
        : enrollmentHistory
                .map((e) => e.attendanceRate)
                .reduce((a, b) => a + b) /
            enrollmentHistory.length;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.school_outlined,
            label: 'Total Course',
            value: '${enrollmentHistory.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            label: 'Selesai',
            value: '$completedCount',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            icon: Icons.play_circle_outline,
            label: 'Berjalan',
            value: '$activeCount',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            icon: Icons.event_available_outlined,
            label: 'Rata-rata Kehadiran',
            value: enrollmentHistory.isEmpty
                ? '-'
                : '${(avgAttendance * 100).toStringAsFixed(0)}%',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

// ── Enrollment History ────────────────────────────────────────────────────────

class _EnrollmentHistorySection extends StatelessWidget {
  final List<StudentEnrollmentHistoryEntity> enrollments;

  const _EnrollmentHistorySection({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.history_edu_outlined,
            title: 'Riwayat Course',
            subtitle: '${enrollments.length} course diambil',
          ),
          const SizedBox(height: AppDimensions.md),
          if (enrollments.isEmpty)
            _EmptyState(
              icon: Icons.school_outlined,
              message: 'Belum pernah mengambil course',
            )
          else
            ...enrollments.map((e) => _EnrollmentRow(enrollment: e)),
        ],
      ),
    );
  }
}

class _EnrollmentRow extends StatelessWidget {
  final StudentEnrollmentHistoryEntity enrollment;

  const _EnrollmentRow({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.masterCourseName.isNotEmpty
                          ? enrollment.masterCourseName
                          : enrollment.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${enrollment.batchCode} · ${enrollment.batchType}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _EnrollmentStatusBadge(status: enrollment.status),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              _EnrollmentMeta(
                icon: Icons.calendar_today_outlined,
                value: DateFormat('dd MMM yyyy', 'id_ID')
                    .format(enrollment.enrolledAt),
              ),
              const SizedBox(width: AppDimensions.md),
              _EnrollmentMeta(
                icon: Icons.event_available_outlined,
                value:
                    '${enrollment.totalAttendance}/${enrollment.totalSessions} sesi',
              ),
              const SizedBox(width: AppDimensions.md),
              if (enrollment.finalScore != null)
                _EnrollmentMeta(
                  icon: Icons.star_outline,
                  value:
                      'Nilai: ${enrollment.finalScore!.toStringAsFixed(1)}${enrollment.grade != null ? ' (${enrollment.grade})' : ''}',
                ),
              const Spacer(),
              _PaymentBadge(status: enrollment.paymentStatus),
            ],
          ),
          if (enrollment.totalSessions > 0) ...[
            const SizedBox(height: AppDimensions.sm),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusCircle),
              child: LinearProgressIndicator(
                value: enrollment.attendanceRate,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  enrollment.attendanceRate >= 0.8
                      ? AppColors.success
                      : enrollment.attendanceRate >= 0.6
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recommendations ───────────────────────────────────────────────────────────

class _RecommendationsSection extends StatelessWidget {
  final List<RecommendedCourseEntity> recommendations;

  const _RecommendationsSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.lightbulb_outline,
            title: 'Rekomendasi Course Berikutnya',
            subtitle: 'Berdasarkan histori dan profil siswa',
          ),
          const SizedBox(height: AppDimensions.md),
          if (recommendations.isEmpty)
            _EmptyState(
              icon: Icons.lightbulb_outline,
              message: 'Tidak ada rekomendasi saat ini',
            )
          else
            ...recommendations.map((r) => _RecommendationCard(course: r)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendedCourseEntity course;

  const _RecommendationCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(Icons.auto_stories,
                color: Colors.white, size: AppDimensions.iconMd),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.courseName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (course.hasActiveBatch)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.sm,
                            vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusCircle),
                        ),
                        child: const Text(
                          'Batch Tersedia',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  course.reason,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Talent Pool ───────────────────────────────────────────────────────────────

class _TalentPoolSection extends StatelessWidget {
  final TalentPoolEntity? talentPool;

  const _TalentPoolSection({this.talentPool});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.workspace_premium_outlined,
            title: 'Talent Pool',
          ),
          const SizedBox(height: AppDimensions.md),
          talentPool == null
              ? _EmptyState(
                  icon: Icons.workspace_premium_outlined,
                  message: 'Tidak terdaftar di talent pool',
                )
              : _TalentPoolDetail(talent: talentPool!),
        ],
      ),
    );
  }
}

class _TalentPoolDetail extends StatelessWidget {
  final TalentPoolEntity talent;

  const _TalentPoolDetail({required this.talent});

  @override
  Widget build(BuildContext context) {
    final placement = talent.placementHistory.isNotEmpty
        ? talent.placementHistory.last
        : null;
    final characterTest = talent.characterTestResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TalentStatusBadge(status: talent.talentpoolStatus),
            const Spacer(),
            Text(
              DateFormat('dd MMM yyyy', 'id_ID').format(talent.joinedAt),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        _InfoItem(
          icon: Icons.book_outlined,
          label: 'Course',
          value: talent.courseName,
        ),
        if (talent.testScore != null) ...[
          const SizedBox(height: AppDimensions.sm),
          _InfoItem(
            icon: Icons.grade_outlined,
            label: 'Penilaian Internal',
            value: talent.testScore!.toStringAsFixed(1),
          ),
        ],
        if (characterTest.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.md),
          Text(
            'Hasil Character Test',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.sm),
          _CharacterTestResult(result: characterTest),
        ],
        if (placement != null) ...[
          const SizedBox(height: AppDimensions.md),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Penempatan Terakhir',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.sm),
          if (placement['company'] != null)
            _InfoItem(
              icon: Icons.business,
              label: 'Perusahaan',
              value: placement['company'].toString(),
            ),
          if (placement['position'] != null) ...[
            const SizedBox(height: AppDimensions.xs),
            _InfoItem(
              icon: Icons.work_outline,
              label: 'Posisi',
              value: placement['position'].toString(),
            ),
          ],
        ],
        if (talent.placementHistory.length > 1) ...[
          const SizedBox(height: AppDimensions.sm),
          Text(
            '+ ${talent.placementHistory.length - 1} riwayat penempatan lainnya',
            style: const TextStyle(
                color: AppColors.primary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _CharacterTestResult extends StatelessWidget {
  final Map<String, dynamic> result;

  const _CharacterTestResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final entries = result.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .take(6)
        .toList();

    if (entries.isEmpty) {
      return const Text(
        'Belum ada hasil',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }

    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: entries.map((e) {
        final key = e.key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : '')
            .join(' ');
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
          decoration: BoxDecoration(
            color: AppColors.infoSurface,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          child: Text(
            '$key: ${e.value}',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.info,
                fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }
}

// ── Notes ─────────────────────────────────────────────────────────────────────

class _NotesSection extends StatefulWidget {
  final String studentId;
  final List<StudentNoteEntity> notes;
  final bool isAdding;

  const _NotesSection({
    required this.studentId,
    required this.notes,
    required this.isAdding,
  });

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  final _noteCtrl = TextEditingController();
  bool _showInput = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _noteCtrl.text.trim();
    if (content.isEmpty) return;

    final success = await context
        .read<StudentDashboardCubit>()
        .addNote(widget.studentId, content);

    if (success && mounted) {
      _noteCtrl.clear();
      setState(() => _showInput = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_outlined,
                  size: AppDimensions.iconMd, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'Catatan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showInput = !_showInput),
                icon: Icon(
                  _showInput ? Icons.close : Icons.add,
                  size: AppDimensions.iconMd,
                  color: AppColors.primary,
                ),
                tooltip: _showInput ? 'Batal' : 'Tambah catatan',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primarySurface,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          if (_showInput) ...[
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tulis catatan tentang siswa ini...',
                hintStyle: TextStyle(fontSize: 13),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppDimensions.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: widget.isAdding ? null : _submit,
                child: widget.isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(AppStrings.save),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.md),
          if (widget.notes.isEmpty && !_showInput)
            _EmptyState(
              icon: Icons.notes_outlined,
              message: 'Belum ada catatan',
            )
          else
            ...widget.notes.map((n) => _NoteItem(note: n)),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final StudentNoteEntity note;

  const _NoteItem({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  note.authorInitials,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  note.authorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.textPrimary),
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy · HH:mm', 'id_ID')
                    .format(note.createdAt.toLocal()),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            note.content,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconMd, color: AppColors.primary),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconMd),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color:
            isActive ? AppColors.successSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isActive ? AppStrings.active : AppStrings.inactive,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color:
              isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EnrollmentStatusBadge extends StatelessWidget {
  final String status;

  const _EnrollmentStatusBadge({required this.status});

  Color get _bg => switch (status) {
        'completed' => AppColors.successSurface,
        'active' => AppColors.infoSurface,
        'dropped' => AppColors.errorSurface,
        _ => AppColors.surfaceVariant,
      };

  Color get _fg => switch (status) {
        'completed' => AppColors.success,
        'active' => AppColors.info,
        'dropped' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'completed' => 'Selesai',
        'active' => 'Berjalan',
        'dropped' => 'Dropout',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        _label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _fg),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String status;

  const _PaymentBadge({required this.status});

  Color get _bg => switch (status) {
        'paid' => AppColors.successSurface,
        'pending' => AppColors.warningSurface,
        'failed' => AppColors.errorSurface,
        _ => AppColors.surfaceVariant,
      };

  Color get _fg => switch (status) {
        'paid' => AppColors.success,
        'pending' => AppColors.warning,
        'failed' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (status) {
        'paid' => 'Lunas',
        'pending' => 'Pending',
        'failed' => 'Gagal',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        _label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: _fg),
      ),
    );
  }
}

class _TalentStatusBadge extends StatelessWidget {
  final String status;

  const _TalentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'active' => (
          AppColors.infoSurface,
          AppColors.info,
          'Aktif di Talent Pool'
        ),
      'placed' => (
          AppColors.successSurface,
          AppColors.success,
          'Sudah Ditempatkan'
        ),
      'inactive' => (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
          'Nonaktif'
        ),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _EnrollmentMeta extends StatelessWidget {
  final IconData icon;
  final String value;

  const _EnrollmentMeta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          value,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ── Edit Student Dialog ───────────────────────────────────────────────────────

typedef UpdateStudentCallback = Future<bool> Function({
  required String name,
  required String email,
  required String phone,
});

class _EditStudentDialog extends StatefulWidget {
  final StudentDetailEntity student;
  final UpdateStudentCallback onUpdate;

  const _EditStudentDialog({required this.student, required this.onUpdate});

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _emailCtrl = TextEditingController(text: widget.student.email);
    _phoneCtrl = TextEditingController(text: widget.student.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await widget.onUpdate(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengupdate data siswa. Coba lagi.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Data Siswa'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

// ── CRM Log Section ───────────────────────────────────────────────────────────

class _CrmLogSection extends StatefulWidget {
  final String studentId;
  final List<StudentCrmLogEntity> crmLogs;
  final bool isAdding;

  const _CrmLogSection({
    required this.studentId,
    required this.crmLogs,
    required this.isAdding,
  });

  @override
  State<_CrmLogSection> createState() => _CrmLogSectionState();
}

class _CrmLogSectionState extends State<_CrmLogSection> {
  final _responseCtrl = TextEditingController();
  String _contactMethod = 'phone';
  bool _showInput = false;

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final response = _responseCtrl.text.trim();
    if (response.isEmpty) return;

    final success = await context.read<StudentDashboardCubit>().addCrmLog(
          widget.studentId,
          contactMethod: _contactMethod,
          response: response,
        );

    if (success && mounted) {
      _responseCtrl.clear();
      setState(() => _showInput = false);
    }
  }

  String _methodLabel(String method) => switch (method) {
        'phone' => 'Telepon',
        'whatsapp' => 'WhatsApp',
        'email' => 'Email',
        'visit' => 'Kunjungan',
        'sms' => 'SMS',
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_phone_outlined,
                  size: AppDimensions.iconMd, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log CRM',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      '${widget.crmLogs.length} catatan kontak',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showInput = !_showInput),
                icon: Icon(
                  _showInput ? Icons.close : Icons.add,
                  size: AppDimensions.iconMd,
                  color: AppColors.primary,
                ),
                tooltip: _showInput ? 'Batal' : 'Tambah log CRM',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primarySurface,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          if (_showInput) ...[
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _contactMethod,
                    decoration: const InputDecoration(
                      labelText: 'Metode Kontak',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['phone', 'whatsapp', 'email', 'visit', 'sms']
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(_methodLabel(m)),
                            ))
                        .toList(),
                    onChanged: widget.isAdding
                        ? null
                        : (v) =>
                            setState(() => _contactMethod = v ?? 'phone'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            TextField(
              controller: _responseCtrl,
              maxLines: 3,
              enabled: !widget.isAdding,
              decoration: const InputDecoration(
                hintText: 'Catatan hasil kontak...',
                hintStyle: TextStyle(fontSize: 13),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppDimensions.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: widget.isAdding ? null : _submit,
                child: widget.isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan'),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.md),
          if (widget.crmLogs.isEmpty && !_showInput)
            _EmptyState(
              icon: Icons.contact_phone_outlined,
              message: 'Belum ada log CRM',
            )
          else if (widget.crmLogs.isNotEmpty)
            // Table header
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 130,
                          child: Text(
                            'Tanggal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            'Contacted By',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            'Metode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Response',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ...widget.crmLogs.map((log) => _CrmLogRow(log: log)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CrmLogRow extends StatelessWidget {
  final StudentCrmLogEntity log;
  const _CrmLogRow({required this.log});

  String get _methodLabel => switch (log.contactMethod) {
        'phone' => 'Telepon',
        'whatsapp' => 'WhatsApp',
        'email' => 'Email',
        'visit' => 'Kunjungan',
        'sms' => 'SMS',
        _ => log.contactMethod,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              DateFormat('dd MMM yyyy', 'id_ID').format(log.date.toLocal()),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              log.contactedBy.isEmpty ? '-' : log.contactedBy,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.infoSurface,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: Text(
                _methodLabel,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info),
              ),
            ),
          ),
          Expanded(
            child: Text(
              log.response,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.sm),
            Text(
              message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
