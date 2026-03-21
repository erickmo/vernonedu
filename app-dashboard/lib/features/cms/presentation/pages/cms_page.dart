import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/date_format_util.dart';
import '../../domain/entities/cms_article_entity.dart';
import '../../domain/entities/cms_faq_entity.dart';
import '../../domain/entities/cms_media_entity.dart';
import '../../domain/entities/cms_page_entity.dart';
import '../../domain/entities/cms_testimonial_entity.dart';
import '../cubit/cms_cubit.dart';
import '../cubit/cms_state.dart';

class CmsPage extends StatelessWidget {
  const CmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CmsCubit>()..loadAll(),
      child: const _CmsView(),
    );
  }
}

class _CmsView extends StatefulWidget {
  const _CmsView();

  @override
  State<_CmsView> createState() => _CmsViewState();
}

class _CmsViewState extends State<_CmsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: BlocBuilder<CmsCubit, CmsState>(
              builder: (context, state) {
                if (state is CmsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CmsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message, style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<CmsCubit>().loadAll(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is CmsLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _PagesTab(pages: state.pages),
                      _ArticlesTab(articles: state.articles, total: state.articleTotal),
                      _TestimonialsTab(testimonials: state.testimonials),
                      _FaqTab(faqs: state.faqs),
                      _MediaTab(media: state.media),
                      _SeoTab(pages: state.pages),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xl, AppDimensions.lg, AppDimensions.xl, AppDimensions.md,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manajemen Konten Website',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola halaman, artikel, testimoni, dan FAQ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<CmsCubit>().loadAll(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Halaman'),
          Tab(text: 'Artikel'),
          Tab(text: 'Testimoni'),
          Tab(text: 'FAQ'),
          Tab(text: 'Media Library'),
          Tab(text: 'SEO'),
        ],
      ),
    );
  }
}

// ─── Pages Tab ───────────────────────────────────────────────────────────────

class _PagesTab extends StatelessWidget {
  final List<CmsPageEntity> pages;
  const _PagesTab({required this.pages});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text(
                'Daftar Halaman',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DataTable2(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                columns: const [
                  DataColumn2(label: Text('Halaman'), size: ColumnSize.L),
                  DataColumn2(label: Text('Slug'), size: ColumnSize.M),
                  DataColumn2(label: Text('Terakhir Diedit'), size: ColumnSize.M),
                  DataColumn2(label: Text('Diedit Oleh'), size: ColumnSize.M),
                  DataColumn2(label: Text('Aksi'), size: ColumnSize.S, fixedWidth: 80),
                ],
                rows: pages.map((p) {
                  return DataRow2(
                    cells: [
                      DataCell(Text(p.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text(p.slug, style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                      DataCell(Text(DateFormatUtil.toDisplay(p.updatedAt))),
                      DataCell(Text(p.updatedBy.isEmpty ? '—' : p.updatedBy)),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _showPageEditor(context, p),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPageEditor(BuildContext context, CmsPageEntity page) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CmsCubit>(),
        child: _PageEditorDialog(page: page),
      ),
    );
  }
}

class _PageEditorDialog extends StatefulWidget {
  final CmsPageEntity page;
  const _PageEditorDialog({required this.page});

  @override
  State<_PageEditorDialog> createState() => _PageEditorDialogState();
}

class _PageEditorDialogState extends State<_PageEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _metaTitleCtrl;
  late final TextEditingController _metaDescCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.page.title);
    _subtitleCtrl = TextEditingController(text: widget.page.subtitle);
    _metaTitleCtrl = TextEditingController(text: widget.page.metaTitle);
    _metaDescCtrl = TextEditingController(text: widget.page.metaDescription);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Halaman: ${widget.page.slug}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Judul Halaman', _titleCtrl),
              const SizedBox(height: 12),
              _field('Subtitle', _subtitleCtrl),
              const SizedBox(height: 20),
              Text('SEO', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _field('Meta Title', _metaTitleCtrl),
              const SizedBox(height: 12),
              _field('Meta Description', _metaDescCtrl, maxLines: 3),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        isDense: true,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<CmsCubit>().savePage(widget.page.slug, {
      'title': _titleCtrl.text,
      'subtitle': _subtitleCtrl.text,
      'seo': {
        'meta_title': _metaTitleCtrl.text,
        'meta_description': _metaDescCtrl.text,
      },
    });
    if (mounted) Navigator.pop(context);
  }
}

// ─── Articles Tab ─────────────────────────────────────────────────────────────

class _ArticlesTab extends StatefulWidget {
  final List<CmsArticleEntity> articles;
  final int total;
  const _ArticlesTab({required this.articles, required this.total});

  @override
  State<_ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<_ArticlesTab> {
  String _category = '';
  String _status = '';

  static const _categories = [
    ('', 'Semua Kategori'),
    ('tips_karir', 'Tips Karir'),
    ('info_kursus', 'Info Kursus'),
    ('berita', 'Berita'),
    ('event', 'Event'),
  ];

  static const _statuses = [
    ('', 'Semua Status'),
    ('draft', 'Draft'),
    ('published', 'Published'),
    ('archived', 'Archived'),
  ];

  List<CmsArticleEntity> get _filtered => widget.articles.where((a) {
        if (_category.isNotEmpty && a.category != _category) return false;
        if (_status.isNotEmpty && a.status != _status) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Text('Artikel (${widget.total})',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                  const Spacer(),
                  _DropdownFilter(
                    value: _category,
                    items: _categories,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(width: 8),
                  _DropdownFilter(
                    value: _status,
                    items: _statuses,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Buat Artikel'),
                    onPressed: () => _showArticleForm(context, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DataTable2(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                columns: const [
                  DataColumn2(label: Text('Judul'), size: ColumnSize.L),
                  DataColumn2(label: Text('Kategori'), size: ColumnSize.M),
                  DataColumn2(label: Text('Status'), size: ColumnSize.S),
                  DataColumn2(label: Text('Tgl Publish'), size: ColumnSize.M),
                  DataColumn2(label: Text('Author'), size: ColumnSize.M),
                  DataColumn2(label: Text('Aksi'), size: ColumnSize.S, fixedWidth: 100),
                ],
                rows: filtered.map((a) => DataRow2(cells: [
                  DataCell(Text(a.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(_CategoryPill(a.categoryLabel)),
                  DataCell(_StatusPill(a.status, a.statusLabel)),
                  DataCell(Text(a.publishedAt != null ? DateFormatUtil.toDisplay(a.publishedAt!) : '—')),
                  DataCell(Text(a.authorName)),
                  DataCell(Row(children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                      onPressed: () => _showArticleForm(context, a),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      onPressed: () => _confirmDelete(context, a),
                      tooltip: 'Hapus',
                    ),
                  ])),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArticleForm(BuildContext context, CmsArticleEntity? article) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CmsCubit>(),
        child: _ArticleFormDialog(article: article),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CmsArticleEntity article) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Artikel'),
        content: Text('Hapus artikel "${article.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CmsCubit>().deleteArticle(article.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ArticleFormDialog extends StatefulWidget {
  final CmsArticleEntity? article;
  const _ArticleFormDialog({this.article});

  @override
  State<_ArticleFormDialog> createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<_ArticleFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _metaTitleCtrl;
  late final TextEditingController _metaDescCtrl;
  late String _category;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _slugCtrl = TextEditingController(text: a?.slug ?? '');
    _contentCtrl = TextEditingController(text: a?.content ?? '');
    _metaTitleCtrl = TextEditingController(text: a?.metaTitle ?? '');
    _metaDescCtrl = TextEditingController(text: a?.metaDescription ?? '');
    _category = a?.category ?? 'tips_karir';
    _status = a?.status ?? 'draft';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _contentCtrl.dispose();
    _metaTitleCtrl.dispose();
    _metaDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.article != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Artikel' : 'Buat Artikel Baru'),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Judul', _titleCtrl),
              const SizedBox(height: 12),
              _field('Slug', _slugCtrl),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dropdown('Kategori', _category, [
                  ('tips_karir', 'Tips Karir'),
                  ('info_kursus', 'Info Kursus'),
                  ('berita', 'Berita'),
                  ('event', 'Event'),
                ], (v) => setState(() => _category = v))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown('Status', _status, [
                  ('draft', 'Draft'),
                  ('published', 'Published'),
                ], (v) => setState(() => _status = v))),
              ]),
              const SizedBox(height: 12),
              _field('Konten', _contentCtrl, maxLines: 6),
              const SizedBox(height: 20),
              Text('SEO', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              _field('Meta Title', _metaTitleCtrl),
              const SizedBox(height: 12),
              _field('Meta Description', _metaDescCtrl, maxLines: 3),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Simpan' : 'Buat', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          isDense: true,
        ),
      );

  Widget _dropdown(String label, String value, List<(String, String)> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        isDense: true,
      ),
      items: items.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'title': _titleCtrl.text,
      'slug': _slugCtrl.text,
      'category': _category,
      'content': _contentCtrl.text,
      'status': _status,
      'seo': {'meta_title': _metaTitleCtrl.text, 'meta_description': _metaDescCtrl.text},
    };
    if (widget.article != null) {
      await context.read<CmsCubit>().updateArticle(widget.article!.id, data);
    } else {
      await context.read<CmsCubit>().createArticle(data);
    }
    if (mounted) Navigator.pop(context);
  }
}

// ─── Testimonials Tab ─────────────────────────────────────────────────────────

class _TestimonialsTab extends StatelessWidget {
  final List<CmsTestimonialEntity> testimonials;
  const _TestimonialsTab({required this.testimonials});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Text('Testimoni (${testimonials.length})',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Testimoni'),
                    onPressed: () => _showForm(context, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DataTable2(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                columns: const [
                  DataColumn2(label: Text('Nama'), size: ColumnSize.M),
                  DataColumn2(label: Text('Kursus'), size: ColumnSize.M),
                  DataColumn2(label: Text('Rating'), size: ColumnSize.S),
                  DataColumn2(label: Text('Featured'), size: ColumnSize.S),
                  DataColumn2(label: Text('Aksi'), size: ColumnSize.S, fixedWidth: 100),
                ],
                rows: testimonials.map((t) => DataRow2(cells: [
                  DataCell(Text(t.studentName, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text(t.courseName)),
                  DataCell(Text('⭐ ${t.rating}/5')),
                  DataCell(Icon(
                    t.isFeatured ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: t.isFeatured ? AppColors.success : AppColors.textHint,
                    size: 18,
                  )),
                  DataCell(Row(children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                      onPressed: () => _showForm(context, t),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      onPressed: () => _confirmDelete(context, t),
                      tooltip: 'Hapus',
                    ),
                  ])),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, CmsTestimonialEntity? item) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CmsCubit>(),
        child: _TestimonialFormDialog(item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CmsTestimonialEntity item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Testimoni'),
        content: Text('Hapus testimoni dari "${item.studentName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CmsCubit>().deleteTestimonial(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TestimonialFormDialog extends StatefulWidget {
  final CmsTestimonialEntity? item;
  const _TestimonialFormDialog({this.item});

  @override
  State<_TestimonialFormDialog> createState() => _TestimonialFormDialogState();
}

class _TestimonialFormDialogState extends State<_TestimonialFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _quoteCtrl;
  late int _rating;
  late bool _featured;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.item;
    _nameCtrl = TextEditingController(text: t?.studentName ?? '');
    _courseCtrl = TextEditingController(text: t?.courseName ?? '');
    _quoteCtrl = TextEditingController(text: t?.quote ?? '');
    _rating = t?.rating ?? 5;
    _featured = t?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _courseCtrl.dispose();
    _quoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item != null ? 'Edit Testimoni' : 'Tambah Testimoni'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Nama Siswa', _nameCtrl),
              const SizedBox(height: 12),
              _field('Kursus', _courseCtrl),
              const SizedBox(height: 12),
              _field('Quote', _quoteCtrl, maxLines: 4),
              const SizedBox(height: 12),
              Text('Rating', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                )),
              ),
              SwitchListTile(
                title: const Text('Featured (tampil di beranda)'),
                value: _featured,
                onChanged: (v) => setState(() => _featured = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          isDense: true,
        ),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'student_name': _nameCtrl.text,
      'course_name': _courseCtrl.text,
      'quote': _quoteCtrl.text,
      'rating': _rating,
      'is_featured': _featured,
    };
    if (widget.item != null) {
      await context.read<CmsCubit>().updateTestimonial(widget.item!.id, data);
    } else {
      await context.read<CmsCubit>().createTestimonial(data);
    }
    if (mounted) Navigator.pop(context);
  }
}

// ─── FAQ Tab ──────────────────────────────────────────────────────────────────

class _FaqTab extends StatefulWidget {
  final List<CmsFaqEntity> faqs;
  const _FaqTab({required this.faqs});

  @override
  State<_FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<_FaqTab> {
  String _category = '';

  static const _categories = [
    ('', 'Semua Kategori'),
    ('umum', 'Umum'),
    ('pendaftaran', 'Pendaftaran'),
    ('pembayaran', 'Pembayaran'),
    ('sertifikat', 'Sertifikat'),
    ('program_karir', 'Program Karir'),
  ];

  List<CmsFaqEntity> get _filtered => widget.faqs.where((f) {
        if (_category.isNotEmpty && f.category != _category) return false;
        return true;
      }).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Text('FAQ (${widget.faqs.length})',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                  const Spacer(),
                  _DropdownFilter(
                    value: _category,
                    items: _categories,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah FAQ'),
                    onPressed: () => _showForm(context, null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DataTable2(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                columns: const [
                  DataColumn2(label: Text('Pertanyaan'), size: ColumnSize.L),
                  DataColumn2(label: Text('Kategori'), size: ColumnSize.M),
                  DataColumn2(label: Text('Halaman'), size: ColumnSize.M),
                  DataColumn2(label: Text('Order'), size: ColumnSize.S),
                  DataColumn2(label: Text('Aksi'), size: ColumnSize.S, fixedWidth: 100),
                ],
                rows: filtered.map((f) => DataRow2(cells: [
                  DataCell(Text(
                    f.question.length > 60 ? '${f.question.substring(0, 60)}…' : f.question,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )),
                  DataCell(Text(f.categoryLabel)),
                  DataCell(Text(f.pageSlugs.isEmpty ? '—' : f.pageSlugs.join(', '))),
                  DataCell(Text('${f.sortOrder}')),
                  DataCell(Row(children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                      onPressed: () => _showForm(context, f),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      onPressed: () => _confirmDelete(context, f),
                      tooltip: 'Hapus',
                    ),
                  ])),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(BuildContext context, CmsFaqEntity? faq) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CmsCubit>(),
        child: _FaqFormDialog(faq: faq),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CmsFaqEntity faq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus FAQ'),
        content: Text('Hapus FAQ "${faq.question.substring(0, faq.question.length > 40 ? 40 : faq.question.length)}…"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CmsCubit>().deleteFaq(faq.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _FaqFormDialog extends StatefulWidget {
  final CmsFaqEntity? faq;
  const _FaqFormDialog({this.faq});

  @override
  State<_FaqFormDialog> createState() => _FaqFormDialogState();
}

class _FaqFormDialogState extends State<_FaqFormDialog> {
  late final TextEditingController _questionCtrl;
  late final TextEditingController _answerCtrl;
  late String _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.faq;
    _questionCtrl = TextEditingController(text: f?.question ?? '');
    _answerCtrl = TextEditingController(text: f?.answer ?? '');
    _category = f?.category ?? 'umum';
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.faq != null ? 'Edit FAQ' : 'Tambah FAQ'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _questionCtrl,
                decoration: InputDecoration(
                  labelText: 'Pertanyaan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Jawaban',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'umum', child: Text('Umum')),
                  DropdownMenuItem(value: 'pendaftaran', child: Text('Pendaftaran')),
                  DropdownMenuItem(value: 'pembayaran', child: Text('Pembayaran')),
                  DropdownMenuItem(value: 'sertifikat', child: Text('Sertifikat')),
                  DropdownMenuItem(value: 'program_karir', child: Text('Program Karir')),
                ],
                onChanged: (v) { if (v != null) setState(() => _category = v); },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'question': _questionCtrl.text,
      'answer': _answerCtrl.text,
      'category': _category,
    };
    if (widget.faq != null) {
      await context.read<CmsCubit>().updateFaq(widget.faq!.id, data);
    } else {
      await context.read<CmsCubit>().createFaq(data);
    }
    if (mounted) Navigator.pop(context);
  }
}

// ─── Media Library Tab ────────────────────────────────────────────────────────

class _MediaTab extends StatelessWidget {
  final List<CmsMediaEntity> media;
  const _MediaTab({required this.media});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Text('Media Library (${media.length})',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15)),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: const Text('Upload Media'),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: media.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.perm_media_outlined, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text('Belum ada media', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: media.length,
                      itemBuilder: (context, index) =>
                          _MediaCard(item: media[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final CmsMediaEntity item;
  const _MediaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusMd)),
              child: item.isImage
                  ? Image.network(item.url, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: Icon(Icons.broken_image, color: AppColors.textHint),
                          ))
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: Icon(Icons.insert_drive_file, color: AppColors.textHint, size: 40),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(item.sizeLabel, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: item.url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL disalin'), duration: Duration(seconds: 2)),
                          );
                        },
                        child: Icon(Icons.copy, size: 16, color: AppColors.primary),
                      ),
                    ),
                    InkWell(
                      onTap: () => _confirmDelete(context),
                      child: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Media'),
        content: Text('Hapus file "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CmsCubit>().deleteMedia(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── SEO Overview Tab ─────────────────────────────────────────────────────────

class _SeoTab extends StatelessWidget {
  final List<CmsPageEntity> pages;
  const _SeoTab({required this.pages});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Text(
                'SEO Overview',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: DataTable2(
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                columnSpacing: AppDimensions.md,
                horizontalMargin: AppDimensions.md,
                headingRowHeight: AppDimensions.tableHeaderHeight,
                dataRowHeight: AppDimensions.tableRowHeight,
                columns: const [
                  DataColumn2(label: Text('Halaman'), size: ColumnSize.L),
                  DataColumn2(label: Text('Meta Title'), size: ColumnSize.S),
                  DataColumn2(label: Text('Meta Desc'), size: ColumnSize.S),
                  DataColumn2(label: Text('OG Image'), size: ColumnSize.S),
                  DataColumn2(label: Text('Score'), size: ColumnSize.S),
                  DataColumn2(label: Text('Aksi'), size: ColumnSize.S, fixedWidth: 80),
                ],
                rows: pages.map((p) {
                  final score = p.seoScore;
                  return DataRow2(cells: [
                    DataCell(Text(p.title.isEmpty ? p.slug : p.title,
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(_SeoCheck(p.metaTitle.isNotEmpty)),
                    DataCell(_SeoCheck(p.metaDescription.isNotEmpty)),
                    DataCell(_SeoCheck(p.ogImage.isNotEmpty)),
                    DataCell(_SeoScore(score)),
                    DataCell(IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      tooltip: 'Edit SEO',
                      onPressed: () => _showPageEditor(context, p),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPageEditor(BuildContext context, CmsPageEntity page) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<CmsCubit>(),
        child: _PageEditorDialog(page: page),
      ),
    );
  }
}

class _SeoCheck extends StatelessWidget {
  final bool ok;
  const _SeoCheck(this.ok);

  @override
  Widget build(BuildContext context) => Icon(
        ok ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: ok ? AppColors.success : AppColors.error,
      );
}

class _SeoScore extends StatelessWidget {
  final int score;
  const _SeoScore(this.score);

  @override
  Widget build(BuildContext context) {
    final color = score == 100
        ? AppColors.success
        : score >= 67
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        '$score%',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          items: items
              .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  const _CategoryPill(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.infoSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(label, style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w500)),
      );
}

class _StatusPill extends StatelessWidget {
  final String status;
  final String label;
  const _StatusPill(this.status, this.label);

  Color get _color => switch (status) {
        'published' => AppColors.success,
        'draft' => AppColors.warning,
        _ => AppColors.textSecondary,
      };

  Color get _bg => switch (status) {
        'published' => AppColors.successSurface,
        'draft' => AppColors.warningSurface,
        _ => AppColors.surfaceVariant,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w500)),
      );
}
