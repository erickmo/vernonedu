import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../../../leads/domain/entities/lead_entity.dart';
import '../../../../leads/presentation/cubit/lead_cubit.dart';
import '../../../../leads/presentation/cubit/lead_state.dart';

class MarketingLeadsTab extends StatefulWidget {
  const MarketingLeadsTab({super.key});

  @override
  State<MarketingLeadsTab> createState() => _MarketingLeadsTabState();
}

class _MarketingLeadsTabState extends State<MarketingLeadsTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = '';
  String _selectedSource = '';
  int _page = 0;
  static const _pageSize = 15;

  static const _statusFilters = [
    ('', 'Semua Status'),
    ('new', 'Baru'),
    ('contacted', 'Dihubungi'),
    ('interested', 'Tertarik'),
    ('negotiating', 'Negosiasi'),
    ('enrolled', 'Enrolled'),
    ('not_interested', 'Tidak Tertarik'),
  ];

  static const _sourceFilters = [
    ('', 'Semua Sumber'),
    ('referral', 'Referral'),
    ('social_media', 'Media Sosial'),
    ('walk_in', 'Walk In'),
    ('website', 'Website'),
    ('other', 'Lainnya'),
  ];

  static const _sourceOptions = [
    ('referral', 'Referral'),
    ('social_media', 'Media Sosial'),
    ('walk_in', 'Walk In'),
    ('website', 'Website'),
    ('other', 'Lainnya'),
  ];

  static const _statusOptions = [
    ('new', 'Baru'),
    ('contacted', 'Dihubungi'),
    ('interested', 'Tertarik'),
    ('negotiating', 'Negosiasi'),
    ('enrolled', 'Enrolled'),
    ('not_interested', 'Tidak Tertarik'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LeadEntity> _filtered(List<LeadEntity> leads) {
    return leads.where((l) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          l.name.toLowerCase().contains(q) ||
          l.email.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          l.interest.toLowerCase().contains(q);
      final matchStatus =
          _selectedStatus.isEmpty || l.status == _selectedStatus;
      final matchSource =
          _selectedSource.isEmpty || l.source == _selectedSource;
      return matchSearch && matchStatus && matchSource;
    }).toList();
  }

  void _showLeadForm(BuildContext context, {LeadEntity? lead}) {
    final nameCtrl = TextEditingController(text: lead?.name ?? '');
    final emailCtrl = TextEditingController(text: lead?.email ?? '');
    final phoneCtrl = TextEditingController(text: lead?.phone ?? '');
    final interestCtrl = TextEditingController(text: lead?.interest ?? '');
    final notesCtrl = TextEditingController(text: lead?.notes ?? '');
    String selSource = lead?.source ?? 'referral';
    String selStatus = lead?.status ?? 'new';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(lead == null ? 'Tambah Lead' : 'Edit Lead'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nama *'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: phoneCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nomor Telepon'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: interestCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Minat Program'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  DropdownButtonFormField<String>(
                    value: selSource,
                    decoration: const InputDecoration(labelText: 'Sumber'),
                    items: _sourceOptions
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSt(() => selSource = v);
                    },
                  ),
                  if (lead != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    DropdownButtonFormField<String>(
                      value: selStatus,
                      decoration:
                          const InputDecoration(labelText: 'Status'),
                      items: _statusOptions
                          .map((e) => DropdownMenuItem(
                              value: e.$1, child: Text(e.$2)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSt(() => selStatus = v);
                      },
                    ),
                  ],
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Catatan',
                        alignLabelWithHint: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'interest': interestCtrl.text.trim(),
                  'source': selSource,
                  'notes': notesCtrl.text.trim(),
                  if (lead != null) 'status': selStatus,
                };
                final cubit = context.read<LeadCubit>();
                if (lead == null) {
                  cubit.createLead(data);
                } else {
                  cubit.updateLead(lead.id, data);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status, String label) {
    final color = switch (status) {
      'new' => AppColors.info,
      'contacted' => AppColors.warning,
      'interested' => AppColors.primary,
      'negotiating' => Colors.purple,
      'enrolled' => AppColors.success,
      'not_interested' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        if (state is LeadLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is LeadError) {
          return Center(child: Text(state.message));
        }
        final leads = state is LeadLoaded ? state.leads : <LeadEntity>[];
        final filtered = _filtered(leads);
        final pageCount = (filtered.length / _pageSize).ceil();
        final start = _page * _pageSize;
        final end = (start + _pageSize).clamp(0, filtered.length);
        final paginated = filtered.sublist(start, end);

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Cari nama, email, telepon...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (v) =>
                          setState(() {
                            _searchQuery = v;
                            _page = 0;
                          }),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: _statusFilters
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedStatus = v ?? '';
                      _page = 0;
                    }),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  DropdownButton<String>(
                    value: _selectedSource,
                    items: _sourceFilters
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedSource = v ?? '';
                      _page = 0;
                    }),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () => _showLeadForm(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Lead'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              // Table
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.contacts_outlined,
                                size: 48, color: AppColors.textHint),
                            SizedBox(height: AppDimensions.sm),
                            Text('Belum ada data',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : DataTable2(
                        columnSpacing: 16,
                        headingRowColor: WidgetStateProperty.all(
                            AppColors.surfaceVariant),
                        columns: const [
                          DataColumn2(label: Text('Nama'), size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Email / Telepon'),
                              size: ColumnSize.L),
                          DataColumn2(label: Text('Sumber')),
                          DataColumn2(label: Text('Minat')),
                          DataColumn2(label: Text('Status')),
                          DataColumn2(label: Text('Dibuat')),
                          DataColumn2(label: Text('Aksi'), size: ColumnSize.S),
                        ],
                        rows: paginated.map((lead) {
                          return DataRow2(cells: [
                            DataCell(Text(lead.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                            DataCell(Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (lead.email.isNotEmpty)
                                  Text(lead.email,
                                      style: const TextStyle(fontSize: 12)),
                                if (lead.phone.isNotEmpty)
                                  Text(lead.phone,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                              ],
                            )),
                            DataCell(Text(lead.sourceLabel,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(
                              lead.interest.isEmpty ? '-' : lead.interest,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(
                                _statusPill(lead.status, lead.statusLabel)),
                            DataCell(Text(
                                DateFormatUtil.toDisplay(lead.createdAt),
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 16),
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _showLeadForm(context, lead: lead),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.person_add_alt_outlined,
                                      size: 16),
                                  tooltip: 'Konversi ke Siswa',
                                  onPressed: () => context
                                      .read<LeadCubit>()
                                      .convertToStudent(lead.id),
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
              ),
              // Pagination
              if (pageCount > 1)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                          '${start + 1}–$end dari ${filtered.length}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: AppDimensions.sm),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            _page > 0 ? () => setState(() => _page--) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _page < pageCount - 1
                            ? () => setState(() => _page++)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
