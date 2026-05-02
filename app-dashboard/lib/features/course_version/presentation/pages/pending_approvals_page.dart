import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/course_version_entity.dart';
import '../cubit/pending_approvals_cubit.dart';
import '../cubit/pending_approvals_state.dart';

// Page: Persetujuan Kurikulum.
// Shows all course versions with approval_status = 'submitted' awaiting dept_leader review.
class PendingApprovalsPage extends StatelessWidget {
  const PendingApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PendingApprovalsCubit>()..load(),
      child: const _PendingApprovalsView(),
    );
  }
}

class _PendingApprovalsView extends StatelessWidget {
  const _PendingApprovalsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimensions.lg),
          Expanded(
            child: BlocConsumer<PendingApprovalsCubit, PendingApprovalsState>(
              listener: (context, state) {
                if (state is PendingApprovalsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is PendingApprovalsLoading ||
                    state is PendingApprovalsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PendingApprovalsError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<PendingApprovalsCubit>().load(),
                  );
                }
                if (state is PendingApprovalsLoaded) {
                  if (state.versions.isEmpty) return const _EmptyView();
                  return _PendingTable(versions: state.versions);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persetujuan Kurikulum',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Versi kurikulum yang menunggu tindakan Anda sebagai Kepala Departemen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _PendingTable extends StatelessWidget {
  final List<CourseVersionEntity> versions;
  const _PendingTable({required this.versions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 760),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            columns: const [
              DataColumn(label: Text('Versi')),
              DataColumn(label: Text('Jenis Perubahan')),
              DataColumn(label: Text('Changelog')),
              DataColumn(label: Text('Diajukan')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: versions
                .map((v) => _buildRow(context, v))
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, CourseVersionEntity v) {
    return DataRow(cells: [
      DataCell(Text('v${v.versionNumber}',
          style: const TextStyle(fontWeight: FontWeight.w700))),
      DataCell(Text(v.changeType)),
      DataCell(SizedBox(
        width: 280,
        child: Text(
          v.changelog.isEmpty ? '—' : v.changelog,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      )),
      DataCell(Text(
        v.submittedAt != null
            ? DateFormatUtil.toDisplay(v.submittedAt!)
            : '—',
        style: const TextStyle(color: AppColors.textSecondary),
      )),
      DataCell(_RowAction(version: v)),
    ]);
  }
}

class _RowAction extends StatelessWidget {
  final CourseVersionEntity version;
  const _RowAction({required this.version});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go('/curriculum/versions/${version.id}'),
      icon: const Icon(Icons.visibility_outlined, size: 14),
      label: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Tidak ada versi menunggu persetujuan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Semua versi kurikulum sudah ditinjau.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
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
