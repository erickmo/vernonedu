import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/marketing_stats_entity.dart';
import '../../cubit/marketing_cubit.dart';
import '../../cubit/marketing_state.dart';

class MarketingStatsTab extends StatelessWidget {
  const MarketingStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        if (state is! MarketingLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = state.stats;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(context, stats),
              const SizedBox(height: AppDimensions.lg),
              _buildCharts(context, stats),
              const SizedBox(height: AppDimensions.lg),
              _buildExtraStats(context, stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards(BuildContext context, MarketingStatsEntity stats) {
    final leadChange = stats.leadsPrevMonth > 0
        ? ((stats.leadsThisMonth - stats.leadsPrevMonth) /
                stats.leadsPrevMonth *
                100)
            .toStringAsFixed(1)
        : '0.0';
    final isPositive = stats.leadsThisMonth >= stats.leadsPrevMonth;

    final cards = [
      _StatCard(
        title: 'Total Leads',
        value: stats.totalLeads.toString(),
        icon: Icons.contacts_outlined,
        color: AppColors.primary,
      ),
      _StatCard(
        title: 'Leads Bulan Ini',
        value: stats.leadsThisMonth.toString(),
        icon: Icons.person_add_outlined,
        color: AppColors.info,
        subtitle:
            '${isPositive ? '+' : ''}$leadChange% vs bulan lalu',
        subtitleColor: isPositive ? AppColors.success : AppColors.error,
      ),
      _StatCard(
        title: 'Konversi Lead→Siswa',
        value: '${stats.leadToStudentPct.toStringAsFixed(1)}%',
        icon: Icons.trending_up_outlined,
        color: AppColors.success,
      ),
      _StatCard(
        title: 'Posting Terjadwal',
        value: stats.scheduledPosts.toString(),
        icon: Icons.schedule_outlined,
        color: AppColors.warning,
      ),
      _StatCard(
        title: 'Posting Selesai',
        value: stats.postedThisMonth.toString(),
        icon: Icons.check_circle_outline,
        color: AppColors.secondary,
        subtitle: 'Bulan ini',
      ),
      _StatCard(
        title: 'Partner Referral Aktif',
        value: stats.activeReferralPartners.toString(),
        icon: Icons.group_outlined,
        color: AppColors.lavenderMid,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppDimensions.md,
      mainAxisSpacing: AppDimensions.md,
      childAspectRatio: 2.4,
      children: cards,
    );
  }

  Widget _buildCharts(BuildContext context, MarketingStatsEntity stats) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLineChart(context, stats)),
        const SizedBox(width: AppDimensions.md),
        Expanded(child: _buildBarChart(context)),
      ],
    );
  }

  Widget _buildLineChart(
      BuildContext context, MarketingStatsEntity stats) {
    // Mock 6-month data using available stats
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'];
    final values = [
      stats.leadsPrevMonth * 0.6,
      stats.leadsPrevMonth * 0.8,
      stats.leadsPrevMonth * 0.9,
      stats.leadsPrevMonth.toDouble(),
      stats.leadsThisMonth * 0.9,
      stats.leadsThisMonth.toDouble(),
    ];

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
          Text(
            'Akuisisi Leads (6 Bulan)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(months[idx],
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      values.length,
                      (i) => FlSpot(i.toDouble(), values[i]),
                    ),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
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

  Widget _buildBarChart(BuildContext context) {
    final sources = ['Sosmed', 'Referral', 'Website', 'Walk-in', 'Lainnya'];
    final values = [35.0, 25.0, 20.0, 12.0, 8.0];
    final colors = AppColors.chartColors;

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
          Text(
            'Konversi per Sumber',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sources.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(sources[idx],
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  values.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: colors[i % colors.length],
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraStats(
      BuildContext context, MarketingStatsEntity stats) {
    final currFmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Pendapatan Referral',
            value: currFmt.format(stats.referralRevenueThisMonth),
            icon: Icons.payments_outlined,
            color: AppColors.success,
            subtitle: 'Bulan ini',
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            title: 'Batch Dipromosikan',
            value: '0',
            icon: Icons.campaign_outlined,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            title: 'Rata-rata Lead→Enrollment',
            value: '0 hari',
            icon: Icons.timer_outlined,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final Color? subtitleColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.subtitleColor,
  });

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconMd),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor ?? AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
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
