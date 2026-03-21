import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../../domain/entities/social_media_post_entity.dart';
import '../../cubit/marketing_cubit.dart';
import '../../cubit/marketing_state.dart';

class MarketingSocialTab extends StatefulWidget {
  const MarketingSocialTab({super.key});

  @override
  State<MarketingSocialTab> createState() => _MarketingSocialTabState();
}

class _MarketingSocialTabState extends State<MarketingSocialTab> {
  String _filterPlatform = '';
  String _filterStatus = '';

  static const _platformOptions = [
    ('', 'Semua Platform'),
    ('instagram', 'Instagram'),
    ('facebook', 'Facebook'),
    ('tiktok', 'TikTok'),
    ('linkedin', 'LinkedIn'),
  ];

  static const _statusOptions = [
    ('', 'Semua Status'),
    ('draft', 'Draft'),
    ('scheduled', 'Dijadwalkan'),
    ('posted', 'Diposting'),
  ];

  static const _contentTypes = [
    ('promo', 'Promosi Course'),
    ('dokumentasi', 'Dokumentasi Kelas'),
    ('event', 'Event'),
    ('info', 'Info Umum'),
  ];

  void _showPostForm(BuildContext context, {SocialMediaPostEntity? post}) {
    final captionCtrl = TextEditingController(text: post?.caption ?? '');
    final mediaUrlCtrl = TextEditingController(text: post?.mediaUrl ?? '');
    final scheduledCtrl = TextEditingController(
        text: post != null
            ? DateFormatUtil.toDisplayWithTime(post.scheduledAt)
            : '');
    List<String> selPlatforms =
        post?.platforms.toList() ?? ['instagram'];
    String selContentType = post?.contentType ?? 'promo';
    DateTime selDate = post?.scheduledAt ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(post == null ? 'Jadwalkan Post' : 'Edit Post'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform checkboxes
                  const Text('Platform',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: AppDimensions.xs),
                  Wrap(
                    spacing: AppDimensions.sm,
                    children: [
                      'instagram',
                      'facebook',
                      'tiktok',
                      'linkedin'
                    ].map((p) {
                      final checked = selPlatforms.contains(p);
                      return FilterChip(
                        label: Text(p),
                        selected: checked,
                        onSelected: (v) => setSt(() {
                          if (v) {
                            selPlatforms.add(p);
                          } else {
                            selPlatforms.remove(p);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  DropdownButtonFormField<String>(
                    value: selContentType,
                    decoration:
                        const InputDecoration(labelText: 'Tipe Konten'),
                    items: _contentTypes
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSt(() => selContentType = v);
                    },
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: captionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Caption',
                        alignLabelWithHint: true),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: mediaUrlCtrl,
                    decoration:
                        const InputDecoration(labelText: 'URL Media'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateTimePicker(ctx, selDate);
                      if (picked != null) {
                        setSt(() {
                          selDate = picked;
                          scheduledCtrl.text =
                              DateFormatUtil.toDisplayWithTime(picked);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: scheduledCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jadwal Posting',
                          suffixIcon: Icon(Icons.calendar_today, size: 16),
                        ),
                      ),
                    ),
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
                final data = {
                  'platforms': selPlatforms,
                  'content_type': selContentType,
                  'caption': captionCtrl.text.trim(),
                  'media_url': mediaUrlCtrl.text.trim(),
                  'scheduled_at':
                      selDate.millisecondsSinceEpoch ~/ 1000,
                };
                final cubit = context.read<MarketingCubit>();
                if (post == null) {
                  cubit.createPost(data);
                } else {
                  cubit.updatePost(post.id, data);
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

  void _showSubmitUrlDialog(BuildContext context, String postId) {
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit URL Post'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
              labelText: 'URL Postingan',
              hintText: 'https://...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (urlCtrl.text.trim().isNotEmpty) {
                context
                    .read<MarketingCubit>()
                    .submitPostUrl(postId, urlCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        final posts = state is MarketingLoaded ? state.posts : <SocialMediaPostEntity>[];

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters
              Row(
                children: [
                  DropdownButton<String>(
                    value: _filterPlatform,
                    items: _platformOptions
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _filterPlatform = v ?? ''),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  DropdownButton<String>(
                    value: _filterStatus,
                    items: _statusOptions
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _filterStatus = v ?? ''),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      decoration: const InputDecoration(
                          hintText: 'YYYY-MM',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10)),
                      onChanged: (_) {},
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () => _showPostForm(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Jadwalkan Post'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Expanded(
                child: posts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_outlined,
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
                          DataColumn2(label: Text('Platform')),
                          DataColumn2(
                              label: Text('Konten'), size: ColumnSize.L),
                          DataColumn2(label: Text('Tipe')),
                          DataColumn2(label: Text('Status')),
                          DataColumn2(
                              label: Text('URL Post'), size: ColumnSize.L),
                          DataColumn2(label: Text('Aksi')),
                        ],
                        rows: posts.map((post) {
                          return DataRow2(cells: [
                            DataCell(Text(
                                DateFormatUtil.toDisplayWithTime(
                                    post.scheduledAt),
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(post.platformsDisplay,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(Text(
                              post.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            )),
                            DataCell(Text(post.contentTypeLabel,
                                style: const TextStyle(fontSize: 12))),
                            DataCell(_statusPill(
                                post.status, post.statusLabel, post.statusColor)),
                            DataCell(post.postUrl.isEmpty
                                ? const Text('-',
                                    style: TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 12))
                                : Text(post.postUrl,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.info))),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (post.status == 'scheduled')
                                  IconButton(
                                    icon: const Icon(Icons.link, size: 16),
                                    tooltip: 'Submit URL',
                                    onPressed: () => _showSubmitUrlDialog(
                                        context, post.id),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 16),
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _showPostForm(context, post: post),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.error),
                                  tooltip: 'Hapus',
                                  onPressed: () => context
                                      .read<MarketingCubit>()
                                      .deletePost(post.id),
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

  Widget _statusPill(String status, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
