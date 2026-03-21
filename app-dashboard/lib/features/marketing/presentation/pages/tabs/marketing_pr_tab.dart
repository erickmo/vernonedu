import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../../domain/entities/pr_schedule_entity.dart';
import '../../cubit/marketing_cubit.dart';
import '../../cubit/marketing_state.dart';

class MarketingPrTab extends StatefulWidget {
  const MarketingPrTab({super.key});

  @override
  State<MarketingPrTab> createState() => _MarketingPrTabState();
}

class _MarketingPrTabState extends State<MarketingPrTab> {
  String _filterStatus = '';
  String _filterType = '';

  static const _statusFilters = [
    ('', 'Semua Status'),
    ('scheduled', 'Dijadwalkan'),
    ('active', 'Berjalan'),
    ('done', 'Selesai'),
  ];

  static const _typeFilters = [
    ('', 'Semua Tipe'),
    ('press_release', 'Press Release'),
    ('event', 'Event'),
    ('sponsorship', 'Sponsorship'),
    ('interview', 'Interview'),
    ('other', 'Lainnya'),
  ];

  void _showPrForm(BuildContext context, {PrScheduleEntity? pr}) {
    final titleCtrl = TextEditingController(text: pr?.title ?? '');
    final mediaVenueCtrl = TextEditingController(text: pr?.mediaVenue ?? '');
    final picCtrl = TextEditingController(text: pr?.picName ?? '');
    final notesCtrl = TextEditingController(text: pr?.notes ?? '');
    String selType = pr?.type ?? 'event';
    String selStatus = pr?.status ?? 'scheduled';
    DateTime selDate = pr?.scheduledAt ?? DateTime.now();
    final dateCtrl = TextEditingController(
        text: pr != null ? DateFormatUtil.toDisplayWithTime(pr.scheduledAt) : '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(pr == null ? 'Jadwalkan PR / Event' : 'Edit PR / Event'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Judul *'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  DropdownButtonFormField<String>(
                    value: selType,
                    decoration: const InputDecoration(labelText: 'Tipe'),
                    items: _typeFilters
                        .where((e) => e.$1.isNotEmpty)
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSt(() => selType = v);
                    },
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: mediaVenueCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Media / Venue'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: picCtrl,
                    decoration:
                        const InputDecoration(labelText: 'PIC (Nama)'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  if (pr != null)
                    DropdownButtonFormField<String>(
                      value: selStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _statusFilters
                          .where((e) => e.$1.isNotEmpty)
                          .map((e) => DropdownMenuItem(
                              value: e.$1, child: Text(e.$2)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSt(() => selStatus = v);
                      },
                    ),
                  if (pr != null) const SizedBox(height: AppDimensions.sm),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: selDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date == null || !ctx.mounted) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(selDate),
                      );
                      if (time == null) return;
                      setSt(() {
                        selDate = DateTime(date.year, date.month, date.day,
                            time.hour, time.minute);
                        dateCtrl.text =
                            DateFormatUtil.toDisplayWithTime(selDate);
                      });
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal & Waktu',
                          suffixIcon: Icon(Icons.calendar_today, size: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Keterangan',
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
                if (titleCtrl.text.trim().isEmpty) return;
                final data = {
                  'title': titleCtrl.text.trim(),
                  'type': selType,
                  'media_venue': mediaVenueCtrl.text.trim(),
                  'pic_name': picCtrl.text.trim(),
                  'status': selStatus,
                  'notes': notesCtrl.text.trim(),
                  'scheduled_at': selDate.millisecondsSinceEpoch ~/ 1000,
                };
                final cubit = context.read<MarketingCubit>();
                if (pr == null) {
                  cubit.createPr(data);
                } else {
                  cubit.updatePr(pr.id, data);
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        final all = state is MarketingLoaded
            ? state.prSchedules
            : <PrScheduleEntity>[];
        final filtered = all.where((pr) {
          final matchStatus =
              _filterStatus.isEmpty || pr.status == _filterStatus;
          final matchType = _filterType.isEmpty || pr.type == _filterType;
          return matchStatus && matchType;
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DropdownButton<String>(
                    value: _filterStatus,
                    items: _statusFilters
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _filterStatus = v ?? ''),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  DropdownButton<String>(
                    value: _filterType,
                    items: _typeFilters
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _filterType = v ?? ''),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () => _showPrForm(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Jadwalkan PR'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.newspaper_outlined,
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
                          DataColumn2(label: Text('Tanggal')),
                          DataColumn2(
                              label: Text('Judul'), size: ColumnSize.L),
                          DataColumn2(label: Text('Tipe')),
                          DataColumn2(label: Text('Media/Venue')),
                          DataColumn2(label: Text('PIC')),
                          DataColumn2(label: Text('Status')),
                          DataColumn2(label: Text('Keterangan'),
                              size: ColumnSize.L),
                          DataColumn2(label: Text('Aksi')),
                        ],
                        rows: filtered.map((pr) {
                          return DataRow2(cells: [
                            DataCell(Text(
                                DateFormatUtil.toDisplay(pr.scheduledAt),
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(pr.title,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(pr.typeLabel,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(pr.mediaVenue,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(pr.picName,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(_statusPill(pr)),
                            DataCell(Text(
                              pr.notes.isEmpty ? '-' : pr.notes,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 16),
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _showPrForm(context, pr: pr),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.error),
                                  tooltip: 'Hapus',
                                  onPressed: () => context
                                      .read<MarketingCubit>()
                                      .deletePr(pr.id),
                                ),
                              ],
                            )),
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

  Widget _statusPill(PrScheduleEntity pr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pr.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(pr.statusLabel,
          style: TextStyle(
              color: pr.statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}
