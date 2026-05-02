import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_template_cubit.dart';

const _kRouteEditor = '/certificate-templates';

/// Lists all certificate templates with create / edit affordances.
class CertificateTemplateListPage extends StatelessWidget {
  const CertificateTemplateListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CertificateTemplateCubit>()..load(),
      child: const _ListView(),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView();

  void _openEditor(BuildContext context, {String? id}) {
    final path = id == null ? '$_kRouteEditor/new' : '$_kRouteEditor/$id/edit';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Sertifikat'),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Template Baru'),
      ),
      body: BlocBuilder<CertificateTemplateCubit, CertificateTemplateState>(
        builder: (ctx, state) {
          if (state is CertificateTemplateLoading ||
              state is CertificateTemplateInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CertificateTemplateError) {
            return _ErrorView(message: state.message);
          }
          if (state is CertificateTemplateLoaded) {
            if (state.templates.isEmpty) {
              return const _EmptyView();
            }
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: _TemplateTable(
                templates: state.templates,
                onEdit: (id) => _openEditor(context, id: id),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TemplateTable extends StatelessWidget {
  final List<CertificateTemplateEntity> templates;
  final void Function(String id) onEdit;

  const _TemplateTable({required this.templates, required this.onEdit});

  String _typeLabel(String t) =>
      t == 'competency' ? 'Kompetensi' : 'Peserta';

  @override
  Widget build(BuildContext context) {
    return DataTable2(
      columns: const [
        DataColumn2(label: Text('Nama'), size: ColumnSize.L),
        DataColumn2(label: Text('Tipe')),
        DataColumn2(label: Text('Diperbarui')),
        DataColumn2(label: Text('Aksi'), fixedWidth: 100),
      ],
      rows: templates
          .map((t) => DataRow2(
                cells: [
                  DataCell(Text(t.name)),
                  DataCell(Text(_typeLabel(t.type))),
                  DataCell(Text(DateFormatUtil.toDisplay(t.createdAt))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit, size: AppDimensions.iconMd),
                    tooltip: 'Edit',
                    onPressed: () => onEdit(t.id),
                  )),
                ],
              ))
          .toList(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 64, color: AppColors.textHint),
          SizedBox(height: AppDimensions.md),
          Text('Belum ada template sertifikat',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppDimensions.md),
          Text(message, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: AppDimensions.md),
          FilledButton(
            onPressed: () =>
                context.read<CertificateTemplateCubit>().load(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
