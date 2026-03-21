import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_cubit.dart';

class CertificatePage extends StatelessWidget {
  const CertificatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CertificateCubit>()..loadAll(),
      child: const _CertificateView(),
    );
  }
}

class _CertificateView extends StatefulWidget {
  const _CertificateView();

  @override
  State<_CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<_CertificateView> {
  String? _statusFilter;
  String? _typeFilter;

  void _applyFilter() {
    context.read<CertificateCubit>().loadAll(
          statusFilter: _statusFilter,
          typeFilter: _typeFilter,
        );
  }

  void _showIssueDialog(List<CertificateTemplateEntity> templates) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CertificateCubit>(),
        child: _IssueDialog(templates: templates),
      ),
    );
  }

  void _showRevokeDialog(CertificateEntity cert) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CertificateCubit>(),
        child: _RevokeDialog(certificate: cert),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateCubit, CertificateState>(
      listener: (context, state) {
        if (state is CertificateError) {
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
            _buildHeader(),
            const SizedBox(height: AppDimensions.md),
            _buildFilterRow(),
            const SizedBox(height: AppDimensions.md),
            BlocBuilder<CertificateCubit, CertificateState>(
              builder: (context, state) {
                if (state is CertificateLoading || state is CertificateInitial) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is CertificateError) {
                  return Expanded(child: _buildError(state.message));
                }
                if (state is CertificateLoaded) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStats(state.certificates),
                        const SizedBox(height: AppDimensions.md),
                        Expanded(
                          child: _buildTable(
                            state.certificates,
                            state.templates,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<CertificateCubit, CertificateState>(
      builder: (context, state) {
        final templates = state is CertificateLoaded ? state.templates : <CertificateTemplateEntity>[];
        return Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sertifikat',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  'Kelola penerbitan & pencabutan sertifikat course',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const Spacer(),
            IconButton.outlined(
              onPressed: _applyFilter,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: AppDimensions.sm),
            FilledButton.icon(
              onPressed: () => _showIssueDialog(templates),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Terbitkan Sertifikat'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              labelText: 'Status',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Semua Status')),
              DropdownMenuItem(value: 'active', child: Text('Aktif')),
              DropdownMenuItem(value: 'revoked', child: Text('Dicabut')),
            ],
            onChanged: (v) {
              setState(() => _statusFilter = v);
              _applyFilter();
            },
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            value: _typeFilter,
            decoration: InputDecoration(
              labelText: 'Tipe',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Semua Tipe')),
              DropdownMenuItem(
                  value: 'participant', child: Text('Peserta')),
              DropdownMenuItem(
                  value: 'competency', child: Text('Kompetensi')),
            ],
            onChanged: (v) {
              setState(() => _typeFilter = v);
              _applyFilter();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<CertificateEntity> certs) {
    final now = DateTime.now();
    final total = certs.length;
    final thisMonth =
        certs.where((c) => c.issuedAt.year == now.year && c.issuedAt.month == now.month).length;
    final active = certs.where((c) => !c.isRevoked).length;
    final revoked = certs.where((c) => c.isRevoked).length;

    return Row(
      children: [
        _StatCard(
          label: 'Total Sertifikat',
          value: '$total',
          icon: Icons.workspace_premium_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.md),
        _StatCard(
          label: 'Terbit Bulan Ini',
          value: '$thisMonth',
          icon: Icons.calendar_month_outlined,
          color: AppColors.success,
        ),
        const SizedBox(width: AppDimensions.md),
        _StatCard(
          label: 'Aktif',
          value: '$active',
          icon: Icons.verified_outlined,
          color: AppColors.info,
        ),
        const SizedBox(width: AppDimensions.md),
        _StatCard(
          label: 'Dicabut',
          value: '$revoked',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildTable(
    List<CertificateEntity> certs,
    List<CertificateTemplateEntity> templates,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: certs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: AppDimensions.md),
                  Text(
                    'Belum ada sertifikat terbit',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: DataTable2(
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                headingRowColor:
                    WidgetStateProperty.all(AppColors.surfaceVariant),
                border: TableBorder(
                  horizontalInside:
                      BorderSide(color: AppColors.border, width: 1),
                ),
                columns: const [
                  DataColumn2(
                    label: Text('Kode Sertifikat', style: _headerStyle),
                    fixedWidth: 200,
                  ),
                  DataColumn2(
                    label: Text('Siswa', style: _headerStyle),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('Course / Kelas', style: _headerStyle),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('Tipe', style: _headerStyle),
                    fixedWidth: 130,
                  ),
                  DataColumn2(
                    label: Text('Tanggal Terbit', style: _headerStyle),
                    fixedWidth: 130,
                  ),
                  DataColumn2(
                    label: Text('Status', style: _headerStyle),
                    fixedWidth: 110,
                  ),
                  DataColumn2(
                    label: Text('Aksi', style: _headerStyle),
                    fixedWidth: 80,
                  ),
                ],
                rows: certs
                    .map((cert) => DataRow2(
                          cells: [
                            DataCell(
                              Text(
                                cert.certificateCode.isEmpty
                                    ? '-'
                                    : cert.certificateCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(
                              Text(
                                cert.studentName.isEmpty ? '-' : cert.studentName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cert.courseName.isEmpty
                                        ? '-'
                                        : cert.courseName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cert.batchName.isNotEmpty)
                                    Text(
                                      cert.batchName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(_CertTypeBadge(type: cert.type)),
                            DataCell(
                              Text(
                                DateFormatUtil.toDisplay(cert.issuedAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            DataCell(
                              _CertStatusBadge(isRevoked: cert.isRevoked),
                            ),
                            DataCell(
                              cert.isRevoked
                                  ? const SizedBox.shrink()
                                  : IconButton(
                                      onPressed: () =>
                                          _showRevokeDialog(cert),
                                      icon: const Icon(
                                        Icons.block_outlined,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Cabut Sertifikat',
                                    ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.md),
          OutlinedButton(
            onPressed: _applyFilter,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 12,
  color: AppColors.textPrimary,
);

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
                color: color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class _CertTypeBadge extends StatelessWidget {
  final String type;
  const _CertTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isCompetency = type == 'competency';
    final bg = isCompetency ? AppColors.warningSurface : AppColors.infoSurface;
    final fg = isCompetency ? AppColors.warning : AppColors.info;
    final label = isCompetency ? 'Kompetensi' : 'Peserta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CertStatusBadge extends StatelessWidget {
  final bool isRevoked;
  const _CertStatusBadge({required this.isRevoked});

  @override
  Widget build(BuildContext context) {
    final bg = isRevoked ? AppColors.errorSurface : AppColors.successSurface;
    final fg = isRevoked ? AppColors.error : AppColors.success;
    final label = isRevoked ? 'Dicabut' : 'Aktif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Issue dialog
// ---------------------------------------------------------------------------

class _IssueDialog extends StatefulWidget {
  final List<CertificateTemplateEntity> templates;
  const _IssueDialog({required this.templates});

  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends State<_IssueDialog> {
  final _enrollmentController = TextEditingController();
  String _selectedType = 'participant';
  String? _selectedTemplateId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _enrollmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final enrollmentId = _enrollmentController.text.trim();
    if (enrollmentId.isEmpty) return;

    setState(() => _isSubmitting = true);

    final body = <String, dynamic>{
      'enrollment_id': enrollmentId,
      'type': _selectedType,
    };
    if (_selectedTemplateId != null) body['template_id'] = _selectedTemplateId;

    final ok =
        await context.read<CertificateCubit>().issueCertificate(body: body);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sertifikat berhasil diterbitkan'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(Icons.workspace_premium_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Text(
                    'Terbitkan Sertifikat Baru',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
              TextFormField(
                controller: _enrollmentController,
                decoration: InputDecoration(
                  labelText: 'ID Enrollment',
                  hintText: 'Masukkan ID enrollment siswa',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              DropdownButtonFormField<String>(
                value: _selectedType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Tipe Sertifikat',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'participant', child: Text('Peserta')),
                  DropdownMenuItem(
                      value: 'competency', child: Text('Kompetensi')),
                ],
                onChanged: (val) =>
                    setState(() => _selectedType = val ?? 'participant'),
              ),
              if (widget.templates.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.md),
                DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Template (opsional)',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Default')),
                    ...widget.templates.map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          t.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedTemplateId = val),
                ),
              ],
              const SizedBox(height: AppDimensions.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Terbitkan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revoke dialog
// ---------------------------------------------------------------------------

class _RevokeDialog extends StatefulWidget {
  final CertificateEntity certificate;
  const _RevokeDialog({required this.certificate});

  @override
  State<_RevokeDialog> createState() => _RevokeDialogState();
}

class _RevokeDialogState extends State<_RevokeDialog> {
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _isSubmitting = true);

    final ok = await context.read<CertificateCubit>().revokeCertificate(
          id: widget.certificate.id,
          reason: reason,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sertifikat berhasil dicabut'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(Icons.block_outlined,
                        color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      'Cabut Sertifikat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.certificate.certificateCode,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.certificate.studentName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      widget.certificate.courseName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alasan Pencabutan *',
                  hintText: 'Tuliskan alasan pencabutan sertifikat ini...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Cabut Sertifikat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
