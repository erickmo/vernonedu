import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../../../features/accounting/domain/entities/budget_item_entity.dart';
import '../../../../features/accounting/domain/entities/invoice_entity.dart';
import '../../../../features/accounting/domain/entities/transaction_entity.dart';
import '../cubit/finance_dashboard_cubit.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String _fmt(double v) => _idr.format(v);

class FinanceMainPage extends StatelessWidget {
  const FinanceMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FinanceDashboardCubit>()..loadAll(),
      child: const _FinanceView(),
    );
  }
}

class _FinanceView extends StatefulWidget {
  const _FinanceView();

  @override
  State<_FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<_FinanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<FinanceDashboardCubit>().loadAll(
          month: _selectedMonth,
          year: _selectedYear,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FinanceDashboardCubit, FinanceDashboardState>(
      listener: (context, state) {
        if (state is FinanceDashboardError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimensions.md),
            BlocBuilder<FinanceDashboardCubit, FinanceDashboardState>(
              builder: (context, state) {
                if (state is FinanceDashboardLoading ||
                    state is FinanceDashboardInitial) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is FinanceDashboardError) {
                  return Expanded(child: _buildError(state.message));
                }
                if (state is FinanceDashboardLoaded) {
                  return Expanded(child: _buildLoaded(context, state));
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keuangan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              'Manajemen Keuangan & Akuntansi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const Spacer(),
        _PeriodSelector(
          month: _selectedMonth,
          year: _selectedYear,
          onChanged: (m, y) {
            setState(() {
              _selectedMonth = m;
              _selectedYear = y;
            });
            _reload();
          },
        ),
        const SizedBox(width: AppDimensions.sm),
        IconButton.outlined(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: AppDimensions.sm),
        FilledButton.icon(
          onPressed: () => context.push('/finance/transactions/new'),
          icon: const Icon(Icons.add),
          label: const Text('Input Transaksi'),
        ),
      ],
    );
  }

  Widget _buildLoaded(BuildContext context, FinanceDashboardLoaded state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 stats
          Row(
            children: [
              _StatCard(
                label: 'Total Pendapatan',
                subtitle: 'Bulan ini',
                value: _fmt(state.stats.totalRevenue),
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.md),
              _StatCard(
                label: 'Total Pengeluaran',
                subtitle: 'Bulan ini',
                value: _fmt(state.stats.totalExpense),
                icon: Icons.trending_down,
                color: AppColors.error,
              ),
              const SizedBox(width: AppDimensions.md),
              _StatCard(
                label: 'Laba Bersih',
                subtitle: 'Bulan ini',
                value: _fmt(state.stats.netProfit),
                icon: Icons.account_balance_wallet_outlined,
                color: state.stats.netProfit >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              const SizedBox(width: AppDimensions.md),
              _StatCard(
                label: 'Kas & Bank',
                subtitle: 'Saldo saat ini',
                value: _fmt(state.stats.cashAndBank),
                icon: Icons.savings_outlined,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          // Row 2 stats
          Row(
            children: [
              _StatCard(
                label: 'Piutang',
                subtitle: 'Outstanding invoice',
                value: _fmt(state.stats.receivables),
                icon: Icons.receipt_long_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppDimensions.md),
              _StatCard(
                label: 'Hutang',
                subtitle: 'Account payable',
                value: _fmt(state.stats.payables),
                icon: Icons.money_off_outlined,
                color: AppColors.error,
              ),
              const SizedBox(width: AppDimensions.md),
              _StatCard(
                label: 'Invoice Jatuh Tempo',
                subtitle: 'Minggu ini',
                value: '${state.dueThisWeekCount} faktur',
                icon: Icons.schedule_outlined,
                color: state.dueThisWeekCount > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
              const SizedBox(width: AppDimensions.md),
              _StatCard(
                label: 'Komisi Belum Dibayar',
                subtitle: 'Estimasi',
                value: _fmt(state.stats.payables * 0.3),
                icon: Icons.people_outline,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          // Charts row
          SizedBox(
            height: 280,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TrendBarChart(trend: state.monthlyTrend),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: _ExpensePieChart(transactions: state.transactions),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          // Quick actions
          _QuickActionsRow(),
          const SizedBox(height: AppDimensions.lg),
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  dividerColor: AppColors.border,
                  tabs: const [
                    Tab(text: 'Transaksi Terbaru'),
                    Tab(text: 'Anggaran vs Realisasi'),
                    Tab(text: 'Ringkasan per Batch'),
                  ],
                ),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TransaksiTab(transactions: state.transactions),
                      _AnggaranTab(budgetItems: state.budgetItems),
                      _BatchTab(summaries: state.batchSummaries),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message),
          const SizedBox(height: AppDimensions.md),
          OutlinedButton(onPressed: _reload, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period selector
// ---------------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int month, int year) onChanged;

  const _PeriodSelector({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: month,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(months[i], style: const TextStyle(fontSize: 13)),
              ),
            ),
            onChanged: (v) => onChanged(v!, year),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: year,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: List.generate(
              5,
              (i) => DropdownMenuItem(
                value: DateTime.now().year - 2 + i,
                child: Text(
                  '${DateTime.now().year - 2 + i}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            onChanged: (v) => onChanged(month, v!),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (label: 'Input Transaksi', icon: Icons.add_circle_outline, route: '/finance/transactions/new'),
      (label: 'Lihat Invoice', icon: Icons.receipt_outlined, route: '/finance/invoices'),
      (label: 'Lihat Hutang', icon: Icons.list_alt_outlined, route: '/finance/payables'),
      (label: 'Laporan Keuangan', icon: Icons.bar_chart_outlined, route: '/finance/reports'),
      (label: 'Analisis Keuangan', icon: Icons.show_chart_outlined, route: '/finance/analysis'),
      (label: 'Jurnal Umum', icon: Icons.book_outlined, route: '/finance/journal'),
    ];
    return Row(
      children: actions
          .map((a) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: a == actions.last ? 0 : AppDimensions.sm),
                  child: _QuickActionCard(
                    label: a.label,
                    icon: a.icon,
                    onTap: () => context.push(a.route),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.md,
            horizontal: AppDimensions.sm,
          ),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 24,
                color: _hovered ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend bar chart (last 6 months)
// ---------------------------------------------------------------------------

class _TrendBarChart extends StatelessWidget {
  final List<MonthlyTrendPoint> trend;
  const _TrendBarChart({required this.trend});

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
          const Text(
            'Pendapatan vs Pengeluaran (6 bulan)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              _LegendDot(color: AppColors.success, label: 'Pendapatan'),
              const SizedBox(width: AppDimensions.md),
              _LegendDot(color: AppColors.error, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Expanded(
            child: trend.isEmpty
                ? const Center(
                    child: Text('Belum ada data',
                        style: TextStyle(color: AppColors.textHint)))
                : BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = rodIndex == 0 ? 'Pendapatan' : 'Pengeluaran';
                            return BarTooltipItem(
                              '$label\n${_fmt(rod.toY)}',
                              const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= trend.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  trend[idx].label,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        horizontalInterval: 5000000,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(trend.length, (i) {
                        final p = trend[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: p.revenue,
                              color: AppColors.success,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: p.expense,
                              color: AppColors.error,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expense pie chart
// ---------------------------------------------------------------------------

class _ExpensePieChart extends StatelessWidget {
  final List<TransactionEntity> transactions;
  const _ExpensePieChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions
        .where((t) => t.transactionType == 'expense' || t.transactionType == 'debit')
        .fold(<String, double>{}, (map, t) {
      final cat = t.category.isEmpty ? 'Lainnya' : t.category;
      map[cat] = (map[cat] ?? 0) + t.amount;
      return map;
    });

    final colors = AppColors.chartColors;
    final entries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          const Text(
            'Komposisi Pengeluaran',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text('Belum ada data',
                        style: TextStyle(color: AppColors.textHint)))
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: List.generate(
                              entries.length > 7 ? 7 : entries.length,
                              (i) => PieChartSectionData(
                                color: colors[i % colors.length],
                                value: entries[i].value,
                                title: '',
                                radius: 60,
                              ),
                            ),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          entries.length > 7 ? 7 : entries.length,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _LegendDot(
                              color: colors[i % colors.length],
                              label: entries[i].key,
                              maxWidth: 90,
                            ),
                          ),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final double? maxWidth;
  const _LegendDot({required this.color, required this.label, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: maxWidth,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tabs
// ---------------------------------------------------------------------------

class _TransaksiTab extends StatelessWidget {
  final List<TransactionEntity> transactions;
  const _TransaksiTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada transaksi',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return DataTable2(
      columnSpacing: AppDimensions.md,
      horizontalMargin: AppDimensions.md,
      headingRowHeight: AppDimensions.tableHeaderHeight,
      dataRowHeight: AppDimensions.tableRowHeight,
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.border, width: 1),
      ),
      columns: const [
        DataColumn2(label: Text('Tanggal', style: _hdr), fixedWidth: 110),
        DataColumn2(label: Text('Kode', style: _hdr), fixedWidth: 130),
        DataColumn2(label: Text('Deskripsi', style: _hdr), size: ColumnSize.L),
        DataColumn2(label: Text('Tipe', style: _hdr), fixedWidth: 100),
        DataColumn2(
            label: Text('Debit', style: _hdr),
            fixedWidth: 130,
            numeric: true),
        DataColumn2(
            label: Text('Kredit', style: _hdr),
            fixedWidth: 130,
            numeric: true),
      ],
      rows: transactions
          .map((t) => DataRow2(cells: [
                DataCell(Text(
                  t.transactionDate.length >= 10
                      ? t.transactionDate.substring(0, 10)
                      : t.transactionDate,
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(Text(
                  t.referenceNumber.isEmpty ? '-' : t.referenceNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                  ),
                )),
                DataCell(Text(
                  t.description,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(_TxTypeBadge(type: t.transactionType)),
                DataCell(Text(
                  t.transactionType == 'income' || t.transactionType == 'credit'
                      ? _fmt(t.amount)
                      : '—',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.success),
                )),
                DataCell(Text(
                  t.transactionType == 'expense' || t.transactionType == 'debit'
                      ? _fmt(t.amount)
                      : '—',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                )),
              ]))
          .toList(),
    );
  }
}

class _TxTypeBadge extends StatelessWidget {
  final String type;
  const _TxTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isIncome = type == 'income' || type == 'credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isIncome ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isIncome ? 'Pemasukan' : 'Pengeluaran',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isIncome ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _AnggaranTab extends StatelessWidget {
  final List<BudgetItemEntity> budgetItems;
  const _AnggaranTab({required this.budgetItems});

  @override
  Widget build(BuildContext context) {
    if (budgetItems.isEmpty) {
      return const Center(
        child: Text('Belum ada data anggaran',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return DataTable2(
      columnSpacing: AppDimensions.md,
      horizontalMargin: AppDimensions.md,
      headingRowHeight: AppDimensions.tableHeaderHeight,
      dataRowHeight: AppDimensions.tableRowHeight,
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.border, width: 1),
      ),
      columns: const [
        DataColumn2(
            label: Text('Akun / Kategori', style: _hdr), size: ColumnSize.L),
        DataColumn2(
            label: Text('Anggaran', style: _hdr),
            fixedWidth: 150,
            numeric: true),
        DataColumn2(
            label: Text('Realisasi', style: _hdr),
            fixedWidth: 150,
            numeric: true),
        DataColumn2(
            label: Text('Selisih', style: _hdr),
            fixedWidth: 130,
            numeric: true),
        DataColumn2(label: Text('%', style: _hdr), fixedWidth: 100),
      ],
      rows: budgetItems
          .map((b) {
            final selisih = b.anggaran - b.realisasi;
            final pct = b.anggaran > 0
                ? (b.realisasi / b.anggaran * 100).toStringAsFixed(1)
                : '0.0';
            return DataRow2(cells: [
              DataCell(Text(b.category,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500))),
              DataCell(Text(_fmt(b.anggaran),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text(_fmt(b.realisasi),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: b.realisasi > b.anggaran
                        ? AppColors.error
                        : AppColors.success,
                  ))),
              DataCell(Text(
                _fmt(selisih.abs()),
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  color: selisih < 0 ? AppColors.error : AppColors.success,
                ),
              )),
              DataCell(
                SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$pct%', style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 3),
                      LinearProgressIndicator(
                        value: (b.realisasi / (b.anggaran > 0 ? b.anggaran : 1))
                            .clamp(0.0, 1.0),
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          b.realisasi > b.anggaran
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
              ),
            ]);
          })
          .toList(),
    );
  }
}

class _BatchTab extends StatelessWidget {
  final List<BatchSummary> summaries;
  const _BatchTab({required this.summaries});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Center(
        child: Text('Belum ada data batch',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return DataTable2(
      columnSpacing: AppDimensions.md,
      horizontalMargin: AppDimensions.md,
      headingRowHeight: AppDimensions.tableHeaderHeight,
      dataRowHeight: AppDimensions.tableRowHeight,
      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.border, width: 1),
      ),
      columns: const [
        DataColumn2(label: Text('Batch', style: _hdr), size: ColumnSize.M),
        DataColumn2(
            label: Text('Pendapatan', style: _hdr),
            fixedWidth: 150,
            numeric: true),
        DataColumn2(
            label: Text('Pengeluaran', style: _hdr),
            fixedWidth: 130,
            numeric: true),
        DataColumn2(
            label: Text('Komisi', style: _hdr),
            fixedWidth: 120,
            numeric: true),
        DataColumn2(
            label: Text('Laba', style: _hdr), fixedWidth: 130, numeric: true),
        DataColumn2(label: Text('Margin %', style: _hdr), fixedWidth: 90),
      ],
      rows: summaries
          .map((b) => DataRow2(cells: [
                DataCell(Text(b.batchName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500))),
                DataCell(Text(_fmt(b.revenue),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.success))),
                DataCell(Text(_fmt(b.expense),
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.error))),
                DataCell(Text(_fmt(b.commission),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.warning))),
                DataCell(Text(
                  _fmt(b.profit),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: b.profit >= 0 ? AppColors.success : AppColors.error,
                  ),
                )),
                DataCell(Text(
                  '${b.margin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: b.margin >= 0 ? AppColors.success : AppColors.error,
                  ),
                )),
              ]))
          .toList(),
    );
  }
}

const _hdr = TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 12,
  color: AppColors.textPrimary,
);
