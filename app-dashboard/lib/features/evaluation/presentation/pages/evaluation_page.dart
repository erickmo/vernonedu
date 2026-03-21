import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format_util.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<Map<String, dynamic>>> _batchesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _batchesFuture = _loadBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadBatches() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final res = await dio.get(
        '/course-batches',
        queryParameters: {'limit': 200},
      );
      final raw = res.data;
      final list = (raw is Map && raw['data'] != null)
          ? raw['data'] as List
          : raw is List
              ? raw
              : <dynamic>[];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _refresh() {
    setState(() {
      _batchesFuture = _loadBatches();
    });
  }

  // --- Status helpers ---

  Color _statusColor(String s) => switch (s) {
        'upcoming' => AppColors.info,
        'ongoing' => AppColors.success,
        'completed' => AppColors.textSecondary,
        _ => AppColors.textSecondary,
      };

  Color _statusBg(String s) => switch (s) {
        'upcoming' => AppColors.infoSurface,
        'ongoing' => AppColors.successSurface,
        'completed' => AppColors.surfaceVariant,
        _ => AppColors.surfaceVariant,
      };

  String _statusLabel(String s) => switch (s) {
        'upcoming' => 'Akan Datang',
        'ongoing' => 'Berjalan',
        'completed' => 'Selesai',
        _ => s,
      };

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  // --- Date parse helper ---

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw as String);
      return DateFormatUtil.toDisplay(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _batchesFuture,
        builder: (context, snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.lg),
              _buildSummaryStats(snapshot),
              const SizedBox(height: AppDimensions.lg),
              Expanded(child: _buildTabbedContent(snapshot)),
            ],
          );
        },
      ),
    );
  }

  // --- Section 1: Header ---

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluasi & Hasil Belajar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Pantau hasil dan kelulusan siswa per batch',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded, size: AppDimensions.iconMd),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }

  // --- Section 2: Summary Stats ---

  Widget _buildSummaryStats(
      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    final batches = snapshot.data ?? [];
    final total = batches.length;
    final selesai =
        batches.where((b) => b['status'] == 'completed').length;
    final berjalan =
        batches.where((b) => b['status'] == 'ongoing').length;
    final akanDatang =
        batches.where((b) => b['status'] == 'upcoming').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.view_list_rounded,
            iconColor: AppColors.primary,
            iconBg: AppColors.primarySurface,
            label: 'Total Batch',
            value: snapshot.connectionState == ConnectionState.waiting
                ? '—'
                : '$total',
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.surfaceVariant,
            label: 'Batch Selesai',
            value: snapshot.connectionState == ConnectionState.waiting
                ? '—'
                : '$selesai',
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            icon: Icons.play_circle_outline_rounded,
            iconColor: AppColors.success,
            iconBg: AppColors.successSurface,
            label: 'Batch Berjalan',
            value: snapshot.connectionState == ConnectionState.waiting
                ? '—'
                : '$berjalan',
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.info,
            iconBg: AppColors.infoSurface,
            label: 'Batch Akan Datang',
            value: snapshot.connectionState == ConnectionState.waiting
                ? '—'
                : '$akanDatang',
          ),
        ),
      ],
    );
  }

  // --- Section 3: Tabbed Content ---

  Widget _buildTabbedContent(
      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Column(
        children: [
          _buildTabBar(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _buildTabBarView(snapshot),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'Batch Aktif & Berjalan'),
          Tab(text: 'Batch Selesai'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(
      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _buildError();
    }

    final batches = snapshot.data ?? [];
    final ongoing =
        batches.where((b) => b['status'] == 'ongoing').toList();
    final completed =
        batches.where((b) => b['status'] == 'completed').toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOngoingTab(ongoing),
        _buildCompletedTab(completed),
      ],
    );
  }

  // --- Tab 1: Batch Aktif & Berjalan ---

  Widget _buildOngoingTab(List<Map<String, dynamic>> batches) {
    if (batches.isEmpty) {
      return _buildEmpty(
        icon: Icons.play_circle_outline_rounded,
        message: 'Belum ada batch berjalan',
      );
    }

    return DataTable2(
      columnSpacing: AppDimensions.md,
      horizontalMargin: AppDimensions.md,
      headingRowHeight: AppDimensions.tableHeaderHeight,
      dataRowHeight: AppDimensions.tableRowHeight,
      headingTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      columns: const [
        DataColumn2(label: Text('Kode Batch'), size: ColumnSize.S),
        DataColumn2(label: Text('Course'), size: ColumnSize.L),
        DataColumn2(label: Text('Fasilitator'), size: ColumnSize.M),
        DataColumn2(label: Text('Tgl Mulai'), size: ColumnSize.M),
        DataColumn2(label: Text('Tgl Selesai'), size: ColumnSize.M),
        DataColumn2(label: Text('Peserta'), size: ColumnSize.S),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
      ],
      rows: batches.map((batch) {
        final id = batch['id'] as String? ?? '';
        final code = batch['code'] as String? ?? '—';
        final course = batch['master_course_name'] as String? ?? '—';
        final facilitator =
            batch['facilitator_name'] as String? ?? '—';
        final startDate = _formatDate(batch['start_date']);
        final endDate = _formatDate(batch['end_date']);
        final totalEnrolled = batch['total_enrolled'] ?? 0;
        final maxParticipants = batch['max_participants'] ?? 0;
        final status = batch['status'] as String? ?? '';

        return DataRow2(
          onTap: () => context.go('/course-batches/$id'),
          cells: [
            DataCell(
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            DataCell(Text(course)),
            DataCell(Text(facilitator)),
            DataCell(Text(startDate)),
            DataCell(Text(endDate)),
            DataCell(
              Text('$totalEnrolled / $maxParticipants'),
            ),
            DataCell(_statusBadge(status)),
          ],
        );
      }).toList(),
    );
  }

  // --- Tab 2: Batch Selesai ---

  Widget _buildCompletedTab(List<Map<String, dynamic>> batches) {
    if (batches.isEmpty) {
      return _buildEmpty(
        icon: Icons.check_circle_outline_rounded,
        message: 'Belum ada batch selesai',
      );
    }

    return DataTable2(
      columnSpacing: AppDimensions.md,
      horizontalMargin: AppDimensions.md,
      headingRowHeight: AppDimensions.tableHeaderHeight,
      dataRowHeight: AppDimensions.tableRowHeight,
      headingTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      columns: const [
        DataColumn2(label: Text('Kode Batch'), size: ColumnSize.S),
        DataColumn2(label: Text('Course'), size: ColumnSize.L),
        DataColumn2(label: Text('Tgl Selesai'), size: ColumnSize.M),
        DataColumn2(label: Text('Total Peserta'), size: ColumnSize.S),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
      ],
      rows: batches.map((batch) {
        final id = batch['id'] as String? ?? '';
        final code = batch['code'] as String? ?? '—';
        final course = batch['master_course_name'] as String? ?? '—';
        final endDate = _formatDate(batch['end_date']);
        final totalEnrolled = batch['total_enrolled'] ?? 0;
        final status = batch['status'] as String? ?? 'completed';

        return DataRow2(
          onTap: () => context.go('/course-batches/$id'),
          cells: [
            DataCell(
              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            DataCell(Text(course)),
            DataCell(Text(endDate)),
            DataCell(Text('$totalEnrolled')),
            DataCell(_statusBadge(status)),
          ],
        );
      }).toList(),
    );
  }

  // --- States: Error & Empty ---

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Gagal memuat data batch',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.md),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded,
                size: AppDimensions.iconSm),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Stat Card ---

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

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
            width: AppDimensions.avatarMd,
            height: AppDimensions.avatarMd,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: AppDimensions.iconMd),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
