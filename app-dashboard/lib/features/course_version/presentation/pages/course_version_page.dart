import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../domain/entities/course_version_entity.dart';
import '../../domain/entities/internship_config_entity.dart';
import '../../domain/entities/character_test_config_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/course_version_cubit.dart';
import '../cubit/course_version_state.dart';

// Page displaying CourseType detail with version list.
// Breadcrumb: Course > [courseName] > [typeName]
class CourseVersionPage extends StatelessWidget {
  final String typeId;

  const CourseVersionPage({super.key, required this.typeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // typeName is unknown at this point — the view loads it asynchronously
      // and calls loadVersions again with typeName once the detail is fetched
      create: (_) => getIt<CourseVersionCubit>()..loadVersions(typeId),
      child: _CourseVersionView(typeId: typeId),
    );
  }
}

class _CourseVersionView extends StatefulWidget {
  final String typeId;
  const _CourseVersionView({required this.typeId});

  @override
  State<_CourseVersionView> createState() => _CourseVersionViewState();
}

class _CourseVersionViewState extends State<_CourseVersionView> {
  late final Future<_TypeDetail> _typeFuture;
  bool _configsLoaded = false;

  @override
  void initState() {
    super.initState();
    _typeFuture = _loadTypeDetail();
  }

  // Load course type detail from API to display in header and drive config visibility
  Future<_TypeDetail> _loadTypeDetail() async {
    try {
      final res = await getIt<ApiClient>().dio.get('/api/v1/curriculum/types/${widget.typeId}');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      final detail = _TypeDetail.fromJson(json);

      // Reload versions with typeName so cubit can fetch configs for program_karir
      if (!_configsLoaded && mounted) {
        _configsLoaded = true;
        context.read<CourseVersionCubit>().loadVersions(widget.typeId, typeName: detail.typeName);
      }

      return detail;
    } catch (_) {
      return _TypeDetail(
        typeName: 'course_type',
        isActive: true,
        priceDisplay: '—',
        targetAudience: '',
        certificationType: '',
        extraDocs: [],
        masterCourseId: '',
        courseName: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TypeDetail>(
      future: _typeFuture,
      builder: (context, snap) {
        final typeDetail = snap.data;
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb: Course > [courseName] > [typeName]
              _Breadcrumb(
                courseId: typeDetail?.masterCourseId ?? '',
                courseName: typeDetail?.courseName ?? 'Course',
                typeName: typeDetail?.typeLabel ?? widget.typeId,
              ),
              const SizedBox(height: AppDimensions.md),

              // Header: type badge + active status
              if (typeDetail != null) _TypeHeader(detail: typeDetail),
              const SizedBox(height: AppDimensions.lg),

              // Main content
              Expanded(
                child: BlocConsumer<CourseVersionCubit, CourseVersionState>(
                  listener: (context, state) {
                    if (state is CourseVersionError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is CourseVersionLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is CourseVersionError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<CourseVersionCubit>()
                            .loadVersions(widget.typeId, typeName: typeDetail?.typeName),
                      );
                    }
                    if (state is CourseVersionLoaded) {
                      final isProgramKarir = typeDetail?.typeName == 'program_karir';
                      return _LoadedContent(
                        versions: state.versions,
                        typeId: widget.typeId,
                        typeName: typeDetail?.typeName,
                        isProgramKarir: isProgramKarir,
                        internshipConfig: state.internshipConfig,
                        characterTestConfig: state.characterTestConfig,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Loaded Content ───────────────────────────────────────────────────────────

class _LoadedContent extends StatelessWidget {
  final List<CourseVersionEntity> versions;
  final String typeId;
  final String? typeName;
  final bool isProgramKarir;
  final InternshipConfigEntity? internshipConfig;
  final CharacterTestConfigEntity? characterTestConfig;

  const _LoadedContent({
    required this.versions,
    required this.typeId,
    required this.typeName,
    required this.isProgramKarir,
    required this.internshipConfig,
    required this.characterTestConfig,
  });

  // Determine the version ID to bind configs to — prefer approved, else first
  String? get _configVersionId {
    if (versions.isEmpty) return null;
    final approved = versions.where((v) => v.isApproved).toList();
    return approved.isNotEmpty ? approved.first.id : versions.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version list section
          _VersionListSection(
            versions: versions,
            typeId: typeId,
            typeName: typeName,
          ),

          // Program Karir config sections
          if (isProgramKarir && _configVersionId != null) ...[
            const SizedBox(height: AppDimensions.lg),
            _InternshipConfigSection(
              versionId: _configVersionId!,
              config: internshipConfig,
            ),
            const SizedBox(height: AppDimensions.lg),
            _CharacterTestConfigSection(
              versionId: _configVersionId!,
              config: characterTestConfig,
            ),
            const SizedBox(height: AppDimensions.lg),
          ],
        ],
      ),
    );
  }
}

// ─── Breadcrumb ───────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  final String courseId;
  final String courseName;
  final String typeName;

  const _Breadcrumb({
    required this.courseId,
    required this.courseName,
    required this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/curriculum'),
          child: Text(
            'Course',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 14, color: AppColors.textHint),
        ),
        if (courseId.isNotEmpty) ...[
          InkWell(
            onTap: () => context.go('/curriculum/$courseId'),
            child: Text(
              courseName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right, size: 14, color: AppColors.textHint),
          ),
        ],
        Text(
          typeName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ─── Type Header ──────────────────────────────────────────────────────────────

class _TypeHeader extends StatelessWidget {
  final _TypeDetail detail;

  const _TypeHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Type name badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: Text(
                  detail.typeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              // Active status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: detail.isActive ? AppColors.successSurface : AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: Text(
                  detail.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: detail.isActive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          // Meta info chips
          Wrap(
            spacing: AppDimensions.lg,
            runSpacing: AppDimensions.xs,
            children: [
              _MetaChip(icon: Icons.payments_outlined, label: detail.priceDisplay),
              if (detail.certificationType.isNotEmpty)
                _MetaChip(
                    icon: Icons.workspace_premium_outlined,
                    label: detail.certificationType),
              if (detail.targetAudience.isNotEmpty)
                _MetaChip(
                    icon: Icons.people_outline,
                    label: detail.targetAudience),
              ...detail.extraDocs.map(
                (doc) => _MetaChip(icon: Icons.description_outlined, label: doc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Version List Section ─────────────────────────────────────────────────────

class _VersionListSection extends StatelessWidget {
  final List<CourseVersionEntity> versions;
  final String typeId;
  final String? typeName;

  const _VersionListSection({
    required this.versions,
    required this.typeId,
    this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header + add button
        Row(
          children: [
            const Icon(Icons.history_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Daftar Versi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: Text(
                '${versions.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showCreateVersionDialog(context, typeId, versions),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Versi Baru'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        // Version list or empty state
        if (versions.isEmpty)
          _EmptyVersionCard()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: versions.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.sm),
            itemBuilder: (context, i) => _VersionCard(
              version: versions[i],
              typeId: typeId,
              typeName: typeName,
            ),
          ),
      ],
    );
  }

  // Navigate to create-version page
  Future<void> _showCreateVersionDialog(
      BuildContext context, String typeId, List<CourseVersionEntity> existing) async {
    final created = await context.push<bool>(
      '/curriculum/types/$typeId/versions/new',
      extra: existing,
    );
    if (created == true && context.mounted) {
      context.read<CourseVersionCubit>().loadVersions(typeId, typeName: typeName);
    }
  }
}

// ─── Version Card ─────────────────────────────────────────────────────────────

class _VersionCard extends StatelessWidget {
  final CourseVersionEntity version;
  final String typeId;
  final String? typeName;

  const _VersionCard({
    required this.version,
    required this.typeId,
    this.typeName,
  });

  Color get _statusColor => switch (version.status) {
        'draft' => AppColors.textSecondary,
        'review' => AppColors.warning,
        'approved' => AppColors.success,
        'archived' => AppColors.textHint,
        _ => AppColors.textSecondary,
      };

  Color get _statusSurface => switch (version.status) {
        'draft' => AppColors.surfaceVariant,
        'review' => AppColors.warningSurface,
        'approved' => AppColors.successSurface,
        'archived' => AppColors.surfaceVariant,
        _ => AppColors.surfaceVariant,
      };

  String get _statusLabel => switch (version.status) {
        'draft' => 'Draft',
        'review' => 'Review',
        'approved' => 'Approved',
        'archived' => 'Archived',
        _ => version.status,
      };

  String get _changeTypeLabel => switch (version.changeType) {
        'major' => 'Major',
        'minor' => 'Minor',
        'patch' => 'Patch',
        _ => version.changeType,
      };

  Color get _changeTypeColor => switch (version.changeType) {
        'major' => AppColors.error,
        'minor' => AppColors.info,
        'patch' => AppColors.secondary,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/curriculum/versions/${version.id}'),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Version number — bold
                Text(
                  'v${version.versionNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(width: AppDimensions.sm),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusSurface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                // Change type chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _changeTypeColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                    border: Border.all(
                        color: _changeTypeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _changeTypeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _changeTypeColor,
                    ),
                  ),
                ),
                const Spacer(),
                // Approval workflow button — visible to dept_leader when version
                // has approval_status = 'submitted'. Uses the new /approve endpoint.
                _ApprovalDecisionButtons(
                  version: version,
                  typeId: typeId,
                  typeName: typeName,
                ),
                // Action button based on lifecycle status (legacy promote flow)
                _VersionActionButton(
                  version: version,
                  typeId: typeId,
                  typeName: typeName,
                ),
              ],
            ),
            if (version.changelog.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.xs),
              Text(
                version.changelog,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppDimensions.xs),
            // Created / approved dates
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 11, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Dibuat: ${DateFormatUtil.toDisplay(version.createdAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
                if (version.approvedAt != null) ...[
                  const SizedBox(width: AppDimensions.md),
                  const Icon(Icons.check_circle_outline,
                      size: 11, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Approved: ${DateFormatUtil.toDisplay(version.approvedAt!)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.success),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Version Action Button ────────────────────────────────────────────────────

class _VersionActionButton extends StatelessWidget {
  final CourseVersionEntity version;
  final String typeId;
  final String? typeName;

  const _VersionActionButton({
    required this.version,
    required this.typeId,
    this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    if (version.isDraft) {
      return OutlinedButton(
        onPressed: () async {
          final confirmed = await _showConfirmDialog(
            context,
            title: 'Kirim untuk Review',
            message:
                'Apakah Anda yakin ingin mengirim v${version.versionNumber} untuk direview?',
          );
          if (confirmed && context.mounted) {
            context
                .read<CourseVersionCubit>()
                .promoteVersion(version.id, 'review', typeId, typeName: typeName);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.warning,
          side: BorderSide(color: AppColors.warning.withOpacity(0.5)),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Kirim Review', style: TextStyle(fontSize: 12)),
      );
    }
    if (version.isReview) {
      return FilledButton(
        onPressed: () async {
          final confirmed = await _showConfirmDialog(
            context,
            title: 'Approve Versi',
            message:
                'Approve v${version.versionNumber}? Versi ini akan menjadi versi aktif.',
          );
          if (confirmed && context.mounted) {
            context
                .read<CourseVersionCubit>()
                .promoteVersion(version.id, 'approved', typeId, typeName: typeName);
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Approve', style: TextStyle(fontSize: 12)),
      );
    }
    if (version.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.successSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 13, color: AppColors.success),
            SizedBox(width: 4),
            Text(
              'Aktif',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<bool> _showConfirmDialog(
      BuildContext context,
      {required String title,
      required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─── Internship Config Section ────────────────────────────────────────────────

class _InternshipConfigSection extends StatelessWidget {
  final String versionId;
  final InternshipConfigEntity? config;

  const _InternshipConfigSection({
    required this.versionId,
    required this.config,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.business_center_outlined,
                  size: AppDimensions.iconMd, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Konfigurasi Magang',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showInternshipForm(context),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Config display or empty state
          if (config == null || config!.isEmpty)
            _ConfigEmptyState(
              label: 'Belum ada konfigurasi magang',
              onAdd: () => _showInternshipForm(context),
            )
          else
            _InternshipConfigDetail(config: config!),
        ],
      ),
    );
  }

  Future<void> _showInternshipForm(BuildContext context) async {
    final saved = await context.push<bool>(
      '/curriculum/versions/$versionId/internship-config',
      extra: config,
    );
    if (saved == true && context.mounted) {
      // Re-fetch configs after save — use loadConfigs for targeted refresh
      context.read<CourseVersionCubit>().loadConfigs(versionId);
    }
  }
}

class _InternshipConfigDetail extends StatelessWidget {
  final InternshipConfigEntity config;
  const _InternshipConfigDetail({required this.config});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.xl,
      runSpacing: AppDimensions.sm,
      children: [
        _ConfigField(
          label: 'Perusahaan Mitra',
          value: config.partnerCompanyName.isNotEmpty
              ? config.partnerCompanyName
              : '—',
        ),
        _ConfigField(label: 'Posisi / Jabatan', value: config.positionTitle),
        _ConfigField(
          label: 'Durasi Magang',
          value: '${config.durationWeeks} minggu',
        ),
        _ConfigField(
          label: 'Nama Supervisor',
          value: config.supervisorName.isNotEmpty ? config.supervisorName : '—',
        ),
        _ConfigField(
          label: 'Kontak Supervisor',
          value: config.supervisorContact.isNotEmpty
              ? config.supervisorContact
              : '—',
        ),
        _ConfigField(
          label: 'Dokumen MOU',
          value: config.mouDocumentUrl.isNotEmpty ? config.mouDocumentUrl : '—',
        ),
        _ConfigField(
          label: 'Disediakan Perusahaan',
          value: config.isCompanyProvided ? 'Ya' : 'Tidak',
        ),
      ],
    );
  }
}

// ─── Character Test Config Section ───────────────────────────────────────────

class _CharacterTestConfigSection extends StatelessWidget {
  final String versionId;
  final CharacterTestConfigEntity? config;

  const _CharacterTestConfigSection({
    required this.versionId,
    required this.config,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: AppDimensions.iconMd, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Konfigurasi Tes Karakter',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showCharacterTestForm(context),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Config display or empty state
          if (config == null || config!.isEmpty)
            _ConfigEmptyState(
              label: 'Belum ada konfigurasi tes karakter',
              onAdd: () => _showCharacterTestForm(context),
            )
          else
            _CharacterTestConfigDetail(config: config!),
        ],
      ),
    );
  }

  Future<void> _showCharacterTestForm(BuildContext context) async {
    final saved = await context.push<bool>(
      '/curriculum/versions/$versionId/character-test-config',
      extra: config,
    );
    if (saved == true && context.mounted) {
      // Re-fetch configs after save — use loadConfigs for targeted refresh
      context.read<CourseVersionCubit>().loadConfigs(versionId);
    }
  }
}

class _CharacterTestConfigDetail extends StatelessWidget {
  final CharacterTestConfigEntity config;
  const _CharacterTestConfigDetail({required this.config});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.xl,
      runSpacing: AppDimensions.sm,
      children: [
        _ConfigField(label: 'Jenis Tes', value: config.testTypeLabel),
        _ConfigField(
          label: 'Penyelenggara Tes',
          value: config.testProvider.isNotEmpty ? config.testProvider : '—',
        ),
        _ConfigField(
          label: 'Nilai Minimal Lulus',
          value: '${config.passingThreshold.toStringAsFixed(0)}%',
        ),
        _ConfigField(
          label: 'Kelayakan Talent Pool',
          value: config.talentpoolEligible ? 'Ya' : 'Tidak',
        ),
      ],
    );
  }
}

// ─── Shared Config Widgets ────────────────────────────────────────────────────

class _ConfigField extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ConfigEmptyState extends StatelessWidget {
  final String label;
  final VoidCallback onAdd;

  const _ConfigEmptyState({required this.label, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
        const SizedBox(width: AppDimensions.xs),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppDimensions.sm),
        TextButton(
          onPressed: onAdd,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Tambah Sekarang', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

// ─── Internship Config Dialog (removed — now a separate page) ──────────────

// ─── Character Test Config Dialog (removed — now a separate page) ──────────

// ─── Create Version Dialog (removed — now a separate page) ────────────────

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _EmptyVersionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Belum ada versi untuk tipe ini',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.sm),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

// ─── Approval Decision Buttons (dept_leader, approval_status = submitted) ───

class _ApprovalDecisionButtons extends StatelessWidget {
  final CourseVersionEntity version;
  final String typeId;
  final String? typeName;

  const _ApprovalDecisionButtons({
    required this.version,
    required this.typeId,
    this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    if (!version.isApprovalSubmitted) return const SizedBox.shrink();

    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    if (!authState.user.hasRole(UserRole.deptLeader)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            key: const Key('approval-reject-btn'),
            onPressed: () => _onReject(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Tolak', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: AppDimensions.xs),
          FilledButton(
            key: const Key('approval-approve-btn'),
            onPressed: () => _onApprove(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Setujui', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _onApprove(BuildContext context) async {
    final cubit = context.read<CourseVersionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Setujui Versi'),
        content: Text(
            'Setujui v${version.versionNumber}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await cubit.approveVersion(version.id, typeId, typeName: typeName);
    if (ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Versi berhasil disetujui'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _onReject(BuildContext context) async {
    final cubit = context.read<CourseVersionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );
    if (reason == null || reason.trim().isEmpty) return;
    final ok = await cubit.rejectVersion(version.id, typeId,
        reason: reason.trim(), typeName: typeName);
    if (ok) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Versi telah ditolak'),
        backgroundColor: AppColors.warning,
      ));
    }
  }
}

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'Alasan wajib diisi');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak Versi'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Alasan penolakan',
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}

// ─── Data model for type detail ───────────────────────────────────────────────

class _TypeDetail {
  final String typeName;
  final bool isActive;
  final String priceDisplay;
  final String targetAudience;
  final String certificationType;
  final List<String> extraDocs;
  final String masterCourseId;
  final String courseName;

  const _TypeDetail({
    required this.typeName,
    required this.isActive,
    required this.priceDisplay,
    required this.targetAudience,
    required this.certificationType,
    required this.extraDocs,
    required this.masterCourseId,
    required this.courseName,
  });

  // Human-readable type label
  String get typeLabel => switch (typeName) {
        'regular' => 'Regular',
        'private' => 'Private',
        'company_training' => 'Company Training',
        'collab_university' => 'Kolaborasi Universitas',
        'collab_school' => 'Kolaborasi Sekolah',
        'program_karir' => 'Program Karir',
        _ => typeName,
      };

  factory _TypeDetail.fromJson(Map<String, dynamic> json) {
    final priceType = json['price_type'] as String? ?? 'by_request';
    final priceCurrency = json['price_currency'] as String? ?? 'IDR';
    final priceMin = json['price_min'] as int?;
    final priceMax = json['price_max'] as int?;
    final priceNotes = json['price_notes'] as String? ?? '';

    String priceDisplay;
    if (priceType == 'by_request') {
      priceDisplay = 'Hubungi Kami';
    } else if (priceType == 'fixed' && priceMin != null) {
      priceDisplay = '$priceCurrency ${_fmt(priceMin)}';
    } else if (priceType == 'range' && priceMin != null && priceMax != null) {
      priceDisplay = '$priceCurrency ${_fmt(priceMin)} – ${_fmt(priceMax)}';
    } else {
      priceDisplay = priceNotes.isNotEmpty ? priceNotes : '—';
    }

    return _TypeDetail(
      typeName: json['type_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      priceDisplay: priceDisplay,
      targetAudience: json['target_audience'] as String? ?? '',
      certificationType: json['certification_type'] as String? ?? '',
      extraDocs:
          (json['extra_docs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      masterCourseId: json['master_course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
    );
  }

  static String _fmt(int n) => n
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
