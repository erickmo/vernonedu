import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/crm_log_entity.dart';
import '../../domain/entities/lead_entity.dart';
import '../cubit/lead_cubit.dart';
import '../cubit/lead_state.dart';

class LeadsPage extends StatelessWidget {
  const LeadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeadCubit>()..loadLeads(),
      child: const _LeadsView(),
    );
  }
}

class _LeadsView extends StatefulWidget {
  const _LeadsView();

  @override
  State<_LeadsView> createState() => _LeadsViewState();
}

class _LeadsViewState extends State<_LeadsView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = '';

  static const _statusFilters = [
    ('', 'Semua'),
    ('new', 'Baru'),
    ('contacted', 'Dihubungi'),
    ('interested', 'Tertarik'),
    ('negotiating', 'Negosiasi'),
    ('enrolled', 'Enrolled'),
    ('not_interested', 'Tidak Tertarik'),
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
    return leads.where((lead) {
      final matchSearch = _searchQuery.isEmpty ||
          lead.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lead.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lead.phone.contains(_searchQuery) ||
          lead.interest.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStatus =
          _selectedStatus.isEmpty || lead.status == _selectedStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  void _showLeadForm(BuildContext context, {LeadEntity? lead}) {
    final nameCtrl = TextEditingController(text: lead?.name ?? '');
    final emailCtrl = TextEditingController(text: lead?.email ?? '');
    final phoneCtrl = TextEditingController(text: lead?.phone ?? '');
    final interestCtrl = TextEditingController(text: lead?.interest ?? '');
    final notesCtrl = TextEditingController(text: lead?.notes ?? '');
    String selectedSource = lead?.source ?? 'referral';
    String selectedStatus = lead?.status ?? 'new';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lead == null ? 'Tambah Lead' : 'Edit Lead'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama *',
                      hintText: 'Nama calon siswa',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'contoh@email.com',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      hintText: '08xxxxxxxxxx',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: interestCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Minat Program',
                      hintText: 'Program yang diminati',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  DropdownButtonFormField<String>(
                    value: selectedSource,
                    decoration: const InputDecoration(labelText: 'Sumber'),
                    items: _sourceOptions
                        .map((e) => DropdownMenuItem(
                              value: e.$1,
                              child: Text(e.$2),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedSource = v);
                    },
                  ),
                  if (lead != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statusOptions
                          .map((e) => DropdownMenuItem(
                                value: e.$1,
                                child: Text(e.$2),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedStatus = v);
                      },
                    ),
                  ],
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Catatan tambahan',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'interest': interestCtrl.text.trim(),
                  'source': selectedSource,
                  'notes': notesCtrl.text.trim(),
                  if (lead != null) 'status': selectedStatus,
                };
                if (lead == null) {
                  context.read<LeadCubit>().createLead(data);
                } else {
                  context.read<LeadCubit>().updateLead(lead.id, data);
                }
                Navigator.pop(ctx);
              },
              child: Text(lead == null ? 'Simpan' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LeadEntity lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lead'),
        content: Text('Yakin ingin menghapus lead "${lead.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<LeadCubit>().deleteLead(lead.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showLeadDetail(BuildContext context, LeadEntity lead) {
    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: context.read<LeadCubit>(),
        child: _LeadDetailDialog(lead: lead),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadCubit, LeadState>(
      listener: (context, state) {
        if (state is LeadError) {
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
            BlocBuilder<LeadCubit, LeadState>(
              builder: (context, state) {
                if (state is LeadLoaded) {
                  return _buildStatCards(state.leads);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppDimensions.lg),
            _buildSearchAndFilter(context),
            const SizedBox(height: AppDimensions.md),
            Expanded(child: _buildContent(context)),
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
                'Manajemen Leads',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola prospek dan calon siswa',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: () => context.read<LeadCubit>().loadLeads(),
          icon: const Icon(Icons.refresh, size: AppDimensions.iconMd),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: AppDimensions.sm),
        FilledButton.icon(
          onPressed: () => _showLeadForm(context),
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('Tambah Lead'),
        ),
      ],
    );
  }

  Widget _buildStatCards(List<LeadEntity> leads) {
    final total = leads.length;
    final newCount = leads.where((l) => l.status == 'new').length;
    final contactedCount = leads.where((l) => l.status == 'contacted').length;
    final enrolledCount = leads.where((l) => l.status == 'enrolled').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Leads',
            value: total,
            color: AppColors.primary,
            surfaceColor: AppColors.primarySurface,
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            label: 'Baru',
            value: newCount,
            color: AppColors.info,
            surfaceColor: AppColors.infoSurface,
            icon: Icons.fiber_new_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            label: 'Dihubungi',
            value: contactedCount,
            color: AppColors.warning,
            surfaceColor: AppColors.warningSurface,
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: _StatCard(
            label: 'Enrolled',
            value: enrolledCount,
            color: AppColors.success,
            surfaceColor: AppColors.successSurface,
            icon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari leads...',
              prefixIcon: const Icon(Icons.search, size: AppDimensions.iconMd),
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
        const SizedBox(height: AppDimensions.sm),
        Wrap(
          spacing: AppDimensions.sm,
          children: _statusFilters.map((filter) {
            final isSelected = _selectedStatus == filter.$1;
            return FilterChip(
              label: Text(filter.$2),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedStatus = filter.$1);
              },
              selectedColor: AppColors.primarySurface,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        if (state is LeadLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is LeadError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppDimensions.md),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.md),
                FilledButton.icon(
                  onPressed: () => context.read<LeadCubit>().loadLeads(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (state is LeadLoaded) {
          final filtered = _filtered(state.leads);

          if (filtered.isEmpty) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      _searchQuery.isNotEmpty || _selectedStatus.isNotEmpty
                          ? 'Tidak ada leads yang cocok'
                          : 'Belum ada data leads',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (_searchQuery.isEmpty && _selectedStatus.isEmpty) ...[
                      const SizedBox(height: AppDimensions.sm),
                      FilledButton.icon(
                        onPressed: () => _showLeadForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Lead Pertama'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: DataTable2(
              columnSpacing: AppDimensions.md,
              horizontalMargin: AppDimensions.md,
              headingRowHeight: AppDimensions.tableHeaderHeight,
              dataRowHeight: AppDimensions.tableRowHeight,
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
              columns: const [
                DataColumn2(
                  label: Text('No.'),
                  size: ColumnSize.S,
                  fixedWidth: 48,
                ),
                DataColumn2(label: Text('Nama'), size: ColumnSize.L),
                DataColumn2(label: Text('Email'), size: ColumnSize.L),
                DataColumn2(
                  label: Text('Telepon'),
                  size: ColumnSize.M,
                  fixedWidth: 140,
                ),
                DataColumn2(label: Text('Minat'), size: ColumnSize.M),
                DataColumn2(
                  label: Text('Sumber'),
                  size: ColumnSize.S,
                  fixedWidth: 110,
                ),
                DataColumn2(
                  label: Text('Status'),
                  size: ColumnSize.S,
                  fixedWidth: 120,
                ),
                DataColumn2(
                  label: Text('Tanggal'),
                  size: ColumnSize.S,
                  fixedWidth: 120,
                ),
                DataColumn2(
                  label: Text('Aksi'),
                  size: ColumnSize.S,
                  fixedWidth: 100,
                ),
              ],
              rows: List.generate(filtered.length, (index) {
                final lead = filtered[index];
                return DataRow2(
                  onTap: () => _showLeadDetail(context, lead),
                  cells: [
                    DataCell(Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )),
                    DataCell(_LeadNameCell(lead: lead)),
                    DataCell(Text(
                      lead.email.isEmpty ? '-' : lead.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(Text(
                      lead.phone.isEmpty ? '-' : lead.phone,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )),
                    DataCell(Text(
                      lead.interest.isEmpty ? '-' : lead.interest,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(Text(
                      lead.sourceLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )),
                    DataCell(_StatusChip(
                      status: lead.status,
                      label: lead.statusLabel,
                    )),
                    DataCell(Text(
                      DateFormatUtil.toDisplay(lead.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionIconButton(
                          icon: Icons.visibility_outlined,
                          color: AppColors.primary,
                          tooltip: 'Detail & Log CRM',
                          onTap: () => _showLeadDetail(context, lead),
                        ),
                        const SizedBox(width: 4),
                        _ActionIconButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.secondary,
                          tooltip: 'Edit',
                          onTap: () => _showLeadForm(context, lead: lead),
                        ),
                        const SizedBox(width: 4),
                        _ActionIconButton(
                          icon: Icons.delete_outline,
                          color: AppColors.error,
                          tooltip: 'Hapus',
                          onTap: () => _confirmDelete(context, lead),
                        ),
                      ],
                    )),
                  ],
                );
              }),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Lead Detail Dialog ───────────────────────────────────────────────────────

class _LeadDetailDialog extends StatefulWidget {
  final LeadEntity lead;

  const _LeadDetailDialog({required this.lead});

  @override
  State<_LeadDetailDialog> createState() => _LeadDetailDialogState();
}

class _LeadDetailDialogState extends State<_LeadDetailDialog> {
  List<CrmLogEntity> _logs = [];
  bool _loadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    final logs =
        await context.read<LeadCubit>().getCrmLogs(widget.lead.id);
    if (mounted) {
      setState(() {
        _logs = logs;
        _loadingLogs = false;
      });
    }
  }

  void _showCrmLogForm(BuildContext context) {
    String selectedMethod = 'phone';
    final responseCtrl = TextEditingController();
    DateTime? followUpDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Log CRM'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration:
                        const InputDecoration(labelText: 'Metode Kontak'),
                    items: const [
                      DropdownMenuItem(
                          value: 'phone', child: Text('Telepon')),
                      DropdownMenuItem(
                          value: 'email', child: Text('Email')),
                      DropdownMenuItem(
                          value: 'whatsapp', child: Text('WhatsApp')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedMethod = v);
                      }
                    },
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: responseCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Respon Lead *',
                      hintText: 'Catat hasil percakapan atau respon lead...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  _FollowUpDatePicker(
                    selectedDate: followUpDate,
                    onDateChanged: (date) {
                      setDialogState(() => followUpDate = date);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                if (responseCtrl.text.trim().isEmpty) return;
                final data = {
                  'contact_method': selectedMethod,
                  'response': responseCtrl.text.trim(),
                  if (followUpDate != null)
                    'follow_up_date': followUpDate!.toIso8601String(),
                };
                Navigator.pop(ctx);
                final success = await context
                    .read<LeadCubit>()
                    .addCrmLog(widget.lead.id, data);
                if (success && mounted) {
                  _loadLogs();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: SizedBox(
        width: 700,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusCircle),
                    ),
                    child: Center(
                      child: Text(
                        lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lead.email.isNotEmpty ? lead.email : lead.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: lead.status, label: lead.statusLabel),
                  const SizedBox(width: AppDimensions.sm),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: AppDimensions.iconMd),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              const Divider(color: AppColors.divider),
              const SizedBox(height: AppDimensions.sm),

              // ── Lead Metadata ────────────────────────────────────────
              Wrap(
                spacing: AppDimensions.lg,
                runSpacing: AppDimensions.sm,
                children: [
                  _MetaItem(label: 'Telepon', value: lead.phone.isEmpty ? '-' : lead.phone),
                  _MetaItem(label: 'Minat', value: lead.interest.isEmpty ? '-' : lead.interest),
                  _MetaItem(label: 'Sumber', value: lead.sourceLabel),
                  _MetaItem(
                    label: 'Terdaftar',
                    value: DateFormatUtil.toDisplay(lead.createdAt),
                  ),
                ],
              ),
              if (lead.notes.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.sm),
                _MetaItem(label: 'Catatan', value: lead.notes),
              ],
              const SizedBox(height: AppDimensions.md),

              // ── CRM Log Section ──────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Log CRM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (lead.status != 'enrolled') ...[
                    FilledButton.icon(
                      onPressed: () => _showCrmLogForm(context),
                      icon: const Icon(Icons.add, size: AppDimensions.iconSm),
                      label: const Text('Tambah Log'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md,
                          vertical: AppDimensions.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final cubit = context.read<LeadCubit>();
                        final nav = Navigator.of(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Konversi ke Siswa'),
                            content: Text(
                              'Yakin ingin mengkonversi "${lead.name}" menjadi siswa?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Konversi'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && mounted) {
                          final success = await cubit.convertToStudent(lead.id);
                          if (success && mounted) {
                            nav.pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add_outlined,
                          size: AppDimensions.iconSm),
                      label: const Text('Konversi ke Siswa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md,
                          vertical: AppDimensions.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppDimensions.sm),

              // ── Log Table ────────────────────────────────────────────
              _buildCrmLogTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrmLogTable() {
    if (_loadingLogs) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_logs.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Belum ada log CRM. Klik "Tambah Log" untuk mencatat kontak.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(110),
                1: FlexColumnWidth(2),
                2: FixedColumnWidth(130),
                3: FixedColumnWidth(110),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                  ),
                  children: [
                    _tableHeader('Metode'),
                    _tableHeader('Respon'),
                    _tableHeader('Follow Up'),
                    _tableHeader('Tanggal'),
                  ],
                ),
                ..._logs.map((log) => TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      children: [
                        _tableCell(_contactMethodChip(log.contactMethod)),
                        _tableCell(
                          Text(
                            log.response,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _tableCell(
                          Text(
                            log.followUpDate != null
                                ? DateFormatUtil.toDisplay(log.followUpDate!)
                                : '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        _tableCell(
                          Text(
                            DateFormatUtil.toDisplay(log.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _tableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.sm,
      ),
      child: child,
    );
  }

  Widget _contactMethodChip(String method) {
    final (color, label) = switch (method) {
      'phone' => (AppColors.info, 'Telepon'),
      'email' => (AppColors.warning, 'Email'),
      'whatsapp' => (AppColors.success, 'WhatsApp'),
      _ => (AppColors.textSecondary, method),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Follow Up Date Picker ────────────────────────────────────────────────────

class _FollowUpDatePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateChanged;

  const _FollowUpDatePicker({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedDate != null
                ? 'Follow Up: ${DateFormatUtil.toDisplay(selectedDate!)}'
                : 'Follow Up: Tidak ditentukan',
            style: TextStyle(
              fontSize: 13,
              color: selectedDate != null
                  ? AppColors.textPrimary
                  : AppColors.textHint,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            onDateChanged(picked);
          },
          icon: const Icon(Icons.calendar_today_outlined,
              size: AppDimensions.iconSm),
          label: const Text('Pilih Tanggal'),
        ),
        if (selectedDate != null)
          IconButton(
            onPressed: () => onDateChanged(null),
            icon: const Icon(Icons.clear, size: AppDimensions.iconSm),
            tooltip: 'Hapus tanggal',
          ),
      ],
    );
  }
}

// ─── Meta Item ────────────────────────────────────────────────────────────────

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color surfaceColor;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.surfaceColor,
    required this.icon,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconLg),
          ),
          const SizedBox(width: AppDimensions.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
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

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;

  const _StatusChip({required this.status, required this.label});

  (Color, Color) get _colors => switch (status) {
        'new' => (AppColors.info, AppColors.infoSurface),
        'contacted' => (AppColors.warning, AppColors.warningSurface),
        'interested' => (AppColors.primary, AppColors.primarySurface),
        'negotiating' => (AppColors.secondary, AppColors.secondaryDark.withOpacity(0.1)),
        'enrolled' => (AppColors.success, AppColors.successSurface),
        'not_interested' => (AppColors.error, AppColors.errorSurface),
        _ => (AppColors.textSecondary, AppColors.surfaceVariant),
      };

  @override
  Widget build(BuildContext context) {
    final (textColor, bgColor) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Lead Name Cell ───────────────────────────────────────────────────────────

class _LeadNameCell extends StatelessWidget {
  final LeadEntity lead;
  const _LeadNameCell({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          child: Center(
            child: Text(
              lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            lead.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Action Icon Button ───────────────────────────────────────────────────────

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              widget.icon,
              size: AppDimensions.iconMd,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
