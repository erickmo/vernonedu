import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab dokumen SDM — CV, kontrak, sertifikat, KTP, dsb.
class SdmDocumentsTabWidget extends StatelessWidget {
  final List<SdmDocumentEntity> documents;

  const SdmDocumentsTabWidget({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return _buildEmpty(context);
    }
    final grouped = <String, List<SdmDocumentEntity>>{};
    for (final doc in documents) {
      grouped.putIfAbsent(doc.type, () => []).add(doc);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries
            .map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.lg),
                  child: _buildGroup(context, entry.key, entry.value),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String type,
    List<SdmDocumentEntity> docs,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _typeLabel(type),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...docs.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                child: _buildDocumentCard(context, d),
              )),
        ],
      );

  Widget _buildDocumentCard(BuildContext context, SdmDocumentEntity doc) =>
      Container(
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
                color: _docColor(doc.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                _docIcon(doc.type),
                color: _docColor(doc.type),
                size: AppDimensions.iconMd,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Upload: ${_fmtDate(doc.uploadDate)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      if (doc.fileSize != null) ...[
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          '· ${doc.fileSize}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textHint,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (doc.url != null)
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.download_outlined,
                  size: AppDimensions.iconMd,
                ),
                color: AppColors.primary,
                tooltip: AppStrings.sdmDocDownload,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      );

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                AppStrings.sdmNoDocumentData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  String _typeLabel(String type) {
    switch (type) {
      case 'cv':
        return 'CV / Resume';
      case 'contract':
        return 'Kontrak';
      case 'certificate':
        return 'Sertifikat';
      case 'id_card':
        return 'Identitas';
      default:
        return 'Dokumen Lainnya';
    }
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'cv':
        return Icons.description_outlined;
      case 'contract':
        return Icons.handshake_outlined;
      case 'certificate':
        return Icons.workspace_premium_outlined;
      case 'id_card':
        return Icons.badge_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _docColor(String type) {
    switch (type) {
      case 'cv':
        return AppColors.primary;
      case 'contract':
        return AppColors.secondary;
      case 'certificate':
        return AppColors.warning;
      case 'id_card':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
