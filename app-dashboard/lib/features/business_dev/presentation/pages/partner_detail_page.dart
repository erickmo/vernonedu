import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/mou_entity.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partnership_log_entity.dart';
import '../cubit/partner_detail_cubit.dart';
import '../cubit/partner_detail_state.dart';

class PartnerDetailPage extends StatelessWidget {
  final String partnerId;

  const PartnerDetailPage({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PartnerDetailCubit>()..loadDetail(partnerId),
      child: _PartnerDetailView(partnerId: partnerId),
    );
  }
}

class _PartnerDetailView extends StatelessWidget {
  final String partnerId;

  const _PartnerDetailView({required this.partnerId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerDetailCubit, PartnerDetailState>(
      listener: (context, state) {
        if (state is PartnerDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<PartnerDetailCubit, PartnerDetailState>(
        builder: (context, state) {
          if (state is PartnerDetailInitial || state is PartnerDetailLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is PartnerDetailError) {
            return Scaffold(
              appBar: _buildAppBar(context, null),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: AppDimensions.md),
                    Text(state.message,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: AppDimensions.md),
                    TextButton(
                      onPressed: () => context
                          .read<PartnerDetailCubit>()
                          .loadDetail(partnerId),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is PartnerDetailLoaded) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context, state.partner),
              body: _PartnerDetailBody(
                partner: state.partner,
                mous: state.mous,
                logs: state.logs,
                partnerId: partnerId,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, PartnerEntity? partner) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Text(
        partner?.name ?? 'Detail Partner',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        if (partner != null)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.md),
            child: _StatusBadge(status: partner.status),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _PartnerDetailBody extends StatelessWidget {
  final PartnerEntity partner;
  final List<MouEntity> mous;
  final List<PartnershipLogEntity> logs;
  final String partnerId;

  const _PartnerDetailBody({
    required this.partner,
    required this.mous,
    required this.logs,
    required this.partnerId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PartnerInfoCard(partner: partner),
          const SizedBox(height: AppDimensions.lg),
          _MouSection(mous: mous, partnerId: partnerId),
          const SizedBox(height: AppDimensions.lg),
          _PartnershipLogSection(logs: logs),
        ],
      ),
    );
  }
}

// ─── Partner Info Card ────────────────────────────────────────────────────────

class _PartnerInfoCard extends StatelessWidget {
  final PartnerEntity partner;

  const _PartnerInfoCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.avatarLg,
                  height: AppDimensions.avatarLg,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      partner.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
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
                        partner.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (partner.groupName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          partner.groupName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.xs),
                      _StatusBadge(status: partner.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          // Info grid
          Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: _InfoGrid(partner: partner),
          ),
          if (partner.notes.isNotEmpty) ...[
            Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    partner.notes,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final PartnerEntity partner;

  const _InfoGrid({required this.partner});

  @override
  Widget build(BuildContext context) {
    final fields = [
      _InfoField(label: 'Industri', value: partner.industry),
      _InfoField(label: 'Partner Sejak', value: _formatDate(partner.partnerSince)),
      _InfoField(label: 'Kontak Person', value: partner.contactPerson),
      _InfoField(label: 'Email', value: partner.contactEmail),
      _InfoField(label: 'Telepon', value: partner.contactPhone),
      _InfoField(label: 'Website', value: partner.website),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
      return Wrap(
        spacing: AppDimensions.xl,
        runSpacing: AppDimensions.md,
        children: fields
            .map(
              (f) => SizedBox(
                width: crossAxisCount == 2
                    ? (constraints.maxWidth - AppDimensions.xl) / 2
                    : constraints.maxWidth,
                child: _InfoItem(label: f.label, value: f.value),
              ),
            )
            .toList(),
      );
    });
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _InfoField {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── MOU Section ─────────────────────────────────────────────────────────────

class _MouSection extends StatefulWidget {
  final List<MouEntity> mous;
  final String partnerId;

  const _MouSection({required this.mous, required this.partnerId});

  @override
  State<_MouSection> createState() => _MouSectionState();
}

class _MouSectionState extends State<_MouSection> {
  bool _showAddForm = false;
  final _documentNumberCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _documentNumberCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.md,
              AppDimensions.md,
              AppDimensions.md,
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: AppDimensions.iconMd, color: AppColors.primary),
                const SizedBox(width: AppDimensions.sm),
                const Expanded(
                  child: Text(
                    'Daftar MoU',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showAddForm = !_showAddForm),
                  icon: Icon(
                    _showAddForm ? Icons.close : Icons.add,
                    size: AppDimensions.iconSm,
                  ),
                  label: Text(_showAddForm ? 'Batal' : 'Tambah MoU'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),

          // Add form
          if (_showAddForm) ...[
            _MouAddForm(
              documentNumberCtrl: _documentNumberCtrl,
              startDateCtrl: _startDateCtrl,
              endDateCtrl: _endDateCtrl,
              notesCtrl: _notesCtrl,
              submitting: _submitting,
              onSubmit: () => _submit(context),
            ),
            Divider(height: 1, color: AppColors.border),
          ],

          // Table
          if (widget.mous.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.xl),
              child: Center(
                child: Text(
                  'Belum ada MoU tercatat.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: AppDimensions.tableRowHeight * widget.mous.length +
                  AppDimensions.tableHeaderHeight +
                  AppDimensions.sm,
              child: DataTable2(
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.lg,
                minWidth: 520,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columns: const [
                  DataColumn2(
                    label: Text('No. Dokumen',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text('Mulai',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  DataColumn2(
                    label: Text('Berakhir',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  DataColumn2(
                    label: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.S,
                  ),
                ],
                rows: widget.mous.map((mou) {
                  final expiring = mou.isExpiringSoon;
                  return DataRow2(
                    color: expiring
                        ? WidgetStateProperty.all(
                            AppColors.warningSurface,
                          )
                        : null,
                    cells: [
                      DataCell(Text(
                        mou.documentNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      )),
                      DataCell(Text(
                        _formatDate(mou.startDate),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      )),
                      DataCell(Text(
                        _formatDate(mou.endDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: expiring
                              ? AppColors.warning
                              : AppColors.textSecondary,
                          fontWeight: expiring
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      )),
                      DataCell(
                        expiring
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningSurface,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSm),
                                  border: Border.all(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'Akan Habis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                ),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final docNum = _documentNumberCtrl.text.trim();
    final start = _startDateCtrl.text.trim();
    final end = _endDateCtrl.text.trim();
    if (docNum.isEmpty || start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor dokumen, tanggal mulai, dan berakhir wajib diisi.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final cubit = context.read<PartnerDetailCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await cubit.addMOU(widget.partnerId, {
      'document_number': docNum,
      'start_date': start,
      'end_date': end,
      'notes': _notesCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        _documentNumberCtrl.clear();
        _startDateCtrl.clear();
        _endDateCtrl.clear();
        _notesCtrl.clear();
        setState(() => _showAddForm = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('MoU berhasil ditambahkan.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _MouAddForm extends StatelessWidget {
  final TextEditingController documentNumberCtrl;
  final TextEditingController startDateCtrl;
  final TextEditingController endDateCtrl;
  final TextEditingController notesCtrl;
  final bool submitting;
  final VoidCallback onSubmit;

  const _MouAddForm({
    required this.documentNumberCtrl,
    required this.startDateCtrl,
    required this.endDateCtrl,
    required this.notesCtrl,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambah MoU Baru',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          _FormField(
            label: 'Nomor Dokumen *',
            controller: documentNumberCtrl,
            hint: 'Contoh: MOU/2024/001',
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  label: 'Tanggal Mulai *',
                  controller: startDateCtrl,
                  hint: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: _FormField(
                  label: 'Tanggal Berakhir *',
                  controller: endDateCtrl,
                  hint: 'YYYY-MM-DD',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          _FormField(
            label: 'Catatan',
            controller: notesCtrl,
            hint: 'Opsional',
            maxLines: 2,
          ),
          const SizedBox(height: AppDimensions.md),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                minimumSize: const Size(120, AppDimensions.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Partnership Log Section ──────────────────────────────────────────────────

class _PartnershipLogSection extends StatelessWidget {
  final List<PartnershipLogEntity> logs;

  const _PartnershipLogSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.lg,
              AppDimensions.md,
              AppDimensions.lg,
              AppDimensions.md,
            ),
            child: Row(
              children: [
                Icon(Icons.history_outlined,
                    size: AppDimensions.iconMd, color: AppColors.primary),
                SizedBox(width: AppDimensions.sm),
                Text(
                  'Riwayat Kemitraan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),

          // Table
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.xl),
              child: Center(
                child: Text(
                  'Belum ada riwayat kemitraan.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: AppDimensions.tableRowHeight * logs.length +
                  AppDimensions.tableHeaderHeight +
                  AppDimensions.sm,
              child: DataTable2(
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.lg,
                minWidth: 520,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceVariant),
                columns: const [
                  DataColumn2(
                    label: Text('Tanggal',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: Text('Entitas',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text('Tipe',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: Text('Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.S,
                  ),
                  DataColumn2(
                    label: Text('Catatan',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    size: ColumnSize.L,
                  ),
                ],
                rows: logs.map((log) {
                  return DataRow2(
                    cells: [
                      DataCell(Text(
                        _formatDate(log.logDate),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      )),
                      DataCell(Text(
                        log.entityName,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                      )),
                      DataCell(Text(
                        _typeLabel(log.entityType),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      )),
                      DataCell(_LogStatusBadge(status: log.status)),
                      DataCell(Text(
                        log.notes.isEmpty ? '—' : log.notes,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'batch':
        return 'Batch';
      case 'project':
        return 'Proyek';
      case 'mou':
        return 'MoU';
      default:
        return type;
    }
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'active' => (
          'Aktif',
          AppColors.successSurface,
          AppColors.success,
        ),
      'negotiating' => (
          'Negosiasi',
          AppColors.infoSurface,
          AppColors.info,
        ),
      'contacted' => (
          'Dihubungi',
          AppColors.warningSurface,
          AppColors.warning,
        ),
      'inactive' => (
          'Tidak Aktif',
          AppColors.errorSurface,
          AppColors.error,
        ),
      _ => (
          'Prospek',
          AppColors.lavender,
          AppColors.primaryLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LogStatusBadge extends StatelessWidget {
  final String status;

  const _LogStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('Selesai', AppColors.success),
      'ongoing' => ('Berjalan', AppColors.info),
      'cancelled' => ('Dibatalkan', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };

    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
