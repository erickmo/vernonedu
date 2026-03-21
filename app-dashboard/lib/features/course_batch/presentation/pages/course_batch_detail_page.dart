import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/course_batch_detail_entity.dart';
import '../cubit/course_batch_detail_cubit.dart';
import '../cubit/course_batch_detail_state.dart';

class CourseBatchDetailPage extends StatelessWidget {
  final String batchId;
  const CourseBatchDetailPage({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CourseBatchDetailCubit>()..loadDetail(batchId),
      child: _CourseBatchDetailView(batchId: batchId),
    );
  }
}

class _CourseBatchDetailView extends StatelessWidget {
  final String batchId;
  const _CourseBatchDetailView({required this.batchId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseBatchDetailCubit, CourseBatchDetailState>(
      listener: (context, state) {
        if (state is CourseBatchDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
      },
      child: BlocBuilder<CourseBatchDetailCubit, CourseBatchDetailState>(
        builder: (context, state) {
          if (state is CourseBatchDetailLoading ||
              state is CourseBatchDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CourseBatchDetailError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<CourseBatchDetailCubit>().loadDetail(batchId),
            );
          }
          if (state is CourseBatchDetailLoaded) {
            return _DetailContent(detail: state.detail);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final CourseBatchDetailEntity detail;
  const _DetailContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(detail: detail),
          const SizedBox(height: AppDimensions.lg),
          _InfoGrid(detail: detail),
          const SizedBox(height: AppDimensions.lg),
          _EnrollmentStats(detail: detail),
          const SizedBox(height: AppDimensions.lg),
          _EnrollmentTable(enrollments: detail.enrollments),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final CourseBatchDetailEntity detail;
  const _Header({required this.detail});

  String _statusLabel(String s) {
    switch (s) {
      case 'upcoming':
        return 'Akan Datang';
      case 'ongoing':
        return 'Sedang Berjalan';
      default:
        return 'Selesai';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'upcoming':
        return AppColors.info;
      case 'ongoing':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'upcoming':
        return AppColors.infoSurface;
      case 'ongoing':
        return AppColors.successSurface;
      default:
        return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = detail.batchStatus;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        IconButton(
          onPressed: () => context.go('/course-batches'),
          icon: const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
          tooltip: 'Kembali',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/course-batches'),
                    child: Text(
                      'Batch Course',
                      style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right,
                        size: 14, color: AppColors.textHint),
                  ),
                  Text(
                    detail.name,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      detail.name,
                      style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  _Badge(
                    label: _statusLabel(status),
                    color: _statusColor(status),
                    bgColor: _statusBg(status),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  IconButton.outlined(
                    onPressed: () => context
                        .read<CourseBatchDetailCubit>()
                        .loadDetail(detail.id),
                    icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              if (detail.courseName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  detail.courseName,
                  style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Info Grid ────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final CourseBatchDetailEntity detail;
  const _InfoGrid({required this.detail});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 900 ? 3 : 2;
      return Wrap(
        spacing: AppDimensions.md,
        runSpacing: AppDimensions.md,
        children: [
          _InfoCard(
            title: 'Informasi Course',
            icon: Icons.school_outlined,
            iconColor: AppColors.primary,
            children: [
              _InfoRow(label: 'Nama Course', value: detail.courseName.isNotEmpty ? detail.courseName : '—'),
              _InfoRow(label: 'Departemen', value: detail.departmentName.isNotEmpty ? detail.departmentName : '—'),
              if (detail.courseDescription.isNotEmpty)
                _InfoRow(label: 'Deskripsi', value: detail.courseDescription),
            ],
            width: (constraints.maxWidth - (crossCount - 1) * AppDimensions.md) / crossCount,
          ),
          _InfoCard(
            title: 'Jadwal Batch',
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.secondary,
            children: [
              _InfoRow(label: 'Tanggal Mulai', value: DateFormatUtil.toDisplay(detail.startDate)),
              _InfoRow(label: 'Tanggal Selesai', value: DateFormatUtil.toDisplay(detail.endDate)),
              _InfoRow(label: 'Durasi', value: '${detail.durationDays} hari'),
              _InfoRow(label: 'Status Aktif', value: detail.isActive ? 'Aktif' : 'Nonaktif'),
            ],
            width: (constraints.maxWidth - (crossCount - 1) * AppDimensions.md) / crossCount,
          ),
          _InfoCard(
            title: 'Fasilitator',
            icon: Icons.person_outline,
            iconColor: AppColors.info,
            children: [
              _InfoRow(
                label: 'Nama',
                value: detail.facilitatorName.isNotEmpty ? detail.facilitatorName : '—',
              ),
              _InfoRow(
                label: 'Email',
                value: detail.facilitatorEmail.isNotEmpty ? detail.facilitatorEmail : '—',
              ),
            ],
            width: (constraints.maxWidth - (crossCount - 1) * AppDimensions.md) / crossCount,
          ),
        ],
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  final double width;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(icon, size: AppDimensions.iconSm, color: iconColor),
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enrollment Stats ─────────────────────────────────────────────────────────

class _EnrollmentStats extends StatelessWidget {
  final CourseBatchDetailEntity detail;
  const _EnrollmentStats({required this.detail});

  @override
  Widget build(BuildContext context) {
    final ratio = detail.fillRate.clamp(0.0, 1.0);
    final fillColor = ratio >= 1.0 ? AppColors.error : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(Icons.people_outline,
                    size: AppDimensions.iconSm, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'Statistik Enrollment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Total Peserta',
                  value: '${detail.totalEnrolled}',
                  suffix: '/ ${detail.maxParticipants}',
                  color: fillColor,
                  bgColor: fillColor.withValues(alpha: 0.08),
                  icon: Icons.groups_outlined,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _StatChip(
                  label: 'Lunas',
                  value: '${detail.paidCount}',
                  suffix: 'peserta',
                  color: AppColors.success,
                  bgColor: AppColors.successSurface,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _StatChip(
                  label: 'Belum Lunas',
                  value: '${detail.pendingCount}',
                  suffix: 'peserta',
                  color: AppColors.warning,
                  bgColor: AppColors.warningSurface,
                  icon: Icons.schedule_outlined,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: _StatChip(
                  label: 'Gagal Bayar',
                  value: '${detail.failedCount}',
                  suffix: 'peserta',
                  color: AppColors.error,
                  bgColor: AppColors.errorSurface,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Progress bar
          Row(
            children: [
              Text(
                'Tingkat Pengisian',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).toStringAsFixed(1)}%  (${detail.totalEnrolled}/${detail.maxParticipants})',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fillColor),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: color.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color),
                ),
                TextSpan(
                  text: ' $suffix',
                  style: TextStyle(
                      fontSize: 11, color: color.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enrollment Table ─────────────────────────────────────────────────────────

class _EnrollmentTable extends StatefulWidget {
  final List<BatchEnrollmentItemEntity> enrollments;
  const _EnrollmentTable({required this.enrollments});

  @override
  State<_EnrollmentTable> createState() => _EnrollmentTableState();
}

class _EnrollmentTableState extends State<_EnrollmentTable> {
  String _search = '';
  String _statusFilter = 'semua';
  String _paymentFilter = 'semua';

  static const _statusOptions = ['semua', 'active', 'completed', 'dropped'];
  static const _paymentOptions = ['semua', 'paid', 'pending', 'failed'];

  static const _statusLabels = {
    'semua': 'Semua',
    'active': 'Aktif',
    'completed': 'Selesai',
    'dropped': 'Keluar',
  };

  static const _paymentLabels = {
    'semua': 'Semua',
    'paid': 'Lunas',
    'pending': 'Pending',
    'failed': 'Gagal',
  };

  List<BatchEnrollmentItemEntity> get _filtered {
    return widget.enrollments.where((e) {
      final matchSearch = _search.isEmpty ||
          e.studentName.toLowerCase().contains(_search.toLowerCase()) ||
          e.studentEmail.toLowerCase().contains(_search.toLowerCase());
      final matchStatus =
          _statusFilter == 'semua' || e.status == _statusFilter;
      final matchPayment =
          _paymentFilter == 'semua' || e.paymentStatus == _paymentFilter;
      return matchSearch && matchStatus && matchPayment;
    }).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'dropped':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'active':
        return AppColors.successSurface;
      case 'completed':
        return AppColors.primarySurface;
      case 'dropped':
        return AppColors.errorSurface;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color _paymentColor(String s) {
    switch (s) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _paymentBg(String s) {
    switch (s) {
      case 'paid':
        return AppColors.successSurface;
      case 'pending':
        return AppColors.warningSurface;
      case 'failed':
        return AppColors.errorSurface;
      default:
        return AppColors.surfaceVariant;
    }
  }

  String _statusLabel(String s) => _statusLabels[s] ?? s;
  String _paymentLabel(String s) => _paymentLabels[s] ?? s;

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.how_to_reg_outlined,
                        size: AppDimensions.iconMd,
                        color: AppColors.textSecondary),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      'Daftar Peserta (${widget.enrollments.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    if (items.length != widget.enrollments.length)
                      _Badge(
                        label: 'Menampilkan ${items.length}',
                        color: AppColors.info,
                        bgColor: AppColors.infoSurface,
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                // Filters
                Wrap(
                  spacing: AppDimensions.sm,
                  runSpacing: AppDimensions.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 34,
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Cari peserta...',
                          hintStyle: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.search,
                              size: AppDimensions.iconSm,
                              color: AppColors.textHint),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd),
                            borderSide: const BorderSide(
                                color: AppColors.border),
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    ..._statusOptions.map((s) => FilterChip(
                          label: Text(_statusLabels[s] ?? s,
                              style: const TextStyle(fontSize: 11)),
                          selected: _statusFilter == s,
                          onSelected: (_) =>
                              setState(() => _statusFilter = s),
                          selectedColor: AppColors.primarySurface,
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _statusFilter == s
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: _statusFilter == s
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          visualDensity: VisualDensity.compact,
                        )),
                    ..._paymentOptions.map((s) => FilterChip(
                          label: Text(_paymentLabels[s] ?? s,
                              style: const TextStyle(fontSize: 11)),
                          selected: _paymentFilter == s,
                          onSelected: (_) =>
                              setState(() => _paymentFilter = s),
                          selectedColor:
                              AppColors.success.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.success,
                          labelStyle: TextStyle(
                            color: _paymentFilter == s
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: _paymentFilter == s
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          visualDensity: VisualDensity.compact,
                        )),
                  ],
                ),
              ],
            ),
          ),

          // Table
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_search_outlined,
                        size: 40, color: AppColors.textHint),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      widget.enrollments.isEmpty
                          ? 'Belum ada peserta di batch ini'
                          : 'Tidak ada peserta yang sesuai filter',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: (items.length * AppDimensions.tableRowHeight) +
                  AppDimensions.tableHeaderHeight +
                  2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusLg),
                  bottomRight: Radius.circular(AppDimensions.radiusLg),
                ),
                child: DataTable2(
                  columnSpacing: AppDimensions.md,
                  horizontalMargin: AppDimensions.md,
                  headingRowHeight: AppDimensions.tableHeaderHeight,
                  dataRowHeight: AppDimensions.tableRowHeight,
                  headingRowColor:
                      WidgetStateProperty.all(AppColors.surfaceVariant),
                  columns: const [
                    DataColumn2(
                        label: Text('Peserta'), size: ColumnSize.L),
                    DataColumn2(
                        label: Text('Kontak'), size: ColumnSize.M),
                    DataColumn2(
                      label: Text('Tgl Daftar'),
                      size: ColumnSize.S,
                      fixedWidth: 120,
                    ),
                    DataColumn2(
                      label: Text('Status'),
                      size: ColumnSize.S,
                      fixedWidth: 95,
                    ),
                    DataColumn2(
                      label: Text('Pembayaran'),
                      size: ColumnSize.S,
                      fixedWidth: 100,
                    ),
                  ],
                  rows: items
                      .map((e) => DataRow2(
                            cells: [
                              // Peserta — nama + avatar
                              DataCell(Row(
                                children: [
                                  _Avatar(name: e.studentName),
                                  const SizedBox(width: AppDimensions.sm),
                                  Expanded(
                                    child: Text(
                                      e.studentName.isNotEmpty
                                          ? e.studentName
                                          : '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )),
                              // Kontak
                              DataCell(Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    e.studentEmail.isNotEmpty
                                        ? e.studentEmail
                                        : '—',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (e.studentPhone.isNotEmpty)
                                    Text(
                                      e.studentPhone,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textHint),
                                    ),
                                ],
                              )),
                              // Tanggal daftar
                              DataCell(Text(
                                DateFormatUtil.toDisplay(e.enrolledAt),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              )),
                              // Status
                              DataCell(_Badge(
                                label: _statusLabel(e.status),
                                color: _statusColor(e.status),
                                bgColor: _statusBg(e.status),
                              )),
                              // Pembayaran
                              DataCell(_Badge(
                                label: _paymentLabel(e.paymentStatus),
                                color: _paymentColor(e.paymentStatus),
                                bgColor: _paymentBg(e.paymentStatus),
                              )),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Badge(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  String get _initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary),
        ),
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
          const SizedBox(height: AppDimensions.md),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
