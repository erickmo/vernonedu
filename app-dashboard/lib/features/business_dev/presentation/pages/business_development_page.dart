import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/okr_entity.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/entities/delegation_entity.dart';
import '../cubit/biz_dev_cubit.dart';
import '../cubit/biz_dev_state.dart';

class BusinessDevelopmentPage extends StatelessWidget {
  const BusinessDevelopmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BizDevCubit>()..loadAll(),
      child: const _BusinessDevelopmentView(),
    );
  }
}

class _BusinessDevelopmentView extends StatelessWidget {
  const _BusinessDevelopmentView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BizDevCubit, BizDevState>(
      builder: (context, state) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.lg,
                  AppDimensions.lg,
                  AppDimensions.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Business Development',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'Kelola partner, cabang, OKR, investasi, proyeksi, dan delegasi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (state is BizDevLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state is BizDevError)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: AppDimensions.md),
                      Text(state.message,
                          style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: AppDimensions.md),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<BizDevCubit>().loadAll(),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (state is BizDevLoaded)
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.lg),
                    child: Column(
                      children: [
                        _PartnerSection(state: state),
                        const SizedBox(height: AppDimensions.lg),
                        _BranchSection(state: state),
                        const SizedBox(height: AppDimensions.lg),
                        _OkrSection(state: state),
                        const SizedBox(height: AppDimensions.lg),
                        _InvestmentSection(state: state),
                        const SizedBox(height: AppDimensions.lg),
                        _FinancialProjectionSection(),
                        const SizedBox(height: AppDimensions.lg),
                        _DelegationSection(state: state),
                        const SizedBox(height: AppDimensions.xl),
                      ],
                    ),
                  ),
                ]),
              )
            else
              const SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }
}

// ─── Section Wrapper ─────────────────────────────────────────────────────────

class _SectionWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.md,
              AppDimensions.lg,
              AppDimensions.sm,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Number Card ─────────────────────────────────────────────────────────────

class _NumberCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _NumberCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: iconColor ?? AppColors.primary,
                size: AppDimensions.iconLg),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Partner Section ─────────────────────────────────────────────────────────

class _PartnerSection extends StatefulWidget {
  final BizDevLoaded state;
  const _PartnerSection({required this.state});

  @override
  State<_PartnerSection> createState() => _PartnerSectionState();
}

class _PartnerSectionState extends State<_PartnerSection> {
  String _search = '';
  String _statusFilter = '';
  int _page = 0;
  static const int _pageSize = 15;

  @override
  Widget build(BuildContext context) {
    final stats = widget.state.partnerStats;
    final allPartners = widget.state.partners;

    final filtered = allPartners.where((p) {
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.industry.toLowerCase().contains(_search.toLowerCase());
      final matchStatus =
          _statusFilter.isEmpty || p.status == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageData = filtered.sublist(start, end);

    return _SectionWrapper(
      title: 'Partners',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberCard(
                label: 'Aktif',
                value: stats.activeCount.toString(),
                icon: Icons.handshake_outlined,
                iconColor: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Akan Expired',
                value: stats.expiringCount.toString(),
                icon: Icons.warning_amber_outlined,
                iconColor: AppColors.warning,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Negosiasi',
                value: stats.negotiatingCount.toString(),
                icon: Icons.forum_outlined,
                iconColor: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Belum Diapproach',
                value: stats.uncontactedCount.toString(),
                icon: Icons.person_outline,
                iconColor: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari partner...',
                      prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.sm),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (v) => setState(() {
                      _search = v;
                      _page = 0;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter.isEmpty ? null : _statusFilter,
                  hint: const Text('Semua Status'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua Status')),
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(
                        value: 'negotiating', child: Text('Negosiasi')),
                    DropdownMenuItem(value: 'prospect', child: Text('Prospek')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Tidak Aktif')),
                  ],
                  onChanged: (v) => setState(() {
                    _statusFilter = v ?? '';
                    _page = 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 320,
            child: pageData.isEmpty
                ? const Center(child: Text('Tidak ada data partner'))
                : DataTable2(
                    columnSpacing: AppDimensions.sm,
                    horizontalMargin: AppDimensions.sm,
                    headingRowHeight: AppDimensions.tableHeaderHeight,
                    dataRowHeight: AppDimensions.tableRowHeight,
                    columns: const [
                      DataColumn2(label: Text('Nama'), size: ColumnSize.L),
                      DataColumn2(
                          label: Text('Industri'), size: ColumnSize.M),
                      DataColumn2(label: Text('Grup'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(
                          label: Text('Kontak'), size: ColumnSize.M),
                    ],
                    rows: pageData.map((p) {
                      return DataRow2(
                        onTap: () => context.go(
                            '/business-development/partners/${p.id}'),
                        cells: [
                          DataCell(
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(p.name,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                          DataCell(Text(p.industry)),
                          DataCell(Text(p.groupName.isEmpty ? '-' : p.groupName)),
                          DataCell(_StatusBadge(status: p.status, label: p.statusLabel)),
                          DataCell(Text(p.contactPhone.isEmpty ? p.contactEmail : p.contactPhone)),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 0
                      ? () => setState(() => _page--)
                      : null,
                ),
                Text('${_page + 1} / $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages - 1
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Branch Section ───────────────────────────────────────────────────────────

class _BranchSection extends StatefulWidget {
  final BizDevLoaded state;
  const _BranchSection({required this.state});

  @override
  State<_BranchSection> createState() => _BranchSectionState();
}

class _BranchSectionState extends State<_BranchSection> {
  String _search = '';
  int _page = 0;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final branches = widget.state.branches;
    final activeCount = widget.state.branchActiveCount;

    final filtered = branches.where((b) {
      return _search.isEmpty ||
          b.name.toLowerCase().contains(_search.toLowerCase()) ||
          b.city.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageData = filtered.sublist(start, end);

    return _SectionWrapper(
      title: 'Manajemen Cabang',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberCard(
                label: 'Cabang Aktif',
                value: activeCount.toString(),
                icon: Icons.account_tree_outlined,
                iconColor: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Total Cabang',
                value: branches.length.toString(),
                icon: Icons.business_outlined,
              ),
              const Expanded(child: SizedBox.shrink()),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: AppDimensions.buttonHeight,
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama atau kota...',
                prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (v) => setState(() {
                _search = v;
                _page = 0;
              }),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 280,
            child: pageData.isEmpty
                ? const Center(child: Text('Tidak ada data cabang'))
                : DataTable2(
                    columnSpacing: AppDimensions.sm,
                    horizontalMargin: AppDimensions.sm,
                    headingRowHeight: AppDimensions.tableHeaderHeight,
                    dataRowHeight: AppDimensions.tableRowHeight,
                    columns: const [
                      DataColumn2(label: Text('Nama'), size: ColumnSize.L),
                      DataColumn2(label: Text('Kota'), size: ColumnSize.M),
                      DataColumn2(label: Text('Partner'), size: ColumnSize.M),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    ],
                    rows: pageData.map((b) {
                      return DataRow2(
                        cells: [
                          DataCell(Text(b.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(b.city)),
                          DataCell(Text(
                              b.partnerName.isEmpty ? '-' : b.partnerName)),
                          DataCell(
                            _StatusBadge(
                              status: b.isActive ? 'active' : 'inactive',
                              label: b.isActive ? 'Aktif' : 'Tidak Aktif',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _page > 0 ? () => setState(() => _page--) : null,
                ),
                Text('${_page + 1} / $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages - 1
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── OKR Section ─────────────────────────────────────────────────────────────

class _OkrSection extends StatefulWidget {
  final BizDevLoaded state;
  const _OkrSection({required this.state});

  @override
  State<_OkrSection> createState() => _OkrSectionState();
}

class _OkrSectionState extends State<_OkrSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _levels = ['all', 'company', 'department', 'team'];
  final List<String> _levelLabels = ['Semua', 'Perusahaan', 'Departemen', 'Tim'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _levelLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objectives = widget.state.objectives;

    final onTrack = objectives.where((o) => o.status == 'on_track').length;
    final atRisk = objectives.where((o) => o.status == 'at_risk').length;
    final behind = objectives.where((o) => o.status == 'behind').length;

    return _SectionWrapper(
      title: 'OKR & KPI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberCard(
                label: 'Total Objective',
                value: objectives.length.toString(),
                icon: Icons.track_changes_outlined,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'On Track',
                value: onTrack.toString(),
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'At Risk',
                value: atRisk.toString(),
                icon: Icons.warning_amber_outlined,
                iconColor: AppColors.warning,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Behind',
                value: behind.toString(),
                icon: Icons.cancel_outlined,
                iconColor: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: _levelLabels
                .map((l) => Tab(text: l))
                .toList(),
          ),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: _levels.map((level) {
                final filtered = level == 'all'
                    ? objectives
                    : objectives.where((o) => o.level == level).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('Tidak ada objective'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final obj = filtered[i];
                    return _OkrObjectiveTile(objective: obj);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OkrObjectiveTile extends StatelessWidget {
  final OkrObjectiveEntity objective;
  const _OkrObjectiveTile({required this.objective});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            child: Text(objective.title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: AppDimensions.sm),
          _StatusBadge(
              status: objective.status, label: objective.statusLabel),
          const SizedBox(width: AppDimensions.sm),
          Text('${objective.progress}%',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
      subtitle: Text(
        '${objective.ownerName.isNotEmpty ? objective.ownerName : 'Tidak ada pemilik'} · ${objective.period}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      children: objective.keyResults.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.all(AppDimensions.sm),
                child: Text('Tidak ada key result',
                    style: TextStyle(color: AppColors.textHint)),
              )
            ]
          : objective.keyResults.map((kr) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.keyboard_arrow_right,
                    color: AppColors.textSecondary),
                title: Text(kr.title),
                trailing: Text('${kr.progress}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              );
            }).toList(),
    );
  }
}

// ─── Investment Section ───────────────────────────────────────────────────────

class _InvestmentSection extends StatefulWidget {
  final BizDevLoaded state;
  const _InvestmentSection({required this.state});

  @override
  State<_InvestmentSection> createState() => _InvestmentSectionState();
}

class _InvestmentSectionState extends State<_InvestmentSection> {
  int _page = 0;
  static const int _pageSize = 10;

  String _formatCurrency(int amount) {
    final f = NumberFormat.compact(locale: 'id');
    return 'Rp ${f.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.state.investmentStats;
    final investments = widget.state.investments;

    final totalPages = (investments.length / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, investments.length);
    final pageData = investments.sublist(start, end);

    return _SectionWrapper(
      title: 'Rencana Investasi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberCard(
                label: 'Total Direncanakan',
                value: _formatCurrency(stats.totalPlanned),
                icon: Icons.savings_outlined,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Berjalan',
                value: stats.ongoingCount.toString(),
                icon: Icons.trending_up_outlined,
                iconColor: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Selesai',
                value: stats.completedCount.toString(),
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Avg ROI',
                value: '${stats.avgRoi.toStringAsFixed(1)}%',
                icon: Icons.percent_outlined,
                iconColor: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          SizedBox(
            height: 280,
            child: pageData.isEmpty
                ? const Center(child: Text('Tidak ada rencana investasi'))
                : DataTable2(
                    columnSpacing: AppDimensions.sm,
                    horizontalMargin: AppDimensions.sm,
                    headingRowHeight: AppDimensions.tableHeaderHeight,
                    dataRowHeight: AppDimensions.tableRowHeight,
                    columns: const [
                      DataColumn2(label: Text('Judul'), size: ColumnSize.L),
                      DataColumn2(
                          label: Text('Kategori'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Jumlah'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('ROI (%)'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    ],
                    rows: pageData.map((inv) {
                      return DataRow2(
                        cells: [
                          DataCell(Text(inv.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(inv.category.isEmpty
                              ? '-'
                              : inv.category)),
                          DataCell(Text(_formatCurrency(inv.amount))),
                          DataCell(Text(
                              '${inv.expectedRoi.toStringAsFixed(1)}%')),
                          DataCell(_StatusBadge(
                            status: inv.status,
                            label: inv.statusLabel,
                          )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _page > 0 ? () => setState(() => _page--) : null,
                ),
                Text('${_page + 1} / $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages - 1
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Financial Projections Section (Mock) ────────────────────────────────────

class _FinancialProjectionSection extends StatefulWidget {
  @override
  State<_FinancialProjectionSection> createState() =>
      _FinancialProjectionSectionState();
}

class _FinancialProjectionSectionState
    extends State<_FinancialProjectionSection> {
  String _selectedPeriod = '2026';
  String _selectedBranch = 'Semua Cabang';

  final List<_MonthData> _mockData = const [
    _MonthData('Jan', 85000000, 62000000),
    _MonthData('Feb', 92000000, 71000000),
    _MonthData('Mar', 78000000, 58000000),
    _MonthData('Apr', 105000000, 82000000),
    _MonthData('Mei', 98000000, 74000000),
    _MonthData('Jun', 115000000, 89000000),
  ];

  String _formatCurrency(int amount) {
    final f = NumberFormat.compact(locale: 'id');
    return 'Rp ${f.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _mockData.fold(0, (s, d) => s + d.revenue);
    final totalCost = _mockData.fold(0, (s, d) => s + d.cost);
    final totalProfit = totalRevenue - totalCost;

    return _SectionWrapper(
      title: 'Proyeksi Keuangan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  items: ['2025', '2026', '2027']
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedPeriod = v ?? '2026'),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBranch,
                  items: ['Semua Cabang', 'Cabang A', 'Cabang B']
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedBranch = v ?? 'Semua Cabang'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              _NumberCard(
                label: 'Proyeksi Pendapatan',
                value: _formatCurrency(totalRevenue),
                icon: Icons.trending_up_outlined,
                iconColor: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Proyeksi Biaya',
                value: _formatCurrency(totalCost),
                icon: Icons.trending_down_outlined,
                iconColor: AppColors.error,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Proyeksi Laba',
                value: _formatCurrency(totalProfit),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Margin',
                value:
                    '${((totalProfit / totalRevenue) * 100).toStringAsFixed(1)}%',
                icon: Icons.percent_outlined,
                iconColor: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Text('Proyeksi Pendapatan vs Biaya (6 Bulan)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  )),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 200,
            child: _SimpleBarChart(data: _mockData),
          ),
          const SizedBox(height: AppDimensions.lg),
          _RevenueBreakdownTable(mockData: _mockData),
        ],
      ),
    );
  }
}

class _MonthData {
  final String month;
  final int revenue;
  final int cost;
  const _MonthData(this.month, this.revenue, this.cost);
  int get profit => revenue - cost;
}

class _SimpleBarChart extends StatelessWidget {
  final List<_MonthData> data;
  const _SimpleBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0, (m, d) => d.revenue > m ? d.revenue : m);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final revenueRatio = maxVal > 0 ? d.revenue / maxVal : 0.0;
        final costRatio = maxVal > 0 ? d.cost / maxVal : 0.0;
        return Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.xs / 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: (revenueRatio * 150).toDouble(),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Container(
                        height: (costRatio * 150).toDouble(),
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(d.month,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RevenueBreakdownTable extends StatelessWidget {
  final List<_MonthData> mockData;
  const _RevenueBreakdownTable({required this.mockData});

  String _formatCurrency(int amount) {
    final f = NumberFormat.compact(locale: 'id');
    return 'Rp ${f.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rincian per Bulan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
        const SizedBox(height: AppDimensions.sm),
        SizedBox(
          height: 220,
          child: DataTable2(
            columnSpacing: AppDimensions.sm,
            horizontalMargin: AppDimensions.sm,
            headingRowHeight: AppDimensions.tableHeaderHeight,
            dataRowHeight: AppDimensions.tableRowHeight,
            columns: const [
              DataColumn2(label: Text('Bulan'), size: ColumnSize.S),
              DataColumn2(label: Text('Pendapatan'), size: ColumnSize.M),
              DataColumn2(label: Text('Biaya'), size: ColumnSize.M),
              DataColumn2(label: Text('Laba'), size: ColumnSize.M),
            ],
            rows: mockData.map((d) {
              return DataRow2(
                cells: [
                  DataCell(Text(d.month)),
                  DataCell(Text(_formatCurrency(d.revenue))),
                  DataCell(Text(_formatCurrency(d.cost))),
                  DataCell(Text(
                    _formatCurrency(d.profit),
                    style: TextStyle(
                      color: d.profit >= 0
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Delegation Section ───────────────────────────────────────────────────────

class _DelegationSection extends StatefulWidget {
  final BizDevLoaded state;
  const _DelegationSection({required this.state});

  @override
  State<_DelegationSection> createState() => _DelegationSectionState();
}

class _DelegationSectionState extends State<_DelegationSection> {
  String _statusFilter = '';
  int _page = 0;
  static const int _pageSize = 15;

  @override
  Widget build(BuildContext context) {
    final stats = widget.state.delegationStats;
    final delegations = widget.state.delegations;

    final filtered = delegations.where((d) {
      return _statusFilter.isEmpty || d.status == _statusFilter;
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageData = filtered.sublist(start, end);

    return _SectionWrapper(
      title: 'Delegasi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumberCard(
                label: 'Aktif',
                value: stats.activeCount.toString(),
                icon: Icons.assignment_ind_outlined,
                iconColor: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Menunggu',
                value: stats.pendingCount.toString(),
                icon: Icons.pending_outlined,
                iconColor: AppColors.warning,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Dikerjakan',
                value: stats.inProgressCount.toString(),
                icon: Icons.work_outline,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.sm),
              _NumberCard(
                label: 'Selesai Bulan Ini',
                value: stats.completedThisMonthCount.toString(),
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              hint: const Text('Semua Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua Status')),
                DropdownMenuItem(
                    value: 'pending', child: Text('Menunggu')),
                DropdownMenuItem(
                    value: 'accepted', child: Text('Diterima')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('Dikerjakan')),
                DropdownMenuItem(
                    value: 'completed', child: Text('Selesai')),
                DropdownMenuItem(
                    value: 'cancelled', child: Text('Dibatalkan')),
              ],
              onChanged: (v) => setState(() {
                _statusFilter = v ?? '';
                _page = 0;
              }),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          SizedBox(
            height: 320,
            child: pageData.isEmpty
                ? const Center(child: Text('Tidak ada delegasi'))
                : DataTable2(
                    columnSpacing: AppDimensions.sm,
                    horizontalMargin: AppDimensions.sm,
                    headingRowHeight: AppDimensions.tableHeaderHeight,
                    dataRowHeight: AppDimensions.tableRowHeight,
                    columns: const [
                      DataColumn2(label: Text('Judul'), size: ColumnSize.L),
                      DataColumn2(label: Text('Tipe'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Ditugaskan Ke'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Prioritas'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    ],
                    rows: pageData.map((d) {
                      return DataRow2(
                        cells: [
                          DataCell(Text(d.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                          DataCell(Text(d.typeLabel)),
                          DataCell(Text(d.assignedToName.isEmpty
                              ? '-'
                              : d.assignedToName)),
                          DataCell(
                            _PriorityBadge(priority: d.priority),
                          ),
                          DataCell(_StatusBadge(
                            status: d.status,
                            label: d.statusLabel,
                          )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _page > 0 ? () => setState(() => _page--) : null,
                ),
                Text('${_page + 1} / $totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < totalPages - 1
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'active':
      case 'on_track':
      case 'completed':
      case 'approved':
        bg = AppColors.successSurface;
        fg = AppColors.success;
        break;
      case 'negotiating':
      case 'at_risk':
      case 'pending':
      case 'proposed':
        bg = AppColors.warningSurface;
        fg = AppColors.warning;
        break;
      case 'inactive':
      case 'behind':
      case 'cancelled':
        bg = AppColors.errorSurface;
        fg = AppColors.error;
        break;
      default:
        bg = AppColors.infoSurface;
        fg = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (priority) {
      case 'urgent':
        bg = AppColors.errorSurface;
        fg = AppColors.error;
        label = 'Urgent';
        break;
      case 'high':
        bg = AppColors.warningSurface;
        fg = AppColors.warning;
        label = 'High';
        break;
      case 'medium':
        bg = AppColors.infoSurface;
        fg = AppColors.info;
        label = 'Medium';
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        label = 'Low';
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
