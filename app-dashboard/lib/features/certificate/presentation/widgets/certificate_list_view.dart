import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/certificate_entity.dart';

/// Stateless list view that renders a flat list of certificates with
/// per-row actions. Grouping is the caller's responsibility — this widget
/// just iterates [items].
class CertificateListView extends StatelessWidget {
  final List<CertificateEntity> items;
  final void Function(CertificateEntity) onRevoke;
  final void Function(CertificateEntity) onView;

  const CertificateListView({
    super.key,
    required this.items,
    required this.onRevoke,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState();
    }
    return Column(
      children: [
        for (final c in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: CertificateListRow(
              certificate: c,
              onRevoke: () => onRevoke(c),
              onView: () => onView(c),
            ),
          ),
      ],
    );
  }
}

class CertificateListRow extends StatelessWidget {
  final CertificateEntity certificate;
  final VoidCallback onRevoke;
  final VoidCallback onView;

  const CertificateListRow({
    super.key,
    required this.certificate,
    required this.onRevoke,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          _TypeChip(type: c.type),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.certificateCode,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.isRevoked
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    decoration: c.isRevoked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleFor(c),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Text(
            _formatDate(c.issuedAt),
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppDimensions.md),
          _StatusChip(status: c.status),
          const SizedBox(width: AppDimensions.md),
          IconButton(
            tooltip: 'Lihat',
            icon: const Icon(Icons.visibility_outlined,
                size: AppDimensions.iconMd),
            onPressed: onView,
          ),
          IconButton(
            tooltip: c.isRevoked ? 'Sudah dicabut' : 'Cabut sertifikat',
            icon: Icon(
              Icons.block,
              size: AppDimensions.iconMd,
              color: c.isRevoked ? AppColors.textHint : AppColors.error,
            ),
            onPressed: c.isRevoked ? null : onRevoke,
          ),
        ],
      ),
    );
  }

  String _subtitleFor(CertificateEntity c) {
    final parts = <String>[];
    if (c.courseName.isNotEmpty) parts.add(c.courseName);
    if (c.batchName.isNotEmpty) parts.add(c.batchName);
    if (parts.isEmpty) return c.courseId;
    return parts.join(' • ');
  }

  static String _formatDate(DateTime d) =>
      DateFormat('d MMM y', 'id_ID').format(d);
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final isCompetency = type == CertificateEntity.typeCompetency;
    final bg = isCompetency ? AppColors.successSurface : AppColors.infoSurface;
    final fg = isCompetency ? AppColors.success : AppColors.info;
    final label = isCompetency ? 'Kompetensi' : 'Partisipan';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          )),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isRevoked = status == CertificateEntity.statusRevoked;
    final bg = isRevoked ? AppColors.errorSurface : AppColors.successSurface;
    final fg = isRevoked ? AppColors.error : AppColors.success;
    final label = isRevoked ? 'Dicabut' : 'Aktif';
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
            decoration:
                isRevoked ? TextDecoration.lineThrough : TextDecoration.none,
          )),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 32, color: AppColors.textHint),
          SizedBox(height: AppDimensions.sm),
          Text('Belum ada sertifikat',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
