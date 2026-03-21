import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../../domain/entities/class_doc_post_entity.dart';
import '../../cubit/marketing_cubit.dart';
import '../../cubit/marketing_state.dart';

class MarketingClassDocTab extends StatelessWidget {
  const MarketingClassDocTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        final docs =
            state is MarketingLoaded ? state.classDocs : <ClassDocPostEntity>[];

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dokumentasi Kelas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppDimensions.md),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 48, color: AppColors.textHint),
                            SizedBox(height: AppDimensions.sm),
                            Text('Belum ada data',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : DataTable2(
                        columnSpacing: 16,
                        headingRowColor: WidgetStateProperty.all(
                            AppColors.surfaceVariant),
                        columns: const [
                          DataColumn2(label: Text('Tanggal Post')),
                          DataColumn2(
                              label: Text('Kelas'), size: ColumnSize.L),
                          DataColumn2(label: Text('Modul')),
                          DataColumn2(label: Text('Sesi Tanggal')),
                          DataColumn2(label: Text('Status')),
                          DataColumn2(
                              label: Text('URL Post'), size: ColumnSize.L),
                        ],
                        rows: docs.map((doc) {
                          return DataRow2(cells: [
                            DataCell(Text(
                                DateFormatUtil.toDisplay(doc.scheduledPostDate),
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(doc.batchName,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(
                              doc.moduleName,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Text(
                                DateFormatUtil.toDisplay(doc.classDate),
                                style: const TextStyle(fontSize: 12))),
                            DataCell(_statusPill(doc)),
                            DataCell(doc.postUrl.isEmpty
                                ? const Text('-',
                                    style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 12))
                                : Text(doc.postUrl,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.info))),
                          ]);
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusPill(ClassDocPostEntity doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: doc.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        doc.statusLabel,
        style: TextStyle(
            color: doc.statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
