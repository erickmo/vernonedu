import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _showPostForm(BuildContext context,
      {SocialMediaPostEntity? post}) async {
    final saved = post == null
        ? await context.push<bool>('/marketing/social/new')
        : await context.push<bool>(
            '/marketing/social/${post.id}/edit',
            extra: post,
          );
    if (saved == true && context.mounted) {
      context.read<MarketingCubit>().loadAll();
    }
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
