import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/entities/department_summary_entity.dart';
import '../cubit/department_cubit.dart';
import '../cubit/department_state.dart';
import '../cubit/department_dashboard_cubit.dart';
import '../cubit/department_dashboard_state.dart';

class DepartmentPage extends StatelessWidget {
  const DepartmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DepartmentCubit>()..loadDepartments()),
        BlocProvider(create: (_) => getIt<DepartmentSummaryCubit>()..load()),
      ],
      child: const _DepartmentView(),
    );
  }
}

class _DepartmentView extends StatefulWidget {
  const _DepartmentView();

  @override
  State<_DepartmentView> createState() => _DepartmentViewState();
}

class _DepartmentViewState extends State<_DepartmentView> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppDimensions.lg),
            _buildSearchBar(),
            const SizedBox(height: AppDimensions.lg),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Departemen',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola departemen dan lihat ringkasan aktivitas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showDepartmentForm(context),
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('Tambah Departemen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.sm + 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari departemen...',
          prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<DepartmentSummaryCubit, DepartmentSummaryState>(
      builder: (context, summaryState) {
        return BlocBuilder<DepartmentCubit, DepartmentState>(
          builder: (context, deptState) {
            if (summaryState is DepartmentSummaryLoading || deptState is DepartmentLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (summaryState is DepartmentSummaryLoaded) {
              final filtered = summaryState.summaries
                  .where((d) => _search.isEmpty || d.name.toLowerCase().contains(_search))
                  .toList();

              if (filtered.isEmpty) return _buildEmpty(context);
              return _buildSummaryGrid(context, filtered);
            }

            if (summaryState is DepartmentSummaryError) {
              if (deptState is DepartmentLoaded) {
                return _buildPlainGrid(context, deptState.departments);
              }
              return Center(child: Text(summaryState.message));
            }

            if (deptState is DepartmentError) {
              return Center(child: Text(deptState.message));
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildSummaryGrid(BuildContext context, List<DepartmentSummaryEntity> summaries) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxis = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 700
                ? 2
                : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: AppDimensions.md,
            mainAxisSpacing: AppDimensions.md,
            childAspectRatio: 1.55,
          ),
          itemCount: summaries.length,
          itemBuilder: (_, i) => _DepartmentSummaryCard(
            summary: summaries[i],
            onEdit: () => _showDepartmentFormById(
                context, summaries[i].id, summaries[i].name, summaries[i].description),
            onDelete: () => _confirmDelete(context, summaries[i].id, summaries[i].name),
          ),
        );
      },
    );
  }

  Widget _buildPlainGrid(BuildContext context, List<DepartmentEntity> departments) {
    final filtered = departments
        .where((d) => _search.isEmpty || d.name.toLowerCase().contains(_search))
        .toList();
    if (filtered.isEmpty) return _buildEmpty(context);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossAxis = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 700
                ? 2
                : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: AppDimensions.md,
            mainAxisSpacing: AppDimensions.md,
            childAspectRatio: 2.2,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _DepartmentPlainCard(
            dept: filtered[i],
            onEdit: () => _showDepartmentFormById(
                context, filtered[i].id, filtered[i].name, filtered[i].description),
            onDelete: () => _confirmDelete(context, filtered[i].id, filtered[i].name),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Belum ada departemen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.sm),
          ElevatedButton(
            onPressed: () => _showDepartmentForm(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Tambah Departemen'),
          ),
        ],
      ),
    );
  }

  void _showDepartmentForm(BuildContext context, {String? id, String? name, String? description}) {
    final nameCtrl = TextEditingController(text: name ?? '');
    final descCtrl = TextEditingController(text: description ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(id == null ? 'Tambah Departemen' : 'Edit Departemen'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Departemen *'),
              ),
              const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final data = {
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'is_active': true,
              };
              if (id == null) {
                context.read<DepartmentCubit>().createDepartment(data);
              } else {
                context.read<DepartmentCubit>().updateDepartment(id, data);
              }
              Navigator.pop(ctx);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) context.read<DepartmentSummaryCubit>().load();
              });
            },
            child: Text(id == null ? 'Simpan' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDepartmentFormById(BuildContext context, String id, String name, String desc) {
    _showDepartmentForm(context, id: id, name: name, description: desc);
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Departemen'),
        content: Text('Yakin ingin menghapus departemen "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              context.read<DepartmentCubit>().deleteDepartment(id);
              Navigator.pop(ctx);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) context.read<DepartmentSummaryCubit>().load();
              });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ─── Department Summary Card ─────────────────────────────────────────────────

class _DepartmentSummaryCard extends StatefulWidget {
  final DepartmentSummaryEntity summary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentSummaryCard({
    required this.summary,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_DepartmentSummaryCard> createState() => _DepartmentSummaryCardState();
}

class _DepartmentSummaryCardState extends State<_DepartmentSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/departments/${s.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.06),
                blurRadius: _hovered ? 16 : 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _hovered ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _DeptAvatar(name: s.name),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: AppDimensions.iconMd, color: AppColors.textSecondary),
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit();
                      if (v == 'delete') widget.onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                        label: 'Kursus',
                        value: '${s.courseCount}',
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatBox(
                        label: 'Peserta Lunas',
                        value: '${s.paidEnrollmentCount}',
                        color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Batch pills
              Row(
                children: [
                  Expanded(
                    child: _BatchPill(
                        label: 'Akan Datang', value: s.batchUpcoming, color: AppColors.info),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _BatchPill(
                        label: 'Berjalan', value: s.batchOngoing, color: AppColors.success),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _BatchPill(
                        label: 'Selesai',
                        value: s.batchCompleted,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeptAvatar extends StatelessWidget {
  final String name;
  const _DeptAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _BatchPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _BatchPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Fallback plain card ──────────────────────────────────────────────────────

class _DepartmentPlainCard extends StatefulWidget {
  final DepartmentEntity dept;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DepartmentPlainCard(
      {required this.dept, required this.onEdit, required this.onDelete});

  @override
  State<_DepartmentPlainCard> createState() => _DepartmentPlainCardState();
}

class _DepartmentPlainCardState extends State<_DepartmentPlainCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/departments/${widget.dept.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.black.withOpacity(0.06),
                blurRadius: _hovered ? 16 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              _DeptAvatar(name: widget.dept.name),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.dept.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    if (widget.dept.description.isNotEmpty)
                      Text(
                        widget.dept.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: AppDimensions.iconMd, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'edit') widget.onEdit();
                  if (v == 'delete') widget.onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
