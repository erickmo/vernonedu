import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/cash_flow_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../cubit/cash_flow_cubit.dart';
import '../widgets/report_filter_bar.dart';

class CashFlowPage extends StatelessWidget {
  const CashFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CashFlowCubit>()..load(),
      child: const _CashFlowView(),
    );
  }
}

class _CashFlowView extends StatelessWidget {
  const _CashFlowView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Arus Kas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Aliran kas dari aktivitas operasi, investasi, dan pendanaan',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<CashFlowCubit, CashFlowState>(
            builder: (context, state) {
              return ReportFilterBar(
                initialFilter: state is CashFlowLoaded
                    ? state.filter
                    : const ReportFilterEntity(),
                onFilterChanged: (filter) =>
                    context.read<CashFlowCubit>().load(filter: filter),
              );
            },
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: BlocBuilder<CashFlowCubit, CashFlowState>(
              builder: (context, state) {
                if (state is CashFlowLoading || state is CashFlowInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CashFlowError) {
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
                              context.read<CashFlowCubit>().load(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is CashFlowLoaded) {
                  return _CashFlowContent(data: state.data);
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

class _CashFlowContent extends StatelessWidget {
  final CashFlowEntity data;
  const _CashFlowContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Sections
          _CashFlowSection(section: data.operating, color: AppColors.primary),
          const SizedBox(height: AppDimensions.sm),
          _CashFlowSection(section: data.investing, color: AppColors.warning),
          const SizedBox(height: AppDimensions.sm),
          _CashFlowSection(section: data.financing, color: AppColors.info),
          const SizedBox(height: AppDimensions.md),
          // Summary footer
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    label: 'Kenaikan/(Penurunan) Kas Bersih',
                    amount: data.netChange,
                    isBold: true),
                const Divider(color: AppColors.border, height: AppDimensions.md),
                _SummaryRow(
                    label: 'Saldo Awal Kas', amount: data.openingBalance),
                const SizedBox(height: AppDimensions.xs),
                _SummaryRow(
                    label: 'Saldo Akhir Kas',
                    amount: data.closingBalance,
                    isBold: true,
                    highlight: true),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _CashFlowLineChart(trendData: data.monthlyTrend),
        ],
      ),
    );
  }
}

class _CashFlowSection extends StatefulWidget {
  final CashFlowSectionEntity section;
  final Color color;
  const _CashFlowSection({required this.section, required this.color});

  @override
  State<_CashFlowSection> createState() => _CashFlowSectionState();
}

class _CashFlowSectionState extends State<_CashFlowSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          _HeaderRow(
            title: widget.section.name,
            netCash: widget.section.netCash,
            expanded: _expanded,
            color: widget.color,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...widget.section.lines.map((line) => _LineRow(line: line)),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatefulWidget {
  final String title;
  final double netCash;
  final bool expanded;
  final Color color;
  final VoidCallback onToggle;

  const _HeaderRow({
    required this.title,
    required this.netCash,
    required this.expanded,
    required this.color,
    required this.onToggle,
  });

  @override
  State<_HeaderRow> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<_HeaderRow> {
  bool _hovered = false;

  static final _fmt =
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
                ? widget.color.withValues(alpha: 0.1)
                : widget.color.withValues(alpha: 0.06),
            borderRadius: widget.expanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusMd),
                    topRight: Radius.circular(AppDimensions.radiusMd),
                  )
                : BorderRadius.circular(AppDimensions.radiusMd),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: widget.color,
                  ),
                ),
              ),
              Text(
                _fmt.format(widget.netCash),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: widget.netCash >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final CashFlowLineEntity line;
  const _LineRow({required this.line});

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isNegative = line.amount < 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.xs + 2),
      decoration: BoxDecoration(
        color: line.isSubtotal ? AppColors.surfaceVariant : null,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: line.isSubtotal ? FontWeight.w600 : FontWeight.normal,
                color:
                    line.isSubtotal ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            isNegative
                ? '(${_fmt.format(line.amount.abs())})'
                : _fmt.format(line.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: line.isSubtotal ? FontWeight.w700 : FontWeight.normal,
              color: isNegative ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.highlight = false,
  });

  static final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isPositive = amount >= 0;
    final amountColor = highlight
        ? (isPositive ? AppColors.success : AppColors.error)
        : AppColors.textPrimary;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          _fmt.format(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isBold ? 14 : 13,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}

class _CashFlowLineChart extends StatelessWidget {
  final List<MonthlyCashPoint> trendData;
  const _CashFlowLineChart({required this.trendData});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) return const SizedBox.shrink();

    final spots = trendData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.balance);
    }).toList();

    final maxVal =
        trendData.map((p) => p.balance).reduce((a, b) => a > b ? a : b);
    final minVal =
        trendData.map((p) => p.balance).reduce((a, b) => a < b ? a : b);

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
            'Tren Posisi Kas Bulanan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minVal * 0.9,
                maxY: maxVal * 1.1,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
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
                      reservedSize: 64,
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
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
