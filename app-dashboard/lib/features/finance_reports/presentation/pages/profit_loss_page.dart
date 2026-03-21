import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/profit_loss_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../cubit/profit_loss_cubit.dart';
import '../widgets/report_filter_bar.dart';

class ProfitLossPage extends StatelessWidget {
  const ProfitLossPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfitLossCubit>()..load(),
      child: const _ProfitLossView(),
    );
  }
}

class _ProfitLossView extends StatelessWidget {
  const _ProfitLossView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Laba Rugi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Pendapatan, beban, dan laba bersih per periode',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<ProfitLossCubit, ProfitLossState>(
            builder: (context, state) {
              return ReportFilterBar(
                initialFilter: state is ProfitLossLoaded
                    ? state.filter
                    : const ReportFilterEntity(),
                onFilterChanged: (filter) =>
                    context.read<ProfitLossCubit>().load(filter: filter),
              );
            },
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: BlocBuilder<ProfitLossCubit, ProfitLossState>(
              builder: (context, state) {
                if (state is ProfitLossLoading || state is ProfitLossInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProfitLossError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppDimensions.sm),
                        Text(state.message,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: AppDimensions.md),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ProfitLossCubit>().load(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ProfitLossLoaded) {
                  return _ProfitLossContent(data: state.data);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitLossContent extends StatelessWidget {
  final ProfitLossEntity data;
  const _ProfitLossContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _PLStatement(data: data),
          const SizedBox(height: AppDimensions.lg),
          _PLBarChart(trendData: data.monthlyTrend),
        ],
      ),
    );
  }
}

class _PLStatement extends StatefulWidget {
  final ProfitLossEntity data;
  const _PLStatement({required this.data});

  @override
  State<_PLStatement> createState() => _PLStatementState();
}

class _PLStatementState extends State<_PLStatement> {
  final Map<String, bool> _expanded = {
    'revenue': true,
    'cogs': true,
    'expense': true,
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
          // Revenue section
          _SectionHeader(
            title: 'Pendapatan',
            total: widget.data.totalRevenue,
            expanded: _expanded['revenue']!,
            onToggle: () =>
                setState(() => _expanded['revenue'] = !_expanded['revenue']!),
            color: AppColors.success,
          ),
          if (_expanded['revenue']!)
            ...widget.data.revenueAccounts
                .map((a) => _PLAccountRow(account: a)),

          _SubtotalRow(label: 'Total Pendapatan', amount: widget.data.totalRevenue),

          // COGS section
          _SectionHeader(
            title: 'Harga Pokok Penjualan (HPP)',
            total: widget.data.totalCogs,
            expanded: _expanded['cogs']!,
            onToggle: () =>
                setState(() => _expanded['cogs'] = !_expanded['cogs']!),
            color: AppColors.warning,
          ),
          if (_expanded['cogs']!)
            ...widget.data.cogsAccounts.map((a) => _PLAccountRow(account: a)),

          _SubtotalRow(
            label: 'Laba Kotor',
            amount: widget.data.grossProfit,
            highlighted: true,
          ),

          // Expense section
          _SectionHeader(
            title: 'Beban Operasional',
            total: widget.data.totalExpense,
            expanded: _expanded['expense']!,
            onToggle: () =>
                setState(() => _expanded['expense'] = !_expanded['expense']!),
            color: AppColors.error,
          ),
          if (_expanded['expense']!)
            ...widget.data.expenseAccounts
                .map((a) => _PLAccountRow(account: a)),

          // Net profit
          _NetProfitRow(amount: widget.data.netProfit),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatefulWidget {
  final String title;
  final double total;
  final bool expanded;
  final VoidCallback onToggle;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.total,
    required this.expanded,
    required this.onToggle,
    required this.color,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovered = false;
  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md, vertical: AppDimensions.sm + 2),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : widget.color.withValues(alpha: 0.05),
            border: Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                widget.expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: AppDimensions.iconMd,
                color: widget.color,
              ),
              const SizedBox(width: AppDimensions.xs),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: widget.color,
                  ),
                ),
              ),
              Text(
                _fmt.format(widget.total),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PLAccountRow extends StatelessWidget {
  final ProfitLossAccountEntity account;
  final int depth;
  const _PLAccountRow({required this.account, this.depth = 0});

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: AppDimensions.md + (depth * 16.0),
            right: AppDimensions.md,
            top: AppDimensions.xs + 2,
            bottom: AppDimensions.xs + 2,
          ),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              Text(account.code,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontFamily: 'monospace')),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(account.name,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ),
              Text(
                _fmt.format(account.amount),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        ...account.children
            .map((c) => _PLAccountRow(account: c, depth: depth + 1)),
      ],
    );
  }
}

class _SubtotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool highlighted;
  const _SubtotalRow(
      {required this.label, required this.amount, this.highlighted = false});

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primarySurface : AppColors.surfaceVariant,
        border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
            top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _fmt.format(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetProfitRow extends StatelessWidget {
  final double amount;
  const _NetProfitRow({required this.amount});

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.md),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.successSurface : AppColors.errorSurface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusLg),
          bottomRight: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? AppColors.success : AppColors.error,
            size: AppDimensions.iconLg,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Laba Bersih',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          Text(
            _fmt.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _PLBarChart extends StatelessWidget {
  final List<MonthlyPLPoint> trendData;
  const _PLBarChart({required this.trendData});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) return const SizedBox.shrink();

    final maxVal = trendData
        .expand((p) => [p.revenue, p.expense])
        .reduce((a, b) => a > b ? a : b);

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
            'Tren Bulanan',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.sm),
          // Legend
          Wrap(
            spacing: AppDimensions.md,
            children: [
              _LegendItem(color: AppColors.primary, label: 'Pendapatan'),
              _LegendItem(color: AppColors.error, label: 'Pengeluaran'),
              _LegendItem(color: AppColors.success, label: 'Laba Bersih'),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['Pendapatan', 'Pengeluaran', 'Laba Bersih'];
                      final fmt = NumberFormat.compactCurrency(
                          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                      return BarTooltipItem(
                        '${labels[rodIndex]}\n${fmt.format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= trendData.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            trendData[idx].label,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final fmt = NumberFormat.compactCurrency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                        return Text(
                          fmt.format(value),
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: trendData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                          toY: p.revenue,
                          color: AppColors.primary,
                          width: 10,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(
                          toY: p.expense,
                          color: AppColors.error,
                          width: 10,
                          borderRadius: BorderRadius.circular(2)),
                      BarChartRodData(
                          toY: p.netProfit,
                          color: AppColors.success,
                          width: 10,
                          borderRadius: BorderRadius.circular(2)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
