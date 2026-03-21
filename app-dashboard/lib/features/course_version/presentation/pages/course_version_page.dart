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

  // Dialog to create a new version
  void _showCreateVersionDialog(
      BuildContext context, String typeId, List<CourseVersionEntity> existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseVersionCubit>(),
        child: _CreateVersionDialog(
          typeId: typeId,
          typeName: typeName,
          existingVersions: existing,
        ),
      ),
    );
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
                // Action button based on status
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

  void _showInternshipForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseVersionCubit>(),
        child: _InternshipConfigDialog(
          versionId: versionId,
          existing: config,
        ),
      ),
    );
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

  void _showCharacterTestForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseVersionCubit>(),
        child: _CharacterTestConfigDialog(
          versionId: versionId,
          existing: config,
        ),
      ),
    );
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

// ─── Internship Config Dialog ─────────────────────────────────────────────────

class _InternshipConfigDialog extends StatefulWidget {
  final String versionId;
  final InternshipConfigEntity? existing;

  const _InternshipConfigDialog({
    required this.versionId,
    required this.existing,
  });

  @override
  State<_InternshipConfigDialog> createState() =>
      _InternshipConfigDialogState();
}

class _InternshipConfigDialogState extends State<_InternshipConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _supervisorNameCtrl;
  late final TextEditingController _supervisorContactCtrl;
  late final TextEditingController _mouUrlCtrl;
  bool _isCompanyProvided = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _companyCtrl =
        TextEditingController(text: e?.partnerCompanyName ?? '');
    _positionCtrl =
        TextEditingController(text: e?.positionTitle ?? '');
    _durationCtrl =
        TextEditingController(text: e != null ? '${e.durationWeeks}' : '');
    _supervisorNameCtrl =
        TextEditingController(text: e?.supervisorName ?? '');
    _supervisorContactCtrl =
        TextEditingController(text: e?.supervisorContact ?? '');
    _mouUrlCtrl = TextEditingController(text: e?.mouDocumentUrl ?? '');
    _isCompanyProvided = e?.isCompanyProvided ?? false;
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _durationCtrl.dispose();
    _supervisorNameCtrl.dispose();
    _supervisorContactCtrl.dispose();
    _mouUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final success = await context.read<CourseVersionCubit>().saveInternshipConfig(
        widget.versionId,
        {
          'partner_company_name': _companyCtrl.text.trim(),
          'position_title': _positionCtrl.text.trim(),
          'duration_weeks': int.tryParse(_durationCtrl.text.trim()) ?? 0,
          'supervisor_name': _supervisorNameCtrl.text.trim(),
          'supervisor_contact': _supervisorContactCtrl.text.trim(),
          'mou_document_url': _mouUrlCtrl.text.trim(),
          'is_company_provided': _isCompanyProvided,
        },
      );
      if (success && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfigurasi Magang',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan Mitra'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _positionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Posisi / Jabatan'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _durationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Durasi Magang (minggu)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(v) == null) return 'Masukkan angka';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _supervisorNameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Supervisor'),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _supervisorContactCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Kontak Supervisor'),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _mouUrlCtrl,
                  decoration:
                      const InputDecoration(labelText: 'URL Dokumen MOU'),
                ),
                const SizedBox(height: AppDimensions.sm),
                // Toggle: is_company_provided
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Disediakan oleh Perusahaan',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _isCompanyProvided,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isCompanyProvided = v),
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Character Test Config Dialog ─────────────────────────────────────────────

class _CharacterTestConfigDialog extends StatefulWidget {
  final String versionId;
  final CharacterTestConfigEntity? existing;

  const _CharacterTestConfigDialog({
    required this.versionId,
    required this.existing,
  });

  @override
  State<_CharacterTestConfigDialog> createState() =>
      _CharacterTestConfigDialogState();
}

class _CharacterTestConfigDialogState
    extends State<_CharacterTestConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerCtrl;
  late final TextEditingController _thresholdCtrl;
  String _testType = 'MBTI';
  bool _talentpoolEligible = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _testType = e?.testType.toUpperCase() ?? 'MBTI';
    _providerCtrl = TextEditingController(text: e?.testProvider ?? '');
    _thresholdCtrl = TextEditingController(
        text: e != null ? e.passingThreshold.toStringAsFixed(0) : '');
    _talentpoolEligible = e?.talentpoolEligible ?? false;
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final success =
          await context.read<CourseVersionCubit>().saveCharacterTestConfig(
        widget.versionId,
        {
          'test_type': _testType,
          'test_provider': _providerCtrl.text.trim(),
          'passing_threshold':
              double.tryParse(_thresholdCtrl.text.trim()) ?? 0.0,
          'talentpool_eligible': _talentpoolEligible,
        },
      );
      if (success && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfigurasi Tes Karakter',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppDimensions.md),
                DropdownButtonFormField<String>(
                  value: _testType,
                  decoration: const InputDecoration(labelText: 'Jenis Tes'),
                  items: const [
                    DropdownMenuItem(value: 'MBTI', child: Text('MBTI Test')),
                    DropdownMenuItem(
                        value: 'DISC', child: Text('DISC Assessment')),
                    DropdownMenuItem(
                        value: 'custom', child: Text('Custom Test')),
                  ],
                  onChanged: (v) => setState(() => _testType = v ?? 'MBTI'),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _providerCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Penyelenggara Tes'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _thresholdCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nilai Minimal Lulus (%)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(v) == null) return 'Masukkan angka';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.sm),
                // Toggle: talentpool_eligible
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Eligible untuk Talent Pool',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _talentpoolEligible,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _talentpoolEligible = v),
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Create Version Dialog ────────────────────────────────────────────────────

class _CreateVersionDialog extends StatefulWidget {
  final String typeId;
  final String? typeName;
  final List<CourseVersionEntity> existingVersions;

  const _CreateVersionDialog({
    required this.typeId,
    required this.existingVersions,
    this.typeName,
  });

  @override
  State<_CreateVersionDialog> createState() => _CreateVersionDialogState();
}

class _CreateVersionDialogState extends State<_CreateVersionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _versionCtrl;
  late final TextEditingController _changelogCtrl;
  String _changeType = 'minor';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto-increment version from last known version
    _versionCtrl = TextEditingController(text: _autoNextVersion());
    _changelogCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    _changelogCtrl.dispose();
    super.dispose();
  }

  // Calculate next version number from the most recent existing version
  String _autoNextVersion() {
    if (widget.existingVersions.isEmpty) return '1.0.0';
    final sorted = [...widget.existingVersions]
      ..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
    final last = sorted.first.versionNumber.split('.');
    if (last.length == 3) {
      final major = int.tryParse(last[0]) ?? 1;
      final minor = int.tryParse(last[1]) ?? 0;
      final patch = int.tryParse(last[2]) ?? 0;
      return '$major.${minor + 1}.$patch';
    }
    return '1.0.0';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final success = await context.read<CourseVersionCubit>().createVersion(
        widget.typeId,
        {
          'version_number': _versionCtrl.text.trim(),
          'change_type': _changeType,
          'changelog': _changelogCtrl.text.trim(),
        },
        typeName: widget.typeName,
      );
      if (success && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Versi Baru',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _versionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Versi (contoh: 2.1.0)',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nomor versi wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                DropdownButtonFormField<String>(
                  value: _changeType,
                  decoration:
                      const InputDecoration(labelText: 'Jenis Perubahan'),
                  items: const [
                    DropdownMenuItem(
                        value: 'major',
                        child: Text('Major — perubahan besar')),
                    DropdownMenuItem(
                        value: 'minor', child: Text('Minor — fitur baru')),
                    DropdownMenuItem(
                        value: 'patch',
                        child: Text('Patch — perbaikan kecil')),
                  ],
                  onChanged: (v) => setState(() => _changeType = v ?? 'minor'),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _changelogCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Changelog / Catatan Perubahan'),
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Changelog wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _loading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Buat Versi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
