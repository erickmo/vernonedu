import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/date_format_util.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _CertItem {
  final String id;
  final String studentName;
  final String courseName;
  final String batchCode;
  final String type; // 'participant' | 'competency'
  final DateTime issuedAt;
  final String certificateNumber;
  final bool isRevoked;

  const _CertItem({
    required this.id,
    required this.studentName,
    required this.courseName,
    required this.batchCode,
    required this.type,
    required this.issuedAt,
    required this.certificateNumber,
    required this.isRevoked,
  });

  factory _CertItem.fromJson(Map<String, dynamic> json) {
    final issuedAtRaw = json['issued_at'];
    DateTime issuedAt;
    try {
      issuedAt = issuedAtRaw != null
          ? DateTime.parse(issuedAtRaw as String)
          : DateTime.now();
    } catch (_) {
      issuedAt = DateTime.now();
    }
    return _CertItem(
      id: json['id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      batchCode: json['batch_code'] as String? ?? '',
      type: json['type'] as String? ?? 'participant',
      issuedAt: issuedAt,
      certificateNumber: json['certificate_number'] as String? ?? '',
      isRevoked: json['is_revoked'] as bool? ?? false,
    );
  }
}

class _CertStats {
  final int total;
  final int issuedThisMonth;

  const _CertStats({required this.total, required this.issuedThisMonth});
}

// ---------------------------------------------------------------------------
// Enrollment dropdown item for the issue dialog
// ---------------------------------------------------------------------------

class _EnrollmentOption {
  final String id;
  final String label;

  const _EnrollmentOption({required this.id, required this.label});
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  late Future<List<_CertItem>> _certsFuture;

  @override
  void initState() {
    super.initState();
    _certsFuture = _loadCerts();
  }

  void _reload() => setState(() => _certsFuture = _loadCerts());

  Future<List<_CertItem>> _loadCerts() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final res = await dio.get('/certificates', queryParameters: {'limit': 100});
      final raw = res.data;
      final list = (raw is Map && raw['data'] != null)
          ? raw['data'] as List
          : raw is List
              ? raw
              : <dynamic>[];
      return list
          .cast<Map<String, dynamic>>()
          .map(_CertItem.fromJson)
          .toList();
    } catch (_) {
      // Return empty list on error so we can show the empty state gracefully.
      return <_CertItem>[];
    }
  }

  _CertStats _computeStats(List<_CertItem> certs) {
    final now = DateTime.now();
    final issuedThisMonth = certs
        .where((c) =>
            c.issuedAt.year == now.year && c.issuedAt.month == now.month)
        .length;
    return _CertStats(total: certs.length, issuedThisMonth: issuedThisMonth);
  }

  Future<List<_EnrollmentOption>> _loadEnrollments() async {
    try {
      final dio = getIt<ApiClient>().dio;
      final res =
          await dio.get('/enrollments', queryParameters: {'limit': 200});
      final raw = res.data;
      final list = (raw is Map && raw['data'] != null)
          ? raw['data'] as List
          : raw is List
              ? raw
              : <dynamic>[];
      return list.cast<Map<String, dynamic>>().map((e) {
        final studentName = e['student_name'] as String? ?? 'Siswa';
        final batchCode = e['batch_code'] as String? ?? e['course_batch_id'] as String? ?? '-';
        return _EnrollmentOption(
          id: e['id'] as String? ?? '',
          label: '$studentName — $batchCode',
        );
      }).toList();
    } catch (_) {
      return <_EnrollmentOption>[];
    }
  }

  void _showIssueDialog() {
    showDialog(
      context: context,
      builder: (_) => _IssueDialog(
        loadEnrollments: _loadEnrollments,
        onSuccess: () {
          _reload();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sertifikat berhasil diterbitkan'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        onError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menerbitkan sertifikat: $msg'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------------
          // Section 1: Page Header
          // ------------------------------------------------------------------
          Row(
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
                    'Kelola penerbitan sertifikat course',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton.outlined(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: AppDimensions.sm),
              FilledButton.icon(
                onPressed: _showIssueDialog,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Terbitkan Sertifikat'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          // ------------------------------------------------------------------
          // Sections 2 & 3 driven by FutureBuilder
          // ------------------------------------------------------------------
          Expanded(
            child: FutureBuilder<List<_CertItem>>(
              future: _certsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final certs = snapshot.data ?? <_CertItem>[];
                final stats = _computeStats(certs);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --------------------------------------------------------
                    // Section 2: Stats Row
                    // --------------------------------------------------------
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total Sertifikat',
                          value: '${stats.total}',
                          icon: Icons.workspace_premium_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppDimensions.md),
                        _StatCard(
                          label: 'Terbit Bulan Ini',
                          value: '${stats.issuedThisMonth}',
                          icon: Icons.calendar_month_outlined,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),

                    // --------------------------------------------------------
                    // Section 3: Certificate List
                    // --------------------------------------------------------
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: certs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 48,
                                      color: AppColors.textHint,
                                    ),
                                    const SizedBox(height: AppDimensions.md),
                                    Text(
                                      'Belum ada sertifikat terbit',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusLg),
                                child: DataTable2(
                                  columnSpacing: AppDimensions.md,
                                  horizontalMargin: AppDimensions.md,
                                  headingRowHeight: AppDimensions.tableHeaderHeight,
                                  dataRowHeight: AppDimensions.tableRowHeight,
                                  headingRowColor: WidgetStateProperty.all(
                                      AppColors.surfaceVariant),
                                  border: TableBorder(
                                    horizontalInside: BorderSide(
                                        color: AppColors.border, width: 1),
                                  ),
                                  columns: const [
                                    DataColumn2(
                                      label: Text('No. Sertifikat',
                                          style: _tableHeaderStyle),
                                      fixedWidth: 180,
                                    ),
                                    DataColumn2(
                                      label: Text('Siswa',
                                          style: _tableHeaderStyle),
                                      size: ColumnSize.M,
                                    ),
                                    DataColumn2(
                                      label: Text('Course',
                                          style: _tableHeaderStyle),
                                      size: ColumnSize.M,
                                    ),
                                    DataColumn2(
                                      label: Text('Tipe',
                                          style: _tableHeaderStyle),
                                      fixedWidth: 140,
                                    ),
                                    DataColumn2(
                                      label: Text('Tanggal Terbit',
                                          style: _tableHeaderStyle),
                                      fixedWidth: 130,
                                    ),
                                    DataColumn2(
                                      label: Text('Status',
                                          style: _tableHeaderStyle),
                                      fixedWidth: 100,
                                    ),
                                  ],
                                  rows: certs
                                      .map((cert) => DataRow2(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  cert.certificateNumber.isEmpty
                                                      ? '-'
                                                      : cert.certificateNumber,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  cert.studentName.isEmpty
                                                      ? '-'
                                                      : cert.studentName,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      cert.courseName.isEmpty
                                                          ? '-'
                                                          : cert.courseName,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (cert.batchCode
                                                        .isNotEmpty)
                                                      Text(
                                                        cert.batchCode,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .textSecondary),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                  _CertTypeBadge(type: cert.type)),
                                              DataCell(
                                                Text(
                                                  DateFormatUtil.toDisplay(
                                                      cert.issuedAt),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary),
                                                ),
                                              ),
                                              DataCell(
                                                  _CertStatusBadge(
                                                      isRevoked: cert.isRevoked)),
                                            ],
                                          ))
                                      .toList(),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

const _tableHeaderStyle = TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 12,
  color: AppColors.textPrimary,
);

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
                color: color.withOpacity(0.1),
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
// Issue Certificate Dialog
// ---------------------------------------------------------------------------

class _IssueDialog extends StatefulWidget {
  final Future<List<_EnrollmentOption>> Function() loadEnrollments;
  final VoidCallback onSuccess;
  final void Function(String) onError;

  const _IssueDialog({
    required this.loadEnrollments,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends State<_IssueDialog> {
  late Future<List<_EnrollmentOption>> _enrollmentsFuture;
  String? _selectedEnrollmentId;
  String _selectedType = 'participant';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _enrollmentsFuture = widget.loadEnrollments();
  }

  Future<void> _submit() async {
    if (_selectedEnrollmentId == null) return;
    setState(() => _isSubmitting = true);
    try {
      final dio = getIt<ApiClient>().dio;
      await dio.post('/certificates', data: {
        'enrollment_id': _selectedEnrollmentId,
        'type': _selectedType,
      });
      if (mounted) {
        context.pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onError(e.toString());
      }
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
              // Title
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

              // Enrollment dropdown
              FutureBuilder<List<_EnrollmentOption>>(
                future: _enrollmentsFuture,
                builder: (context, snapshot) {
                  final options = snapshot.data ?? <_EnrollmentOption>[];
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;
                  return DropdownButtonFormField<String>(
                    value: _selectedEnrollmentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Enrollment',
                      hintText: isLoading
                          ? 'Memuat data...'
                          : 'Pilih enrollment siswa',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    items: options
                        .map((o) => DropdownMenuItem(
                              value: o.id,
                              child: Text(
                                o.label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (val) =>
                            setState(() => _selectedEnrollmentId = val),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.md),

              // Type dropdown
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
              const SizedBox(height: AppDimensions.lg),

              // Footer buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => context.pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  FilledButton(
                    onPressed: (_selectedEnrollmentId == null || _isSubmitting)
                        ? null
                        : _submit,
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
