import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../../leads/domain/entities/lead_entity.dart';
import '../../../leads/presentation/cubit/lead_cubit.dart';
import '../../../leads/presentation/cubit/lead_state.dart';

class CrmPage extends StatelessWidget {
  const CrmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeadCubit>()..loadLeads(limit: 200),
      child: const _CrmView(),
    );
  }
}

class _CrmView extends StatefulWidget {
  const _CrmView();

  @override
  State<_CrmView> createState() => _CrmViewState();
}

class _CrmViewState extends State<_CrmView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: AppDimensions.lg),
              _buildKpiRow(state),
              const SizedBox(height: AppDimensions.xl),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, LeadState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CRM — Customer Relationship Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor pipeline pelanggan VernonEdu',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: () => context.read<LeadCubit>().loadLeads(limit: 200),
          icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: AppDimensions.sm),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () => context.go('/leads'),
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('Tambah Lead'),
        ),
      ],
    );
  }

  // ─── KPI Stat Cards ───────────────────────────────────────────────────────

  Widget _buildKpiRow(LeadState state) {
    final leads = state is LeadLoaded ? state.leads : <LeadEntity>[];
    final total = leads.length;
    final newCount = leads.where((l) => l.status == 'new').length;
    final contactedCount = leads.where((l) => l.status == 'contacted').length;
    final convertedCount = leads.where((l) => l.status == 'converted').length;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Total Leads',
            value: total,
            icon: Icons.people_outline,
            iconColor: AppColors.info,
            surfaceColor: AppColors.infoSurface,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _KpiCard(
            label: 'Leads Baru',
            value: newCount,
            icon: Icons.fiber_new_outlined,
            iconColor: AppColors.primary,
            surfaceColor: AppColors.primarySurface,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _KpiCard(
            label: 'Dihubungi',
            value: contactedCount,
            icon: Icons.phone_in_talk_outlined,
            iconColor: AppColors.warning,
            surfaceColor: AppColors.warningSurface,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _KpiCard(
            label: 'Konversi',
            value: convertedCount,
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            surfaceColor: AppColors.successSurface,
          ),
        ),
      ],
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, LeadState state) {
    if (state is LeadLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is LeadError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              state.message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.md),
            FilledButton.icon(
              onPressed: () =>
                  context.read<LeadCubit>().loadLeads(limit: 200),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state is LeadLoaded) {
      return _buildPipeline(context, state.leads);
    }

    return const SizedBox.shrink();
  }

  // ─── Pipeline Kanban ──────────────────────────────────────────────────────

  Widget _buildPipeline(BuildContext context, List<LeadEntity> leads) {
    final newLeads = leads.where((l) => l.status == 'new').toList();
    final contactedLeads =
        leads.where((l) => l.status == 'contacted').toList();
    final convertedLeads =
        leads.where((l) => l.status == 'converted').toList();
    final lostLeads = leads.where((l) => l.status == 'lost').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pipeline Leads',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PipelineColumn(
                  title: 'Baru',
                  leads: newLeads,
                  headerColor: AppColors.infoSurface,
                  headerTextColor: AppColors.info,
                  onTap: () => context.go('/leads'),
                  onViewAll: () => context.go('/leads'),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _PipelineColumn(
                  title: 'Dihubungi',
                  leads: contactedLeads,
                  headerColor: AppColors.warningSurface,
                  headerTextColor: AppColors.warning,
                  onTap: () => context.go('/leads'),
                  onViewAll: () => context.go('/leads'),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _PipelineColumn(
                  title: 'Konversi',
                  leads: convertedLeads,
                  headerColor: AppColors.successSurface,
                  headerTextColor: AppColors.success,
                  onTap: () => context.go('/leads'),
                  onViewAll: () => context.go('/leads'),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _PipelineColumn(
                  title: 'Hilang',
                  leads: lostLeads,
                  headerColor: AppColors.errorSurface,
                  headerTextColor: AppColors.error,
                  onTap: () => context.go('/leads'),
                  onViewAll: () => context.go('/leads'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;
  final Color surfaceColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: iconColor, size: AppDimensions.iconLg),
          ),
          const SizedBox(width: AppDimensions.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pipeline Column ──────────────────────────────────────────────────────────

class _PipelineColumn extends StatelessWidget {
  final String title;
  final List<LeadEntity> leads;
  final Color headerColor;
  final Color headerTextColor;
  final VoidCallback onTap;
  final VoidCallback onViewAll;

  const _PipelineColumn({
    required this.title,
    required this.leads,
    required this.headerColor,
    required this.headerTextColor,
    required this.onTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: headerTextColor,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: headerTextColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusCircle,
                        ),
                      ),
                      child: Text(
                        '${leads.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: headerTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lead cards list
              Expanded(
                child: leads.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        itemCount: leads.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppDimensions.xs),
                        itemBuilder: (context, index) {
                          return _LeadMiniCard(lead: leads[index]);
                        },
                      ),
              ),

              // View all button
              InkWell(
                onTap: onViewAll,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusLg),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppDimensions.radiusLg),
                    ),
                  ),
                  child: Text(
                    'Lihat Semua Leads',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: headerTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.textHint,
            ),
            SizedBox(height: AppDimensions.xs),
            Text(
              'Tidak ada leads',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lead Mini Card ───────────────────────────────────────────────────────────

class _LeadMiniCard extends StatefulWidget {
  final LeadEntity lead;

  const _LeadMiniCard({required this.lead});

  @override
  State<_LeadMiniCard> createState() => _LeadMiniCardState();
}

class _LeadMiniCardState extends State<_LeadMiniCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.primarySurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lead.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (widget.lead.interest.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.lead.interest,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
            const SizedBox(height: 2),
            Text(
              DateFormatUtil.toDisplay(widget.lead.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
