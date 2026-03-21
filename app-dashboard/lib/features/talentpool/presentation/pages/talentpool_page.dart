import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../domain/entities/talentpool_entity.dart';
import '../../domain/entities/job_opening_entity.dart';
import '../../domain/entities/partner_company_entity.dart';
import '../cubit/talentpool_cubit.dart';
import '../cubit/talentpool_state.dart';

class TalentPoolPage extends StatelessWidget {
  const TalentPoolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TalentPoolCubit>()..loadAll(),
      child: const _TalentPoolView(),
    );
  }
}

class _TalentPoolView extends StatefulWidget {
  const _TalentPoolView();

  @override
  State<_TalentPoolView> createState() => _TalentPoolViewState();
}

class _TalentPoolViewState extends State<_TalentPoolView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TalentPoolCubit, TalentPoolState>(
      listener: (context, state) {
        if (state is TalentPoolError) {
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
            _buildHeader(context),
            const SizedBox(height: AppDimensions.lg),
            _buildStatsRow(),
            const SizedBox(height: AppDimensions.lg),
            _buildTabBar(),
            const SizedBox(height: AppDimensions.md),
            Expanded(child: _buildTabView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TalentPool VernonEdu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                'Kelola lowongan, perusahaan rekanan, dan peserta talent pool',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
          onPressed: () => context.read<TalentPoolCubit>().loadAll(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return BlocBuilder<TalentPoolCubit, TalentPoolState>(
      builder: (context, state) {
        final loaded = state is TalentPoolLoaded ? state : null;
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.work_outline,
                label: 'Lowongan',
                value: loaded?.jobs.length ?? 0,
                color: AppColors.info,
                surface: AppColors.infoSurface,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _StatCard(
                icon: Icons.business_outlined,
                label: 'Perusahaan Rekanan',
                value: loaded?.companies.length ?? 0,
                color: AppColors.secondary,
                surface: const Color(0xFFE0F2F1),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _StatCard(
                icon: Icons.person_outline,
                label: 'Anggota Aktif',
                value: loaded?.members.where((m) => m.isActive).length ?? 0,
                color: AppColors.success,
                surface: AppColors.successSurface,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: _StatCard(
                icon: Icons.business_center_outlined,
                label: 'Berhasil Diterima',
                value: loaded?.placed.length ?? 0,
                color: AppColors.primary,
                surface: AppColors.primarySurface,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        indicator: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(AppDimensions.xs),
        tabs: const [
          Tab(
            icon: Icon(Icons.work_outline, size: AppDimensions.iconMd),
            text: 'Lowongan',
          ),
          Tab(
            icon: Icon(Icons.business_outlined, size: AppDimensions.iconMd),
            text: 'Perusahaan Rekanan',
          ),
          Tab(
            icon: Icon(Icons.people_outline, size: AppDimensions.iconMd),
            text: 'Anggota',
          ),
          Tab(
            icon:
                Icon(Icons.emoji_events_outlined, size: AppDimensions.iconMd),
            text: 'Diterima Kerja',
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: const [
        _JobOpeningsTab(),
        _PartnerCompaniesTab(),
        _MembersTab(),
        _PlacedTab(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — LOWONGAN PEKERJAAN
// ═══════════════════════════════════════════════════════════════════════════════

class _JobOpeningsTab extends StatefulWidget {
  const _JobOpeningsTab();

  @override
  State<_JobOpeningsTab> createState() => _JobOpeningsTabState();
}

class _JobOpeningsTabState extends State<_JobOpeningsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<JobOpeningEntity> _filtered(List<JobOpeningEntity> all) {
    var list = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((j) =>
              j.title.toLowerCase().contains(q) ||
              j.companyName.toLowerCase().contains(q) ||
              j.location.toLowerCase().contains(q))
          .toList();
    }
    if (_typeFilter.isNotEmpty) {
      list = list.where((j) => j.jobType == _typeFilter).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TalentPoolCubit, TalentPoolState>(
      builder: (context, state) {
        if (state is TalentPoolLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs =
            state is TalentPoolLoaded ? _filtered(state.jobs) : <JobOpeningEntity>[];

        return Column(
          children: [
            _buildFilterRow(),
            const SizedBox(height: AppDimensions.md),
            Expanded(
              child: jobs.isEmpty
                  ? _EmptyState(
                      icon: Icons.work_outline,
                      message: _searchQuery.isNotEmpty || _typeFilter.isNotEmpty
                          ? 'Tidak ada lowongan yang sesuai'
                          : 'Belum ada lowongan pekerjaan',
                    )
                  : _buildGrid(jobs),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    final types = [
      ('', 'Semua'),
      ('full_time', 'Full-time'),
      ('part_time', 'Part-time'),
      ('remote', 'Remote'),
      ('contract', 'Kontrak'),
      ('internship', 'Magang'),
    ];

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari lowongan / perusahaan...',
              prefixIcon:
                  const Icon(Icons.search, size: AppDimensions.iconMd),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: AppDimensions.iconMd),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        ...types.map((t) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.xs),
              child: _FilterPill(
                label: t.$2,
                selected: _typeFilter == t.$1,
                onTap: () => setState(() => _typeFilter = t.$1),
              ),
            )),
      ],
    );
  }

  Widget _buildGrid(List<JobOpeningEntity> jobs) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 1100 ? 3 : 2;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: AppDimensions.md,
          crossAxisSpacing: AppDimensions.md,
          childAspectRatio: 1.6,
        ),
        itemCount: jobs.length,
        itemBuilder: (_, i) => _JobCard(job: jobs[i]),
      );
    });
  }
}

class _JobCard extends StatelessWidget {
  final JobOpeningEntity job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: job.isDeadlinePassed ? AppColors.error.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompanyRow(context),
          const SizedBox(height: AppDimensions.sm),
          Text(
            job.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.xs),
          _buildMetaRow(),
          const Spacer(),
          _buildBottomRow(context),
        ],
      ),
    );
  }

  Widget _buildCompanyRow(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.infoSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(Icons.business, color: AppColors.info, size: 18),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            job.companyName,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _JobTypeBadge(type: job.jobType),
      ],
    );
  }

  Widget _buildMetaRow() {
    return Wrap(
      spacing: AppDimensions.md,
      children: [
        _MetaChip(
          icon: Icons.location_on_outlined,
          label: job.location,
        ),
        _MetaChip(
          icon: Icons.payments_outlined,
          label: job.salaryRange,
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        if (job.requiredCourseName != null) ...[
          const Icon(Icons.school_outlined,
              size: AppDimensions.iconSm, color: AppColors.primary),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              job.requiredCourseName!,
              style: const TextStyle(color: AppColors.primary, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Spacer(),
        if (job.deadline != null)
          Text(
            job.isDeadlinePassed
                ? 'Deadline terlewat'
                : 'Deadline: ${DateFormat('dd MMM', 'id_ID').format(job.deadline!)}',
            style: TextStyle(
              fontSize: 11,
              color: job.isDeadlinePassed ? AppColors.error : AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — PERUSAHAAN REKANAN
// ═══════════════════════════════════════════════════════════════════════════════

class _PartnerCompaniesTab extends StatefulWidget {
  const _PartnerCompaniesTab();

  @override
  State<_PartnerCompaniesTab> createState() => _PartnerCompaniesTabState();
}

class _PartnerCompaniesTabState extends State<_PartnerCompaniesTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PartnerCompanyEntity> _filtered(List<PartnerCompanyEntity> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.industry.toLowerCase().contains(q) ||
            c.location.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TalentPoolCubit, TalentPoolState>(
      builder: (context, state) {
        if (state is TalentPoolLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final companies = state is TalentPoolLoaded
            ? _filtered(state.companies)
            : <PartnerCompanyEntity>[];

        return Column(
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari perusahaan / industri...',
                  prefixIcon:
                      const Icon(Icons.search, size: AppDimensions.iconMd),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: AppDimensions.iconMd),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Expanded(
              child: companies.isEmpty
                  ? _EmptyState(
                      icon: Icons.business_outlined,
                      message: _searchQuery.isNotEmpty
                          ? 'Tidak ada perusahaan yang sesuai'
                          : 'Belum ada perusahaan rekanan',
                    )
                  : _buildGrid(companies),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(List<PartnerCompanyEntity> companies) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 1100 ? 3 : 2;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: AppDimensions.md,
          crossAxisSpacing: AppDimensions.md,
          childAspectRatio: 1.8,
        ),
        itemCount: companies.length,
        itemBuilder: (_, i) => _CompanyCard(company: companies[i]),
      );
    });
  }
}

class _CompanyCard extends StatelessWidget {
  final PartnerCompanyEntity company;

  const _CompanyCard({required this.company});

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
          _buildHeader(context),
          const SizedBox(height: AppDimensions.sm),
          if (company.description != null && company.description!.isNotEmpty)
            Text(
              company.description!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.secondaryDark.withValues(alpha: 0.1),
          child: Text(
            company.initials,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                company.industry,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        if (!company.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: const Text(
              'Nonaktif',
              style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined,
            size: AppDimensions.iconSm, color: AppColors.textHint),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            company.location,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _CountChip(
          icon: Icons.person_outline,
          value: company.totalHired,
          label: 'Rekrut',
          color: AppColors.success,
        ),
        const SizedBox(width: AppDimensions.sm),
        _CountChip(
          icon: Icons.work_outline,
          value: company.activeJobCount,
          label: 'Lowongan',
          color: AppColors.info,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — ANGGOTA TALENT POOL
// ═══════════════════════════════════════════════════════════════════════════════

class _MembersTab extends StatefulWidget {
  const _MembersTab();

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TalentPoolEntity> _filtered(List<TalentPoolEntity> all) {
    var list = all;
    if (_statusFilter.isNotEmpty) {
      list = list.where((t) => t.talentpoolStatus == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.participantName.toLowerCase().contains(q) ||
              t.participantEmail.toLowerCase().contains(q) ||
              t.courseName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TalentPoolCubit, TalentPoolState>(
      builder: (context, state) {
        if (state is TalentPoolLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = state is TalentPoolLoaded ? state.members : <TalentPoolEntity>[];
        final filtered = _filtered(members);

        return Column(
          children: [
            _buildFilterRow(members),
            const SizedBox(height: AppDimensions.md),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      icon: Icons.people_outline,
                      message: _searchQuery.isNotEmpty || _statusFilter.isNotEmpty
                          ? 'Tidak ada anggota yang sesuai'
                          : 'Belum ada anggota talent pool',
                    )
                  : _TalentPoolTable(talents: filtered),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow(List<TalentPoolEntity> all) {
    final activeCount = all.where((t) => t.isActive).length;
    final inactiveCount = all.where((t) => t.isInactive).length;

    return Row(
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari nama / email...',
              prefixIcon:
                  const Icon(Icons.search, size: AppDimensions.iconMd),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: AppDimensions.iconMd),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        _FilterPill(
          label: 'Semua (${all.length})',
          selected: _statusFilter.isEmpty,
          onTap: () => setState(() => _statusFilter = ''),
        ),
        const SizedBox(width: AppDimensions.xs),
        _FilterPill(
          label: 'Aktif ($activeCount)',
          selected: _statusFilter == 'active',
          color: AppColors.success,
          onTap: () => setState(() => _statusFilter = 'active'),
        ),
        const SizedBox(width: AppDimensions.xs),
        _FilterPill(
          label: 'Nonaktif ($inactiveCount)',
          selected: _statusFilter == 'inactive',
          color: AppColors.textSecondary,
          onTap: () => setState(() => _statusFilter = 'inactive'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — BERHASIL DITERIMA KERJA
// ═══════════════════════════════════════════════════════════════════════════════

class _PlacedTab extends StatefulWidget {
  const _PlacedTab();

  @override
  State<_PlacedTab> createState() => _PlacedTabState();
}

class _PlacedTabState extends State<_PlacedTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TalentPoolEntity> _filtered(List<TalentPoolEntity> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((t) =>
            t.participantName.toLowerCase().contains(q) ||
            t.participantEmail.toLowerCase().contains(q) ||
            t.courseName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TalentPoolCubit, TalentPoolState>(
      builder: (context, state) {
        if (state is TalentPoolLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final placed = state is TalentPoolLoaded ? state.placed : <TalentPoolEntity>[];
        final filtered = _filtered(placed);

        return Column(
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Cari nama / perusahaan...',
                  prefixIcon:
                      const Icon(Icons.search, size: AppDimensions.iconMd),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: AppDimensions.iconMd),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      icon: Icons.emoji_events_outlined,
                      message: _searchQuery.isNotEmpty
                          ? 'Tidak ada anggota yang sesuai'
                          : 'Belum ada anggota yang diterima kerja',
                    )
                  : _buildPlacedGrid(filtered),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlacedGrid(List<TalentPoolEntity> placed) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 1100 ? 3 : 2;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: AppDimensions.md,
          crossAxisSpacing: AppDimensions.md,
          childAspectRatio: 1.9,
        ),
        itemCount: placed.length,
        itemBuilder: (_, i) => _PlacedCard(talent: placed[i]),
      );
    });
  }
}

class _PlacedCard extends StatelessWidget {
  final TalentPoolEntity talent;

  const _PlacedCard({required this.talent});

  @override
  Widget build(BuildContext context) {
    final lastPlacement =
        talent.placementHistory.isNotEmpty ? talent.placementHistory.last : null;
    final placedAt = lastPlacement?['placed_at'] != null
        ? DateTime.tryParse(lastPlacement!['placed_at'].toString())
        : null;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primarySurface.withValues(alpha: 0.5),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppDimensions.sm),
          if (lastPlacement != null) ...[
            _buildPlacementInfo(lastPlacement),
          ],
          const Spacer(),
          _buildFooter(placedAt),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primarySurface,
          child: Text(
            talent.participantName.isNotEmpty
                ? talent.participantName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                talent.participantName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                talent.courseName,
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (talent.testScore != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Text(
              talent.testScore!.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlacementInfo(Map<String, dynamic> placement) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (placement['position'] != null)
          Row(
            children: [
              const Icon(Icons.badge_outlined,
                  size: AppDimensions.iconSm, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  placement['position'].toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (placement['company'] != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: AppDimensions.iconSm, color: AppColors.textHint),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  placement['company'].toString(),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(DateTime? placedAt) {
    return Row(
      children: [
        const Icon(Icons.email_outlined,
            size: AppDimensions.iconSm, color: AppColors.textHint),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            talent.participantEmail,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (placedAt != null)
          Text(
            DateFormat('MMM yyyy', 'id_ID').format(placedAt),
            style: const TextStyle(
                color: AppColors.textHint, fontSize: 11),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED — TABLE (digunakan di Tab 3)
// ═══════════════════════════════════════════════════════════════════════════════

class _TalentPoolTable extends StatelessWidget {
  final List<TalentPoolEntity> talents;

  const _TalentPoolTable({required this.talents});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: AppDimensions.md,
            horizontalMargin: AppDimensions.md,
            headingRowHeight: AppDimensions.tableHeaderHeight,
            dataRowMinHeight: AppDimensions.tableRowHeight,
            dataRowMaxHeight: AppDimensions.tableRowHeight,
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            columns: const [
              DataColumn(label: Text('Nama')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Score')),
              DataColumn(label: Text('Course')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Bergabung')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: talents.map((t) => _buildRow(context, t)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, TalentPoolEntity t) {
    return DataRow(cells: [
      DataCell(_AvatarNameCell(
          name: t.participantName, subtitle: t.participantEmail)),
      DataCell(Text(t.participantEmail,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary))),
      DataCell(Text(
        t.testScore != null ? t.testScore!.toStringAsFixed(1) : '—',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: t.testScore != null
              ? AppColors.textPrimary
              : AppColors.textHint,
        ),
      )),
      DataCell(Text(t.courseName,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis)),
      DataCell(_StatusBadge(status: t.talentpoolStatus)),
      DataCell(Text(DateFormatUtil.toDisplay(t.joinedAt),
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary))),
      DataCell(_buildActions(context, t)),
    ]);
  }

  Widget _buildActions(BuildContext context, TalentPoolEntity t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (t.isActive)
          _ActionButton(
            label: 'Placed',
            color: AppColors.primary,
            onPressed: () => _showPlacedDialog(context, t),
          ),
        if (t.isActive) const SizedBox(width: AppDimensions.xs),
        if (t.isActive || t.isPlaced)
          _ActionButton(
            label: 'Nonaktif',
            color: AppColors.error,
            outlined: true,
            onPressed: () async {
              final confirmed = await _confirm(
                context,
                'Nonaktifkan ${t.participantName}?',
              );
              if (confirmed && context.mounted) {
                context
                    .read<TalentPoolCubit>()
                    .updateStatus(t.id, 'inactive', null);
              }
            },
          ),
      ],
    );
  }

  void _showPlacedDialog(BuildContext context, TalentPoolEntity t) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<TalentPoolCubit>(),
        child: _PlacedDialog(talent: t),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ya, Nonaktifkan')),
        ],
      ),
    );
    return result ?? false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final Color surface;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppDimensions.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          border: Border.all(
              color: selected ? c : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _JobTypeBadge extends StatelessWidget {
  final String type;

  const _JobTypeBadge({required this.type});

  Color get _color => switch (type.toLowerCase()) {
        'remote' => AppColors.success,
        'full_time' || 'fulltime' => AppColors.info,
        'part_time' || 'parttime' => AppColors.warning,
        'contract' => AppColors.secondary,
        'internship' => AppColors.primary,
        _ => AppColors.textSecondary,
      };

  String get _label => switch (type.toLowerCase()) {
        'full_time' || 'fulltime' => 'Full-time',
        'part_time' || 'parttime' => 'Part-time',
        'remote' => 'Remote',
        'contract' => 'Kontrak',
        'internship' => 'Magang',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSm, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          label,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _CountChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarNameCell extends StatelessWidget {
  final String name;
  final String subtitle;

  const _AvatarNameCell({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primarySurface,
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'active' => (AppColors.successSurface, AppColors.success, 'Active'),
      'placed' => (AppColors.primarySurface, AppColors.primary, 'Placed'),
      'inactive' => (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
          'Nonaktif'
        ),
      _ => (AppColors.surfaceVariant, AppColors.textHint, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _PlacedDialog extends StatefulWidget {
  final TalentPoolEntity talent;

  const _PlacedDialog({required this.talent});

  @override
  State<_PlacedDialog> createState() => _PlacedDialogState();
}

class _PlacedDialogState extends State<_PlacedDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final success = await context.read<TalentPoolCubit>().updateStatus(
            widget.talent.id,
            'placed',
            {
              'company': _companyCtrl.text.trim(),
              'position': _positionCtrl.text.trim(),
              'notes': _notesCtrl.text.trim(),
              'placed_at': DateTime.now().toIso8601String(),
            },
          );
      if (success && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tandai Placed',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.talent.participantName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: AppDimensions.md),
                TextFormField(
                  controller: _companyCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Perusahaan'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _positionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Posisi / Jabatan'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
