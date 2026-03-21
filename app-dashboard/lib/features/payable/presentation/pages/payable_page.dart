import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/payable_entity.dart';
import '../cubit/payable_cubit.dart';
import '../cubit/payable_state.dart';

class PayablePage extends StatelessWidget {
  const PayablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PayableCubit>()..loadAll(),
      child: const _PayableView(),
    );
  }
}

class _PayableView extends StatelessWidget {
  const _PayableView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PayableCubit, PayableState>(
      listener: (context, state) {
        if (state is PayableError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      child: BlocBuilder<PayableCubit, PayableState>(
        builder: (context, state) {
          if (state is PayableLoading || state is PayableInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PayableError) {
            return _ErrorView(message: state.message);
          }
          if (state is PayableLoaded) {
            return _PayableContent(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(
            onPressed: () => context.read<PayableCubit>().loadAll(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _PayableContent extends StatelessWidget {
  final PayableLoaded state;
  const _PayableContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.lg,
              AppDimensions.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hutang (Account Payable)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manajemen Kewajiban Pembayaran',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: AppDimensions.lg),
                // Stat cards
                _StatsRow(stats: state.stats),
                const SizedBox(height: AppDimensions.lg),
                // Tab bar
                const TabBar(
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Semua Hutang'),
                    Tab(text: 'Fasilitator'),
                    Tab(text: 'Komisi'),
                    Tab(text: 'Marketing Partner'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _AllPayablesTab(state: state),
                _FacilitatorTab(state: state),
                _CommissionTab(state: state),
                _MarketingPartnerTab(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Stats Row ────────────────────────────

class _StatsRow extends StatelessWidget {
  final PayableStatsEntity stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final hasDue = stats.dueThisWeekCount > 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatCard(
            label: 'Total Hutang',
            value: fmt.format(stats.totalPayable),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.error,
          ),
          const SizedBox(width: AppDimensions.md),
          _StatCard(
            label: 'Hutang Fasilitator',
            value: fmt.format(stats.facilitatorPayable),
            icon: Icons.person_outline,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.md),
          _StatCard(
            label: 'Hutang Komisi',
            value: fmt.format(stats.commissionPayable),
            icon: Icons.percent_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.md),
          _StatCard(
            label: 'Hutang Marketing Partner',
            value: fmt.format(stats.marketingPartnerPayable),
            icon: Icons.handshake_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.md),
          _StatCard(
            label: 'Jatuh Tempo Minggu Ini',
            value: '${stats.dueThisWeekCount} tagihan',
            subtitle: fmt.format(stats.dueThisWeekAmount),
            icon: Icons.schedule_outlined,
            color: hasDue ? AppColors.error : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppDimensions.iconMd, color: color),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Helper widgets ────────────────────────────

String _formatCurrency(double amount) {
  return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(amount);
}

Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warning;
    case 'approved':
      return AppColors.info;
    case 'paid':
      return AppColors.success;
    case 'cancelled':
      return AppColors.textHint;
    default:
      return AppColors.textSecondary;
  }
}

Color _statusSurfaceColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.warningSurface;
    case 'approved':
      return AppColors.infoSurface;
    case 'paid':
      return AppColors.successSurface;
    case 'cancelled':
      return AppColors.surfaceVariant;
    default:
      return AppColors.surfaceVariant;
  }
}

Widget _statusPill(String statusLabel, String status) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _statusSurfaceColor(status),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
    ),
    child: Text(
      statusLabel,
      style: TextStyle(
        fontSize: 11,
        color: _statusColor(status),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _typePill(String typeLabel, String type) {
  final colors = <String, Color>{
    'facilitator': AppColors.roleFacilitator,
    'commission_op_leader': AppColors.roleDirector,
    'commission_dept_leader': AppColors.roleDeptLeader,
    'commission_course_creator': AppColors.roleCourseOwner,
    'marketing_partner': AppColors.rolePartner,
  };
  final color = colors[type] ?? AppColors.textSecondary;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
    ),
    child: Text(
      typeLabel,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
    ),
  );
}

// ──────────────────────────── Tab 1: Semua Hutang ────────────────────────────

class _AllPayablesTab extends StatefulWidget {
  final PayableLoaded state;
  const _AllPayablesTab({required this.state});

  @override
  State<_AllPayablesTab> createState() => _AllPayablesTabState();
}

class _AllPayablesTabState extends State<_AllPayablesTab> {
  String? _selectedType;
  String? _selectedStatus;

  final _typeOptions = <String?, String>{
    null: 'Semua Tipe',
    'facilitator': 'Fasilitator',
    'commission_op_leader': 'Komisi Op Leader',
    'commission_dept_leader': 'Komisi Dept Leader',
    'commission_course_creator': 'Komisi Course Creator',
    'marketing_partner': 'Marketing Partner',
    'other': 'Lainnya',
  };

  final _statusOptions = <String?, String>{
    null: 'Semua Status',
    'pending': 'Pending',
    'approved': 'Disetujui',
    'paid': 'Dibayar',
    'cancelled': 'Dibatalkan',
  };

  @override
  Widget build(BuildContext context) {
    final payables = widget.state.payables;
    final page = widget.state.currentPage;

    return Column(
      children: [
        // Filters
        Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _typeOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedType = v);
                    context
                        .read<PayableCubit>()
                        .loadPage(type: v, status: _selectedStatus);
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _statusOptions.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    context
                        .read<PayableCubit>()
                        .loadPage(type: _selectedType, status: v);
                  },
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: payables.isEmpty
              ? const Center(
                  child: Text('Tidak ada data hutang', style: TextStyle(color: AppColors.textSecondary)),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                      columnSpacing: AppDimensions.xl,
                      columns: const [
                        DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Penerima', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600))),
                      ],
                      rows: payables.map((p) {
                        final dateStr = DateFormat('dd/MM/yyyy').format(p.date);
                        return DataRow(cells: [
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 13))),
                          DataCell(_typePill(p.typeLabel, p.type)),
                          DataCell(Text(p.recipientName, style: const TextStyle(fontSize: 13))),
                          DataCell(Text(p.batchCode ?? '-', style: const TextStyle(fontSize: 13))),
                          DataCell(Text(_formatCurrency(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          DataCell(_statusPill(p.statusLabel, p.status)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 18),
                                tooltip: 'Lihat Detail',
                                onPressed: () => _showDetail(context, p),
                                color: AppColors.primary,
                              ),
                              if (p.status == 'pending' || p.status == 'approved')
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  tooltip: 'Tandai Dibayar',
                                  onPressed: () => _confirmMarkPaid(context, p),
                                  color: AppColors.success,
                                ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
        ),
        // Pagination
        _PaginationBar(
          currentPage: page,
          hasMore: widget.state.hasMore,
          onPrev: page > 0
              ? () => context.read<PayableCubit>().loadPage(
                    page: page - 1,
                    type: _selectedType,
                    status: _selectedStatus,
                  )
              : null,
          onNext: widget.state.hasMore
              ? () => context.read<PayableCubit>().loadPage(
                    page: page + 1,
                    type: _selectedType,
                    status: _selectedStatus,
                  )
              : null,
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, PayableEntity p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detail Hutang — ${p.typeLabel}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Penerima', p.recipientName),
              _DetailRow('Tipe', p.typeLabel),
              _DetailRow('Jumlah', _formatCurrency(p.amount)),
              _DetailRow('Status', p.statusLabel),
              _DetailRow('Tanggal', DateFormat('dd MMMM yyyy', 'id_ID').format(p.date)),
              if (p.dueDate != null)
                _DetailRow('Jatuh Tempo', DateFormat('dd MMMM yyyy', 'id_ID').format(p.dueDate!)),
              if (p.batchCode != null) _DetailRow('Batch', p.batchCode!),
              if (p.facilitatorLevel != null) _DetailRow('Level', p.facilitatorLevel!),
              if (p.sessionCount != null) _DetailRow('Jumlah Sesi', '${p.sessionCount}'),
              if (p.feePerSession != null) _DetailRow('Fee/Sesi', _formatCurrency(p.feePerSession!)),
              if (p.commissionPercent != null) _DetailRow('Persentase', '${p.commissionPercent}%'),
              if (p.basisType != null) _DetailRow('Basis', p.basisType == 'profit' ? 'Profit' : 'Revenue'),
              if (p.referralCode != null) _DetailRow('Kode Referral', p.referralCode!),
              if (p.studentName != null) _DetailRow('Siswa', p.studentName!),
              _DetailRow('Sumber', p.source == 'auto' ? 'Auto' : 'Manual'),
              if (p.paymentProof != null) _DetailRow('Bukti Pembayaran', p.paymentProof!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmMarkPaid(BuildContext context, PayableEntity p) {
    final proofCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Tandai Sebagai Dibayar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p.recipientName} — ${_formatCurrency(p.amount)}'),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: proofCtrl,
              decoration: const InputDecoration(
                labelText: 'Bukti Pembayaran (opsional)',
                hintText: 'No. transfer / referensi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(dCtx);
              final proof = proofCtrl.text.trim().isEmpty ? null : proofCtrl.text.trim();
              final ok = await context.read<PayableCubit>().markAsPaid(p.id, paymentProof: proof);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hutang berhasil ditandai sebagai dibayar')),
                );
              }
            },
            child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Tab 2: Fasilitator ────────────────────────────

class _FacilitatorTab extends StatelessWidget {
  final PayableLoaded state;
  const _FacilitatorTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final payables = state.payables.where((p) => p.type == 'facilitator').toList();
    final totalSesi = payables.fold<int>(0, (sum, p) => sum + (p.sessionCount ?? 0));
    final totalAmount = payables.fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        // Summary card
        Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total Sesi Bulan Ini',
                  value: '$totalSesi sesi',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _SummaryCard(
                  label: 'Total Hutang Fasilitator',
                  value: _formatCurrency(totalAmount),
                  icon: Icons.account_balance_wallet_outlined,
                  valueColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: payables.isEmpty
              ? const Center(child: Text('Tidak ada hutang fasilitator', style: TextStyle(color: AppColors.textSecondary)))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                      columnSpacing: AppDimensions.xl,
                      columns: const [
                        DataColumn(label: Text('Fasilitator', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Level', style: TextStyle(fontWeight: FontWeight.w600))),
                        DataColumn(label: Text('Jml Sesi', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                        DataColumn(label: Text('Fee/Sesi', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      ],
                      rows: payables.map((p) {
                        return DataRow(cells: [
                          DataCell(Text(p.recipientName, style: const TextStyle(fontSize: 13))),
                          DataCell(Text(p.facilitatorLevel ?? '-', style: const TextStyle(fontSize: 13))),
                          DataCell(Text('${p.sessionCount ?? 0}', style: const TextStyle(fontSize: 13))),
                          DataCell(Text(p.feePerSession != null ? _formatCurrency(p.feePerSession!) : '-', style: const TextStyle(fontSize: 13))),
                          DataCell(Text(_formatCurrency(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          DataCell(_statusPill(p.statusLabel, p.status)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: AppColors.primaryLight),
          const SizedBox(width: AppDimensions.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: valueColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Tab 3: Komisi ────────────────────────────

class _CommissionTab extends StatelessWidget {
  final PayableLoaded state;
  const _CommissionTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final commissionTypes = {
      'commission_op_leader',
      'commission_dept_leader',
      'commission_course_creator',
    };
    final payables = state.payables.where((p) => commissionTypes.contains(p.type)).toList();

    return payables.isEmpty
        ? const Center(child: Text('Tidak ada hutang komisi', style: TextStyle(color: AppColors.textSecondary)))
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppDimensions.md),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.xl,
                columns: const [
                  DataColumn(label: Text('Penerima', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Basis', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('%', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: payables.map((p) {
                  final basisLabel = p.basisType == 'profit' ? 'Profit' : p.basisType == 'revenue' ? 'Revenue' : '-';
                  return DataRow(cells: [
                    DataCell(Text(p.recipientName, style: const TextStyle(fontSize: 13))),
                    DataCell(_typePill(p.typeLabel, p.type)),
                    DataCell(Text(p.batchCode ?? '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(basisLabel, style: const TextStyle(fontSize: 13))),
                    DataCell(Text(p.commissionPercent != null ? '${p.commissionPercent}%' : '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(_formatCurrency(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    DataCell(_statusPill(p.statusLabel, p.status)),
                  ]);
                }).toList(),
              ),
            ),
          );
  }
}

// ──────────────────────────── Tab 4: Marketing Partner ────────────────────────────

class _MarketingPartnerTab extends StatelessWidget {
  final PayableLoaded state;
  const _MarketingPartnerTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final payables = state.payables.where((p) => p.type == 'marketing_partner').toList();

    return payables.isEmpty
        ? const Center(child: Text('Tidak ada hutang marketing partner', style: TextStyle(color: AppColors.textSecondary)))
        : SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppDimensions.md),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.xl,
                columns: const [
                  DataColumn(label: Text('Partner', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Kode Referral', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Siswa', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Komisi', style: TextStyle(fontWeight: FontWeight.w600)), numeric: true),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: payables.map((p) {
                  return DataRow(cells: [
                    DataCell(Text(p.recipientName, style: const TextStyle(fontSize: 13))),
                    DataCell(Text(p.referralCode ?? '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(p.studentName ?? '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(p.batchCode ?? '-', style: const TextStyle(fontSize: 13))),
                    DataCell(Text(_formatCurrency(p.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    DataCell(_statusPill(p.statusLabel, p.status)),
                  ]);
                }).toList(),
              ),
            ),
          );
  }
}

// ──────────────────────────── Pagination ────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final bool hasMore;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.hasMore,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Halaman ${currentPage + 1}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppDimensions.md),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
            color: onPrev != null ? AppColors.primary : AppColors.textHint,
            tooltip: 'Halaman sebelumnya',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
            color: onNext != null ? AppColors.primary : AppColors.textHint,
            tooltip: 'Halaman berikutnya',
          ),
        ],
      ),
    );
  }
}
