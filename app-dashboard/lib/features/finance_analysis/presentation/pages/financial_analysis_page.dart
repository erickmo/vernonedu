import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '../cubit/finance_analysis_cubit.dart';
import '../cubit/finance_analysis_state.dart';

class FinancialAnalysisPage extends StatelessWidget {
  const FinancialAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<FinanceAnalysisCubit>()..loadAll(),
        child: const _FinancialAnalysisView(),
      );
}

class _FinancialAnalysisView extends StatelessWidget {
  const _FinancialAnalysisView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceAnalysisCubit, FinanceAnalysisState>(
      builder: (context, state) {
        if (state is FinanceAnalysisLoading || state is FinanceAnalysisInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FinanceAnalysisError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppDimensions.md),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.md),
                ElevatedButton(
                  onPressed: () =>
                      context.read<FinanceAnalysisCubit>().loadAll(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        final data = state as FinanceAnalysisLoaded;
        return _FinancialAnalysisContent(data: data);
      },
    );
  }
}

class _FinancialAnalysisContent extends StatelessWidget {
  final FinanceAnalysisLoaded data;
  const _FinancialAnalysisContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceAnalysisCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Analisis Keuangan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          const Text(
            'Rasio keuangan, tren pendapatan, biaya, dan proyeksi kas',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.lg),

          // Filter Bar
          _FilterBar(
            selectedPeriod: data.selectedPeriod,
            selectedBranchId: data.selectedBranchId,
            selectedComparison: data.selectedComparison,
            onPeriodChanged: cubit.changePeriod,
            onBranchChanged: cubit.changeBranch,
            onComparisonChanged: cubit.changeComparison,
          ),
          const SizedBox(height: AppDimensions.xl),

          // Section 1: Rasio Keuangan
          _buildSectionHeader(
            'Rasio Keuangan Utama',
            'Indikator performa keuangan periode ini vs periode pembanding',
          ),
          _RatiosSection(ratios: data.ratios),
          const SizedBox(height: AppDimensions.xl),

          // Section 2: Analisis Pendapatan
          _buildSectionHeader(
            'Analisis Pendapatan',
            'Tren pendapatan berdasarkan jenis kelas dan cabang',
          ),
          _RevenueSection(revenue: data.revenue),
          const SizedBox(height: AppDimensions.xl),

          // Section 3: Analisis Biaya
          _buildSectionHeader(
            'Analisis Biaya',
            'Distribusi dan tren pengeluaran per kategori',
          ),
          _CostSection(costs: data.costs),
          const SizedBox(height: AppDimensions.xl),

          // Section 4: Profitabilitas Batch
          _buildSectionHeader(
            'Profitabilitas Batch',
            'Perbandingan profit antar batch kelas',
          ),
          _BatchProfitSection(batchProfit: data.batchProfit),
          const SizedBox(height: AppDimensions.xl),

          // Section 5: Proyeksi Kas
          _buildSectionHeader(
            'Proyeksi Kas',
            'Perkiraan arus kas 3 bulan ke depan',
          ),
          _CashForecastSection(cashForecast: data.cashForecast),
          const SizedBox(height: AppDimensions.xl),

          // Section 6: Peringatan & Rekomendasi
          _buildSectionHeader(
            'Peringatan & Rekomendasi',
            'Notifikasi keuangan dan saran tindakan',
          ),
          _AlertsSection(
            alerts: data.alerts,
            suggestions: data.suggestions,
          ),
          const SizedBox(height: AppDimensions.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Filter Bar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final String selectedPeriod;
  final String? selectedBranchId;
  final String selectedComparison;
  final void Function(String) onPeriodChanged;
  final void Function(String?) onBranchChanged;
  final void Function(String) onComparisonChanged;

  const _FilterBar({
    required this.selectedPeriod,
    required this.selectedBranchId,
    required this.selectedComparison,
    required this.onPeriodChanged,
    required this.onBranchChanged,
    required this.onComparisonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.md,
      runSpacing: AppDimensions.sm,
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            value: selectedPeriod,
            decoration: const InputDecoration(
              labelText: 'Periode',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
              DropdownMenuItem(value: 'quarterly', child: Text('Kuartalan')),
              DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
            ],
            onChanged: (v) {
              if (v != null) onPeriodChanged(v);
            },
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String?>(
            value: selectedBranchId,
            decoration: const InputDecoration(
              labelText: 'Cabang',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Semua Cabang')),
            ],
            onChanged: onBranchChanged,
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: selectedComparison,
            decoration: const InputDecoration(
              labelText: 'Pembanding',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                  value: 'vs_last_month', child: Text('vs Bulan Lalu')),
              DropdownMenuItem(
                  value: 'vs_last_quarter', child: Text('vs Kuartal Lalu')),
              DropdownMenuItem(
                  value: 'vs_last_year', child: Text('vs Tahun Lalu')),
            ],
            onChanged: (v) {
              if (v != null) onComparisonChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1: Rasio Keuangan
// ---------------------------------------------------------------------------

class _RatiosSection extends StatelessWidget {
  final FinancialRatioEntity ratios;
  const _RatiosSection({required this.ratios});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Profit Margin',
                value: '${ratios.profitMargin.toStringAsFixed(1)}%',
                trend: ratios.profitMarginTrend,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _KpiCard(
                title: 'Rasio OPEX',
                value: '${ratios.opexRatio.toStringAsFixed(1)}%',
                trend: ratios.opexRatioTrend,
                invertTrend: true,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _KpiCard(
                title: 'Pendapatan/Siswa',
                value: _formatAmount(ratios.revenuePerStudent),
                trend: ratios.revenuePerStudentTrend,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _KpiCard(
                title: 'Biaya/Siswa',
                value: _formatAmount(ratios.costPerStudent),
                trend: ratios.costPerStudentTrend,
                invertTrend: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: 'Avg Profitabilitas Batch',
                value: '${ratios.avgBatchProfitability.toStringAsFixed(1)}%',
                trend: ratios.avgBatchProfitabilityTrend,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _KpiCard(
                title: 'Collection Rate',
                value: '${ratios.collectionRate.toStringAsFixed(1)}%',
                trend: ratios.collectionRateTrend,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _KpiCard(
                title: 'DSO (hari)',
                value: '${ratios.dso.toStringAsFixed(0)} hr',
                trend: ratios.dsoTrend,
                invertTrend: true,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _KpiCard(
                title: 'Revenue Growth',
                value: '${ratios.revenueGrowthRate.toStringAsFixed(1)}%',
                trend: ratios.revenueGrowthRateTrend,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final double trend;
  final bool invertTrend;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.trend,
    this.invertTrend = false,
  });

  @override
  Widget build(BuildContext context) {
    // When invertTrend=true, a negative trend is actually good (e.g., lower costs)
    final isPositive = invertTrend ? trend <= 0 : trend >= 0;
    final trendColor = isPositive ? AppColors.success : AppColors.error;
    final trendIcon =
        trend >= 0 ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                '${trend.abs().toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: trendColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2: Analisis Pendapatan
// ---------------------------------------------------------------------------

class _RevenueSection extends StatelessWidget {
  final RevenueAnalysisEntity revenue;
  const _RevenueSection({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Line chart: revenue trend
        _SectionCard(
          title: 'Tren Pendapatan per Jenis Kelas',
          child: SizedBox(
            height: 260,
            child: revenue.trend.isEmpty
                ? const _EmptyChart()
                : _RevenueTrendChart(trend: revenue.trend),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue by type table
            Expanded(
              flex: 3,
              child: _SectionCard(
                title: 'Pendapatan per Jenis Kelas',
                child: _RevenueByTypeTable(byType: revenue.byType),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            // Revenue by branch bar chart
            Expanded(
              flex: 2,
              child: _SectionCard(
                title: 'Pendapatan per Cabang',
                child: SizedBox(
                  height: 240,
                  child: revenue.byBranch.isEmpty
                      ? const _EmptyChart()
                      : _RevenueByBranchChart(byBranch: revenue.byBranch),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  final List<RevenueTrendPoint> trend;
  const _RevenueTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final labels = trend.map((e) => e.month).toList();
    final series = [
      (name: 'Total', values: trend.map((e) => e.total).toList()),
      (name: 'Reguler', values: trend.map((e) => e.reguler).toList()),
      (name: 'Program Karir', values: trend.map((e) => e.programKarir).toList()),
      (name: 'Inhouse', values: trend.map((e) => e.inhouse).toList()),
      (name: 'Kolaborasi', values: trend.map((e) => e.kolaborasi).toList()),
      (name: 'Sertifikasi', values: trend.map((e) => e.sertifikasi).toList()),
    ];

    final lineBarsData = series.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      return LineChartBarData(
        spots: s.values.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value);
        }).toList(),
        isCurved: true,
        color: AppColors.chartColors[i % AppColors.chartColors.length],
        barWidth: 2,
        dotData: const FlDotData(show: false),
      );
    }).toList();

    double maxY = 0;
    for (final s in series) {
      for (final v in s.values) {
        if (v > maxY) maxY = v;
      }
    }
    if (maxY == 0) maxY = 1;

    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        minY: 0,
        maxY: maxY * 1.15,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                final label = labels[idx];
                final short = label.length > 3 ? label.substring(0, 3) : label;
                return Text(short,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                _formatAmountShort(value),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _RevenueByTypeTable extends StatelessWidget {
  final List<RevenueByTypeEntity> byType;
  const _RevenueByTypeTable({required this.byType});

  @override
  Widget build(BuildContext context) {
    if (byType.isEmpty) {
      return const _EmptyData();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: AppDimensions.tableHeaderHeight,
        dataRowMinHeight: AppDimensions.tableRowHeight,
        dataRowMaxHeight: AppDimensions.tableRowHeight,
        columns: const [
          DataColumn(label: Text('Jenis Kelas')),
          DataColumn(label: Text('Pendapatan'), numeric: true),
          DataColumn(label: Text('%'), numeric: true),
          DataColumn(label: Text('Batch'), numeric: true),
          DataColumn(label: Text('Avg/Batch'), numeric: true),
          DataColumn(label: Text('Tren'), numeric: true),
        ],
        rows: byType.map((item) {
          final isUp = item.trend >= 0;
          return DataRow(cells: [
            DataCell(Text(item.typeName)),
            DataCell(Text(_formatAmount(item.amount))),
            DataCell(Text('${item.percentage.toStringAsFixed(1)}%')),
            DataCell(Text('${item.batchCount}')),
            DataCell(Text(_formatAmount(item.avgPerBatch))),
            DataCell(Row(children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isUp ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 2),
              Text(
                '${item.trend.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 12,
                    color: isUp ? AppColors.success : AppColors.error),
              ),
            ])),
          ]);
        }).toList(),
      ),
    );
  }
}

class _RevenueByBranchChart extends StatelessWidget {
  final List<RevenueByBranchEntity> byBranch;
  const _RevenueByBranchChart({required this.byBranch});

  @override
  Widget build(BuildContext context) {
    double maxY =
        byBranch.fold(0, (prev, e) => e.amount > prev ? e.amount : prev);
    if (maxY == 0) maxY = 1;

    final barGroups = byBranch.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: e.amount,
            color: AppColors.chartColors[i % AppColors.chartColors.length],
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        maxY: maxY * 1.15,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= byBranch.length) {
                  return const SizedBox.shrink();
                }
                final name = byBranch[idx].branchName;
                final short = name.length > 6 ? name.substring(0, 6) : name;
                return Text(short,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                _formatAmountShort(value),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 3: Analisis Biaya
// ---------------------------------------------------------------------------

class _CostSection extends StatelessWidget {
  final CostAnalysisEntity costs;
  const _CostSection({required this.costs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Tren Biaya per Kategori',
          child: SizedBox(
            height: 260,
            child: costs.trend.isEmpty
                ? const _EmptyChart()
                : _CostTrendChart(trend: costs.trend),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        _SectionCard(
          title: 'Biaya per Kategori',
          child: _CostByCategoryTable(byCategory: costs.byCategory),
        ),
      ],
    );
  }
}

class _CostTrendChart extends StatelessWidget {
  final List<CostTrendPoint> trend;
  const _CostTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final labels = trend.map((e) => e.month).toList();
    final categories = [
      (name: 'Fasilitator', values: trend.map((e) => e.facilitator).toList()),
      (name: 'Komisi', values: trend.map((e) => e.commission).toList()),
      (name: 'Operasional', values: trend.map((e) => e.operational).toList()),
      (name: 'Marketing', values: trend.map((e) => e.marketing).toList()),
      (name: 'Investasi', values: trend.map((e) => e.investment).toList()),
    ];

    double maxY = 0;
    for (final cat in categories) {
      for (int i = 0; i < cat.values.length; i++) {
        double sum = 0;
        for (final c2 in categories) {
          sum += c2.values[i];
        }
        if (sum > maxY) maxY = sum;
      }
    }
    if (maxY == 0) maxY = 1;

    final barGroups = trend.asMap().entries.map((entry) {
      final i = entry.key;
      double fromY = 0;
      final rods = categories.asMap().entries.map((catEntry) {
        final ci = catEntry.key;
        final cat = catEntry.value;
        final toY = fromY + cat.values[i];
        final rod = BarChartRodStackItem(
          fromY,
          toY,
          AppColors.chartColors[ci % AppColors.chartColors.length],
        );
        fromY = toY;
        return rod;
      }).toList();

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: fromY,
            rodStackItems: rods,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        maxY: maxY * 1.15,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                final label = labels[idx];
                final short = label.length > 3 ? label.substring(0, 3) : label;
                return Text(short,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                _formatAmountShort(value),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _CostByCategoryTable extends StatelessWidget {
  final List<CostByCategory> byCategory;
  const _CostByCategoryTable({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) return const _EmptyData();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: AppDimensions.tableHeaderHeight,
        dataRowMinHeight: AppDimensions.tableRowHeight,
        dataRowMaxHeight: AppDimensions.tableRowHeight,
        columns: const [
          DataColumn(label: Text('Kategori')),
          DataColumn(label: Text('Jumlah'), numeric: true),
          DataColumn(label: Text('%'), numeric: true),
          DataColumn(label: Text('vs Bln Lalu'), numeric: true),
          DataColumn(label: Text('Tren'), numeric: true),
        ],
        rows: byCategory.map((item) {
          final vsIsUp = item.vsLastMonth >= 0;
          final trendIsUp = item.trend >= 0;
          return DataRow(cells: [
            DataCell(Text(item.category)),
            DataCell(Text(_formatAmount(item.amount))),
            DataCell(Text('${item.percentage.toStringAsFixed(1)}%')),
            DataCell(Text(
              '${vsIsUp ? '+' : ''}${item.vsLastMonth.toStringAsFixed(1)}%',
              style: TextStyle(
                  color: vsIsUp ? AppColors.error : AppColors.success,
                  fontSize: 13),
            )),
            DataCell(Row(children: [
              Icon(
                trendIsUp ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: trendIsUp ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 2),
              Text(
                '${item.trend.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 12,
                    color: trendIsUp ? AppColors.error : AppColors.success),
              ),
            ])),
          ]);
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 4: Profitabilitas Batch
// ---------------------------------------------------------------------------

class _BatchProfitSection extends StatelessWidget {
  final BatchProfitAnalysisEntity batchProfit;
  const _BatchProfitSection({required this.batchProfit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionCard(
                title: 'Top 10 Batch — Margin Tertinggi',
                child: _BatchProfitTable(
                  batches: batchProfit.topBatches,
                  isTop: true,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _SectionCard(
                title: 'Bottom 10 Batch — Margin Terendah',
                child: _BatchProfitTable(
                  batches: batchProfit.bottomBatches,
                  isTop: false,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        _SectionCard(
          title: 'Distribusi Margin Batch (Histogram)',
          child: SizedBox(
            height: 240,
            child: batchProfit.histogram.isEmpty
                ? const _EmptyChart()
                : _HistogramChart(histogram: batchProfit.histogram),
          ),
        ),
      ],
    );
  }
}

class _BatchProfitTable extends StatelessWidget {
  final List<BatchProfitEntity> batches;
  final bool isTop;
  const _BatchProfitTable({required this.batches, required this.isTop});

  @override
  Widget build(BuildContext context) {
    if (batches.isEmpty) return const _EmptyData();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: AppDimensions.tableHeaderHeight,
        dataRowMinHeight: AppDimensions.tableRowHeight,
        dataRowMaxHeight: AppDimensions.tableRowHeight,
        columns: const [
          DataColumn(label: Text('Kode Batch')),
          DataColumn(label: Text('Kelas')),
          DataColumn(label: Text('Revenue'), numeric: true),
          DataColumn(label: Text('Biaya'), numeric: true),
          DataColumn(label: Text('Profit'), numeric: true),
          DataColumn(label: Text('Margin'), numeric: true),
        ],
        rows: batches.map((item) {
          final isPositive = item.profit >= 0;
          return DataRow(cells: [
            DataCell(Text(
              item.batchCode,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.primary,
              ),
            )),
            DataCell(Text(
              item.courseName,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(Text(_formatAmount(item.revenue))),
            DataCell(Text(_formatAmount(item.expenditure + item.commission))),
            DataCell(Text(
              _formatAmount(item.profit),
              style: TextStyle(
                color: isPositive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            )),
            DataCell(Text(
              '${item.marginPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isPositive ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

class _HistogramChart extends StatelessWidget {
  final List<HistogramBucket> histogram;
  const _HistogramChart({required this.histogram});

  @override
  Widget build(BuildContext context) {
    final maxY = histogram.fold(0, (prev, e) => e.count > prev ? e.count : prev);

    final barGroups = histogram.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: e.count.toDouble(),
            color: AppColors.chartColors[i % AppColors.chartColors.length],
            width: 32,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        maxY: (maxY * 1.2).toDouble(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= histogram.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    histogram[idx].rangeLabel,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 5: Proyeksi Kas
// ---------------------------------------------------------------------------

class _CashForecastSection extends StatelessWidget {
  final CashForecastEntity cashForecast;
  const _CashForecastSection({required this.cashForecast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: 'Proyeksi Arus Kas 3 Bulan',
          child: SizedBox(
            height: 260,
            child: cashForecast.projection.isEmpty
                ? const _EmptyChart()
                : _CashForecastChart(projection: cashForecast.projection),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        _SectionCard(
          title: 'Agenda Kas Mendatang',
          child: _CashEventsTable(events: cashForecast.upcomingEvents),
        ),
      ],
    );
  }
}

class _CashForecastChart extends StatelessWidget {
  final List<CashForecastPoint> projection;
  const _CashForecastChart({required this.projection});

  @override
  Widget build(BuildContext context) {
    final labels = projection.map((e) => e.month).toList();

    double maxY = 0;
    for (final p in projection) {
      if (p.projectedCash > maxY) maxY = p.projectedCash;
      if (p.projectedInflow > maxY) maxY = p.projectedInflow;
      if (p.projectedOutflow > maxY) maxY = p.projectedOutflow;
    }
    if (maxY == 0) maxY = 1;

    final lineBarsData = [
      LineChartBarData(
        spots: projection.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.projectedCash))
            .toList(),
        isCurved: true,
        color: AppColors.chartColors[0],
        barWidth: 2.5,
        dotData: const FlDotData(show: true),
      ),
      LineChartBarData(
        spots: projection.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.projectedInflow))
            .toList(),
        isCurved: true,
        color: AppColors.chartColors[1],
        barWidth: 2,
        dotData: const FlDotData(show: false),
        dashArray: [4, 4],
      ),
      LineChartBarData(
        spots: projection.asMap().entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.projectedOutflow))
            .toList(),
        isCurved: true,
        color: AppColors.chartColors[3],
        barWidth: 2,
        dotData: const FlDotData(show: false),
        dashArray: [4, 4],
      ),
    ];

    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        minY: 0,
        maxY: maxY * 1.15,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  labels[idx],
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                _formatAmountShort(value),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _CashEventsTable extends StatelessWidget {
  final List<CashEventEntity> events;
  const _CashEventsTable({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const _EmptyData();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: AppDimensions.tableHeaderHeight,
        dataRowMinHeight: AppDimensions.tableRowHeight,
        dataRowMaxHeight: AppDimensions.tableRowHeight,
        columns: const [
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Tipe')),
          DataColumn(label: Text('Keterangan')),
          DataColumn(label: Text('Jumlah'), numeric: true),
          DataColumn(label: Text('Status')),
        ],
        rows: events.map((item) {
          return DataRow(cells: [
            DataCell(Text(item.date)),
            DataCell(_EventTypePill(type: item.type)),
            DataCell(Text(
              item.description,
              overflow: TextOverflow.ellipsis,
            )),
            DataCell(Text(
              _formatAmount(item.amount),
              style: TextStyle(
                color: item.type == 'outflow'
                    ? AppColors.error
                    : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            )),
            DataCell(_StatusPill(status: item.status)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _EventTypePill extends StatelessWidget {
  final String type;
  const _EventTypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (type) {
      case 'inflow':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        label = 'Masuk';
        break;
      case 'outflow':
        bg = AppColors.errorSurface;
        fg = AppColors.error;
        label = 'Keluar';
        break;
      default:
        bg = AppColors.infoSurface;
        fg = AppColors.info;
        label = type;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        label = 'Dikonfirmasi';
        break;
      case 'pending':
        bg = AppColors.warningSurface;
        fg = AppColors.warning;
        label = 'Menunggu';
        break;
      case 'projected':
        bg = AppColors.infoSurface;
        fg = AppColors.info;
        label = 'Proyeksi';
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11)),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 6: Peringatan & Rekomendasi
// ---------------------------------------------------------------------------

class _AlertsSection extends StatelessWidget {
  final List<FinanceAlertEntity> alerts;
  final List<FinanceAlertEntity> suggestions;

  const _AlertsSection({
    required this.alerts,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SectionCard(
            title: 'Peringatan Keuangan',
            child: alerts.isEmpty
                ? const _EmptyData()
                : Column(
                    children: alerts
                        .map((a) => _AlertItem(alert: a))
                        .toList(),
                  ),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _SectionCard(
            title: 'Rekomendasi',
            child: suggestions.isEmpty
                ? const _EmptyData()
                : Column(
                    children: suggestions
                        .map((s) => _SuggestionItem(suggestion: s))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AlertItem extends StatelessWidget {
  final FinanceAlertEntity alert;
  const _AlertItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData icon;
    Color bgColor;
    switch (alert.type) {
      case 'warning':
        iconColor = AppColors.warning;
        bgColor = AppColors.warningSurface;
        icon = Icons.warning_amber_outlined;
        break;
      case 'success':
        iconColor = AppColors.success;
        bgColor = AppColors.successSurface;
        icon = Icons.check_circle_outline;
        break;
      default:
        iconColor = AppColors.info;
        bgColor = AppColors.infoSurface;
        icon = Icons.info_outline;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.iconMd, color: iconColor),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final FinanceAlertEntity suggestion;
  const _SuggestionItem({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline,
              size: AppDimensions.iconMd, color: AppColors.primaryLight),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              suggestion.message,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 40, color: AppColors.textHint),
          SizedBox(height: AppDimensions.sm),
          Text(
            'Belum ada data',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _EmptyData extends StatelessWidget {
  const _EmptyData();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.lg),
      child: Center(
        child: Text(
          'Belum ada data tersedia',
          style: TextStyle(fontSize: 13, color: AppColors.textHint),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatAmount(double amount) {
  if (amount >= 1000000000) {
    return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
  }
  if (amount >= 1000000) {
    return 'Rp ${(amount / 1000000).toStringAsFixed(1)} jt';
  }
  if (amount >= 1000) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)} rb';
  }
  return 'Rp ${amount.toStringAsFixed(0)}';
}

String _formatAmountShort(double amount) {
  if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(0)}M';
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(0)}jt';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}rb';
  return amount.toStringAsFixed(0);
}
