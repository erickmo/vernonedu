import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/network/api_client.dart';
import '../../../course_module/domain/entities/course_module_entity.dart';
import '../../../course_module/presentation/cubit/course_module_cubit.dart';
import '../../../course_module/presentation/cubit/course_module_state.dart';

// Halaman detail CourseVersion yang menampilkan daftar modul
// Breadcrumb: Kurikulum > ... > v[versionNumber]
class CourseModulePage extends StatelessWidget {
  final String versionId;

  const CourseModulePage({super.key, required this.versionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CourseModuleCubit>()..loadModules(versionId),
      child: _CourseModuleView(versionId: versionId),
    );
  }
}

class _CourseModuleView extends StatefulWidget {
  final String versionId;
  const _CourseModuleView({required this.versionId});

  @override
  State<_CourseModuleView> createState() => _CourseModuleViewState();
}

class _CourseModuleViewState extends State<_CourseModuleView> {
  // Detail versi dimuat terpisah untuk header dan breadcrumb
  late final Future<_VersionDetail> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _loadVersionDetail();
  }

  Future<_VersionDetail> _loadVersionDetail() async {
    try {
      final res = await getIt<ApiClient>()
          .dio
          .get('/api/v1/curriculum/versions/${widget.versionId}');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return _VersionDetail.fromJson(json);
    } catch (_) {
      return _VersionDetail(
        versionNumber: '—',
        status: 'draft',
        typeId: '',
        typeName: '',
        courseId: '',
        courseName: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VersionDetail>(
      future: _versionFuture,
      builder: (context, snap) {
        final detail = snap.data;
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              _Breadcrumb(
                courseId: detail?.courseId ?? '',
                courseName: detail?.courseName ?? 'Course',
                typeId: detail?.typeId ?? '',
                typeName: detail?.typeName ?? 'Tipe',
                versionNumber: detail?.versionNumber ?? '—',
              ),
              const SizedBox(height: AppDimensions.md),

              // Header versi + status
              if (detail != null) _VersionHeader(detail: detail),
              const SizedBox(height: AppDimensions.lg),

              // Section modul
              Expanded(
                child: BlocConsumer<CourseModuleCubit, CourseModuleState>(
                  listener: (context, state) {
                    if (state is CourseModuleError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is CourseModuleLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is CourseModuleError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<CourseModuleCubit>()
                            .loadModules(widget.versionId),
                      );
                    }
                    if (state is CourseModuleLoaded) {
                      return _ModuleListSection(
                        modules: state.modules,
                        versionId: widget.versionId,
                        isReadonly: detail?.isApproved ?? false,
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

// ─── Breadcrumb ───────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  final String courseId;
  final String courseName;
  final String typeId;
  final String typeName;
  final String versionNumber;

  const _Breadcrumb({
    required this.courseId,
    required this.courseName,
    required this.typeId,
    required this.typeName,
    required this.versionNumber,
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
        _sep(),
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
          _sep(),
        ],
        if (typeId.isNotEmpty) ...[
          InkWell(
            onTap: () => context.go('/curriculum/types/$typeId'),
            child: Text(
              typeName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          _sep(),
        ],
        Text(
          'v$versionNumber',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _sep() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.chevron_right, size: 14, color: AppColors.textHint),
      );
}

// ─── Version Header ───────────────────────────────────────────────────────────

class _VersionHeader extends StatelessWidget {
  final _VersionDetail detail;

  const _VersionHeader({required this.detail});

  Color get _statusColor => switch (detail.status) {
        'draft' => AppColors.textSecondary,
        'review' => AppColors.warning,
        'approved' => AppColors.success,
        'archived' => AppColors.textHint,
        _ => AppColors.textSecondary,
      };

  Color get _statusSurface => switch (detail.status) {
        'draft' => AppColors.surfaceVariant,
        'review' => AppColors.warningSurface,
        'approved' => AppColors.successSurface,
        _ => AppColors.surfaceVariant,
      };

  String get _statusLabel => switch (detail.status) {
        'draft' => 'Draft',
        'review' => 'Review',
        'approved' => 'Approved',
        'archived' => 'Archived',
        _ => detail.status,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'v${detail.versionNumber}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          child: Text(
            _statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
        ),
        if (detail.isApproved) ...[
          const SizedBox(width: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 13, color: AppColors.info),
                SizedBox(width: 4),
                Text(
                  'Versi ini sudah diapprove — readonly',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Module List Section ──────────────────────────────────────────────────────

class _ModuleListSection extends StatelessWidget {
  final List<CourseModuleEntity> modules;
  final String versionId;
  final bool isReadonly;

  const _ModuleListSection({
    required this.modules,
    required this.versionId,
    required this.isReadonly,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section modul
        Row(
          children: [
            const Icon(Icons.list_alt_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Daftar Modul',
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
                '${modules.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            // Tombol tambah modul — disabled jika approved
            if (!isReadonly)
              FilledButton.icon(
                onPressed: () =>
                    _showModuleDialog(context, versionId, null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Tambah Modul'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),

        if (modules.isEmpty)
          _EmptyModuleCard(isReadonly: isReadonly)
        else
          Expanded(
            child: ListView.separated(
              itemCount: modules.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.sm),
              itemBuilder: (context, i) => _ModuleCard(
                module: modules[i],
                versionId: versionId,
                isReadonly: isReadonly,
              ),
            ),
          ),
      ],
    );
  }

  // Dialog untuk buat/edit modul
  void _showModuleDialog(BuildContext context, String versionId,
      CourseModuleEntity? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseModuleCubit>(),
        child: _ModuleDialog(
          versionId: versionId,
          existing: existing,
        ),
      ),
    );
  }
}

// ─── Module Card ─────────────────────────────────────────────────────────────

class _ModuleCard extends StatefulWidget {
  final CourseModuleEntity module;
  final String versionId;
  final bool isReadonly;

  const _ModuleCard({
    required this.module,
    required this.versionId,
    required this.isReadonly,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _expanded = false;

  // Warna contentDepth
  Color get _depthColor => switch (widget.module.contentDepth) {
        'intro' => AppColors.info,
        'standard' => AppColors.secondary,
        'advanced' => AppColors.warning,
        _ => AppColors.textSecondary,
      };

  Color get _depthSurface => switch (widget.module.contentDepth) {
        'intro' => AppColors.infoSurface,
        'standard' => AppColors.successSurface,
        'advanced' => AppColors.warningSurface,
        _ => AppColors.surfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Baris utama modul
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  // Nomor urut
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.module.sequence}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.module.moduleCode,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.module.moduleTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // contentDepth badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _depthSurface,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusCircle),
                              ),
                              child: Text(
                                widget.module.contentDepthLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _depthColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.schedule_outlined,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.module.durationHours} jam',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tombol aksi edit/hapus
                  if (!widget.isReadonly) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: AppDimensions.iconMd,
                          color: AppColors.textSecondary),
                      onPressed: () => _showEditDialog(context),
                      tooltip: 'Edit modul',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: AppDimensions.iconMd, color: AppColors.error),
                      onPressed: () => _confirmDelete(context),
                      tooltip: 'Hapus modul',
                    ),
                  ],
                  // Toggle expand
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
          // Detail yang bisa di-expand
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.module.topics.isNotEmpty)
                    _ChipGroup(
                        title: 'Topik',
                        items: widget.module.topics,
                        color: AppColors.primary),
                  if (widget.module.toolsRequired.isNotEmpty)
                    _ChipGroup(
                        title: 'Tools',
                        items: widget.module.toolsRequired,
                        color: AppColors.secondary),
                  if (widget.module.practicalActivities.isNotEmpty)
                    _ChipGroup(
                        title: 'Aktivitas Praktis',
                        items: widget.module.practicalActivities,
                        color: AppColors.warning),
                  if (widget.module.assessmentMethod.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Penilaian: ',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary),
                          ),
                          Expanded(
                            child: Text(
                              widget.module.assessmentMethod,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseModuleCubit>(),
        child: _ModuleDialog(
          versionId: widget.versionId,
          existing: widget.module,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Modul'),
        content: Text(
            'Yakin ingin menghapus modul "${widget.module.moduleTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<CourseModuleCubit>()
          .deleteModule(widget.module.id, widget.versionId);
    }
  }
}

// ─── Chip Group ───────────────────────────────────────────────────────────────

class _ChipGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _ChipGroup(
      {required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusCircle),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                          fontSize: 11, color: color, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Module Dialog ────────────────────────────────────────────────────────────

class _ModuleDialog extends StatefulWidget {
  final String versionId;
  final CourseModuleEntity? existing;

  const _ModuleDialog({required this.versionId, this.existing});

  @override
  State<_ModuleDialog> createState() => _ModuleDialogState();
}

class _ModuleDialogState extends State<_ModuleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _sequenceCtrl;
  late final TextEditingController _assessmentCtrl;
  late final TextEditingController _topicInputCtrl;
  late final TextEditingController _toolInputCtrl;
  late final TextEditingController _activityInputCtrl;
  late String _contentDepth;
  late List<String> _topics;
  late List<String> _tools;
  late List<String> _activities;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.moduleCode ?? '');
    _titleCtrl = TextEditingController(text: e?.moduleTitle ?? '');
    _durationCtrl = TextEditingController(
        text: e != null ? e.durationHours.toString() : '');
    _sequenceCtrl =
        TextEditingController(text: e != null ? e.sequence.toString() : '');
    _assessmentCtrl = TextEditingController(text: e?.assessmentMethod ?? '');
    _topicInputCtrl = TextEditingController();
    _toolInputCtrl = TextEditingController();
    _activityInputCtrl = TextEditingController();
    _contentDepth = e?.contentDepth ?? 'standard';
    _topics = List.from(e?.topics ?? []);
    _tools = List.from(e?.toolsRequired ?? []);
    _activities = List.from(e?.practicalActivities ?? []);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _titleCtrl.dispose();
    _durationCtrl.dispose();
    _sequenceCtrl.dispose();
    _assessmentCtrl.dispose();
    _topicInputCtrl.dispose();
    _toolInputCtrl.dispose();
    _activityInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = {
      'module_code': _codeCtrl.text.trim(),
      'module_title': _titleCtrl.text.trim(),
      'duration_hours': double.tryParse(_durationCtrl.text) ?? 0.0,
      'sequence': int.tryParse(_sequenceCtrl.text) ?? 1,
      'content_depth': _contentDepth,
      'assessment_method': _assessmentCtrl.text.trim(),
      'topics': _topics,
      'tools_required': _tools,
      'practical_activities': _activities,
    };
    try {
      bool success;
      if (_isEdit) {
        success = await context.read<CourseModuleCubit>().updateModule(
              widget.existing!.id,
              widget.versionId,
              data,
            );
      } else {
        success = await context
            .read<CourseModuleCubit>()
            .createModule(widget.versionId, data);
      }
      if (success && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Tambah item ke dalam list chip
  void _addItem(List<String> list, TextEditingController ctrl) {
    final val = ctrl.text.trim();
    if (val.isEmpty) return;
    setState(() {
      list.add(val);
      ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit ? 'Edit Modul' : 'Tambah Modul',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _codeCtrl,
                          decoration: const InputDecoration(labelText: 'Kode (M1)'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib' : null,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(labelText: 'Judul Modul'),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sequenceCtrl,
                          decoration: const InputDecoration(labelText: 'Urutan'),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib' : null,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _durationCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Durasi (jam)', suffixText: 'jam'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib' : null,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _contentDepth,
                          decoration:
                              const InputDecoration(labelText: 'Kedalaman'),
                          items: const [
                            DropdownMenuItem(
                                value: 'intro', child: Text('Intro')),
                            DropdownMenuItem(
                                value: 'standard', child: Text('Standard')),
                            DropdownMenuItem(
                                value: 'advanced', child: Text('Advanced')),
                          ],
                          onChanged: (v) =>
                              setState(() => _contentDepth = v ?? 'standard'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextFormField(
                    controller: _assessmentCtrl,
                    decoration: const InputDecoration(labelText: 'Metode Penilaian'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // Topics
                  _ChipEditor(
                    label: 'Topik',
                    items: _topics,
                    inputCtrl: _topicInputCtrl,
                    onAdd: () => _addItem(_topics, _topicInputCtrl),
                    onRemove: (i) => setState(() => _topics.removeAt(i)),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // Tools
                  _ChipEditor(
                    label: 'Tools / Peralatan',
                    items: _tools,
                    inputCtrl: _toolInputCtrl,
                    onAdd: () => _addItem(_tools, _toolInputCtrl),
                    onRemove: (i) => setState(() => _tools.removeAt(i)),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  // Practical Activities
                  _ChipEditor(
                    label: 'Aktivitas Praktis',
                    items: _activities,
                    inputCtrl: _activityInputCtrl,
                    onAdd: () => _addItem(_activities, _activityInputCtrl),
                    onRemove: (i) => setState(() => _activities.removeAt(i)),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
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
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Text(_isEdit ? 'Simpan' : 'Tambah'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chip Editor ──────────────────────────────────────────────────────────────

class _ChipEditor extends StatelessWidget {
  final String label;
  final List<String> items;
  final TextEditingController inputCtrl;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ChipEditor({
    required this.label,
    required this.items,
    required this.inputCtrl,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputCtrl,
                decoration: InputDecoration(
                  hintText: 'Tambah $label...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: AppDimensions.xs),
            IconButton.outlined(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              tooltip: 'Tambah',
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: List.generate(
              items.length,
              (i) => Chip(
                label: Text(items[i],
                    style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => onRemove(i),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Empty Module Card ────────────────────────────────────────────────────────

class _EmptyModuleCard extends StatelessWidget {
  final bool isReadonly;
  const _EmptyModuleCard({required this.isReadonly});

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
          const Icon(Icons.list_alt_outlined,
              size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.sm),
          Text(
            isReadonly
                ? 'Tidak ada modul untuk versi ini'
                : 'Belum ada modul — klik tombol "+ Tambah Modul"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
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

// ─── Data Model untuk version detail ─────────────────────────────────────────

class _VersionDetail {
  final String versionNumber;
  final String status;
  final String typeId;
  final String typeName;
  final String courseId;
  final String courseName;

  const _VersionDetail({
    required this.versionNumber,
    required this.status,
    required this.typeId,
    required this.typeName,
    required this.courseId,
    required this.courseName,
  });

  bool get isApproved => status == 'approved';

  factory _VersionDetail.fromJson(Map<String, dynamic> json) => _VersionDetail(
        versionNumber: json['version_number'] as String? ?? '—',
        status: json['status'] as String? ?? 'draft',
        typeId: json['course_type_id'] as String? ?? '',
        typeName: json['type_name'] as String? ?? '',
        courseId: json['master_course_id'] as String? ?? '',
        courseName: json['course_name'] as String? ?? '',
      );
}
