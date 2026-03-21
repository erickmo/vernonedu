import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/public_api_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';
import '../../core/widgets/section_header.dart';
import 'data/article_data.dart';

/// Halaman Update/Blog VernonEdu — API-powered dengan fallback ke data statis.
class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  List<PublicArticle> _articles = [];
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  Timer? _debounce;
  static const _pageSize = 9;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchArticles({bool resetPage = true}) async {
    if (resetPage) setState(() => _page = 0);
    setState(() => _loading = true);
    final (articles, total) = await PublicApiService.getArticles(
      offset: _page * _pageSize,
      limit: _pageSize,
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (mounted) {
      setState(() {
        _articles = articles.isNotEmpty ? articles : _staticArticles();
        _total = total > 0 ? total : _articles.length;
        _loading = false;
      });
    }
  }

  List<PublicArticle> _staticArticles() {
    return ArticleData.articles
        .map(
          (a) => PublicArticle(
            id: a.id,
            slug: a.id,
            title: a.title,
            excerpt: a.excerpt,
            content: '',
            category: a.category,
            author: a.author,
            publishedAt: a.date,
            imageUrl: '',
            tags: a.tags,
            isFeatured: a.isFeatured,
          ),
        )
        .toList();
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'marketing':
        return const Color(0xFF4F46E5);
      case 'keuangan':
        return const Color(0xFF10B981);
      case 'strategi':
        return const Color(0xFF7C3AED);
      case 'e-commerce':
        return const Color(0xFF0EA5E9);
      case 'leadership':
        return const Color(0xFFEC4899);
      case 'success story':
        return const Color(0xFFF59E0B);
      case 'announcement':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'marketing':
        return Icons.trending_up_rounded;
      case 'keuangan':
        return Icons.account_balance_rounded;
      case 'strategi':
        return Icons.dashboard_customize_rounded;
      case 'e-commerce':
        return Icons.shopping_bag_rounded;
      case 'leadership':
        return Icons.psychology_rounded;
      case 'success story':
        return Icons.emoji_events_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Widget _buildPagination() {
    final totalPages = (_total / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _page > 0
              ? () {
                  setState(() => _page--);
                  _fetchArticles(resetPage: false);
                }
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        ...List.generate(
          totalPages,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () {
                setState(() => _page = i);
                _fetchArticles(resetPage: false);
              },
              style: TextButton.styleFrom(
                backgroundColor:
                    _page == i ? const Color(0xFF4F46E5) : Colors.transparent,
                minimumSize: const Size(36, 36),
              ),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: _page == i ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _page < totalPages - 1
              ? () {
                  setState(() => _page++);
                  _fetchArticles(resetPage: false);
                }
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padH = Responsive.sectionPaddingH(context);
    final isMobile = Responsive.isMobile(context);

    final featuredArticles =
        _articles.where((a) => a.isFeatured).take(2).toList();
    final nonFeaturedArticles =
        _articles.where((a) => !a.isFeatured).toList();

    return WebScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _UpdatePageHeader(padH: padH),

          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH).copyWith(
              top: AppDimensions.s24,
              bottom: AppDimensions.s8,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari artikel...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF4F46E5), width: 2),
                ),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce =
                    Timer(const Duration(milliseconds: 300), () {
                  setState(() => _searchQuery = v);
                  _fetchArticles();
                });
              },
            ),
          ),

          // Categories
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: padH, vertical: AppDimensions.s16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ArticleData.categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        _fetchArticles();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? AppColors.primaryGradient
                              : null,
                          color:
                              isSelected ? null : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTextStyles.labelS.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Loading or content
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.s80),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF4F46E5)),
              ),
            )
          else ...[
            // Featured articles (top 2) — only when showing "Semua" with no search
            if (_selectedCategory == 'Semua' &&
                _searchQuery.isEmpty &&
                featuredArticles.isNotEmpty) ...[
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: padH),
                child: _FeaturedArticles(
                  articles: featuredArticles,
                  isMobile: isMobile,
                  categoryColor: _categoryColor,
                  categoryIcon: _categoryIcon,
                ),
              ),
              const SizedBox(height: AppDimensions.s40),
            ],

            // All articles grid
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: padH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedCategory == 'Semua' &&
                      _searchQuery.isEmpty)
                    Text(
                      'Artikel Terbaru',
                      style: AppTextStyles.h2,
                    ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: AppDimensions.s24),
                  _ArticleGrid(
                    articles: (_selectedCategory == 'Semua' &&
                            _searchQuery.isEmpty)
                        ? nonFeaturedArticles
                        : _articles,
                    isMobile: isMobile,
                    categoryColor: _categoryColor,
                    categoryIcon: _categoryIcon,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.s40),

            // Pagination
            _buildPagination(),
          ],

          const SizedBox(height: AppDimensions.s80),

          // Newsletter CTA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: _NewsletterBanner(),
          ),

          const SizedBox(height: AppDimensions.s64),

          const FooterWidget(),
        ],
      ),
    );
  }
}

class _UpdatePageHeader extends StatelessWidget {
  final double padH;

  const _UpdatePageHeader({required this.padH});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: padH, vertical: AppDimensions.s80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3D2068),
            Color(0xFF5B3A9A),
            Color(0xFF7C68EE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SectionHeader(
        badge: '📰 Blog & Update',
        title: 'Inspirasi & Pengetahuan\nuntuk Pengusaha',
        subtitle:
            'Tips bisnis, kisah sukses, tren industri, dan update terbaru dari VernonEdu. Baca dan terapkan hari ini.',
        isDark: true,
      ),
    );
  }
}

class _FeaturedArticles extends StatelessWidget {
  final List<PublicArticle> articles;
  final bool isMobile;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _FeaturedArticles({
    required this.articles,
    required this.isMobile,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Artikel Pilihan', style: AppTextStyles.h2)
            .animate()
            .fadeIn(duration: 400.ms),
        const SizedBox(height: AppDimensions.s24),
        isMobile
            ? Column(
                children: articles
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppDimensions.s16),
                        child: _FeaturedArticleCard(
                          article: a,
                          categoryColor: categoryColor,
                          categoryIcon: categoryIcon,
                        ),
                      ),
                    )
                    .toList(),
              )
            : Row(
                children: articles.asMap().entries.map((e) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: e.key == 0 ? 16 : 0),
                      child: _FeaturedArticleCard(
                        article: e.value,
                        categoryColor: categoryColor,
                        categoryIcon: categoryIcon,
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

class _FeaturedArticleCard extends StatefulWidget {
  final PublicArticle article;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _FeaturedArticleCard({
    required this.article,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<_FeaturedArticleCard> createState() =>
      _FeaturedArticleCardState();
}

class _FeaturedArticleCardState extends State<_FeaturedArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.categoryColor(widget.article.category);
    final icon = widget.categoryIcon(widget.article.category);
    final slug = widget.article.slug.isNotEmpty
        ? widget.article.slug
        : widget.article.id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/update/$slug'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius:
                BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.r20),
                  topRight: Radius.circular(AppDimensions.r20),
                ),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          icon,
                          color:
                              Colors.white.withValues(alpha: 0.3),
                          size: 80,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.article.category,
                            style: AppTextStyles.badge.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandGold,
                            borderRadius:
                                BorderRadius.circular(999),
                          ),
                          child: Text(
                            'FEATURED',
                            style: AppTextStyles.badge.copyWith(
                              color: const Color(0xFF78350F),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.all(AppDimensions.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.title,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.article.excerpt,
                      style: AppTextStyles.bodyS,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: color,
                          child: Text(
                            widget.article.authorInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(widget.article.author,
                                  style: AppTextStyles.labelS),
                              Text(
                                widget.article.publishedAt,
                                style: AppTextStyles.bodyXS,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                color: AppColors.brandIndigo,
                                size: 16),
                            Text(
                              'Baca',
                              style: AppTextStyles.labelS
                                  .copyWith(
                                      color:
                                          AppColors.brandIndigo),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}

class _ArticleGrid extends StatelessWidget {
  final List<PublicArticle> articles;
  final bool isMobile;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _ArticleGrid({
    required this.articles,
    required this.isMobile,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: AppDimensions.s64),
          child: Text(
            'Tidak ada artikel ditemukan.',
            style: AppTextStyles.bodyM,
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile
            ? 1
            : (MediaQuery.of(context).size.width < 1100 ? 2 : 3),
        mainAxisSpacing: AppDimensions.s20,
        crossAxisSpacing: AppDimensions.s20,
        childAspectRatio: isMobile ? 3.0 : 0.85,
      ),
      itemCount: articles.length,
      itemBuilder: (context, i) => _ArticleCard(
        article: articles[i],
        index: i,
        categoryColor: categoryColor,
        categoryIcon: categoryIcon,
      ),
    );
  }
}

class _ArticleCard extends StatefulWidget {
  final PublicArticle article;
  final int index;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _ArticleCard({
    required this.article,
    required this.index,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final color = widget.categoryColor(widget.article.category);
    final slug = widget.article.slug.isNotEmpty
        ? widget.article.slug
        : widget.article.id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/update/$slug'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform:
              Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius:
                BorderRadius.circular(AppDimensions.r16),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: isMobile
              ? _MobileArticleCard(article: widget.article,
                  categoryColor: widget.categoryColor,
                  categoryIcon: widget.categoryIcon)
              : _DesktopArticleCardContent(
                  article: widget.article,
                  hovered: _hovered,
                  categoryColor: widget.categoryColor,
                  categoryIcon: widget.categoryIcon,
                ),
        )
            .animate(delay: (widget.index * 80).ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.15, end: 0),
      ),
    );
  }
}

class _DesktopArticleCardContent extends StatelessWidget {
  final PublicArticle article;
  final bool hovered;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _DesktopArticleCardContent({
    required this.article,
    required this.hovered,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(article.category);
    final icon = categoryIcon(article.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.r16),
            topRight: Radius.circular(AppDimensions.r16),
          ),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 48),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      article.category,
                      style: AppTextStyles.badge
                          .copyWith(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: AppTextStyles.labelL.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    article.excerpt,
                    style:
                        AppTextStyles.bodyXS.copyWith(height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: color,
                      child: Text(
                        article.authorInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        article.publishedAt,
                        style: AppTextStyles.bodyXS
                            .copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: color, size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileArticleCard extends StatelessWidget {
  final PublicArticle article;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _MobileArticleCard({
    required this.article,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(article.category);
    final icon = categoryIcon(article.category);

    return Row(
      children: [
        Container(
          width: 60,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.r16),
              bottomLeft: Radius.circular(AppDimensions.r16),
            ),
          ),
          child: Center(
            child: Icon(icon,
                color: Colors.white.withValues(alpha: 0.6), size: 26),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(article.title,
                    style: AppTextStyles.labelM, maxLines: 2),
                const SizedBox(height: 4),
                Text(
                  article.publishedAt,
                  style: AppTextStyles.bodyXS,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NewsletterBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(
          isMobile ? AppDimensions.s24 : AppDimensions.s48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2068), Color(0xFF5B3A9A)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.r24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read_rounded,
              color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'Dapatkan Tips Bisnis Gratis\nSetiap Minggu',
            style: AppTextStyles.h2OnDark,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Bergabunglah dengan 25.000+ pengusaha yang sudah subscribe newsletter VernonEdu',
            style: AppTextStyles.bodyMOnDark,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          isMobile
              ? Column(
                  children: [
                    _EmailInput(),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Subscribe Sekarang',
                      onTap: () {},
                      height: 52,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 320, child: _EmailInput()),
                    const SizedBox(width: 12),
                    GradientButton(
                      label: 'Subscribe Sekarang',
                      onTap: () {},
                      height: 52,
                    ),
                  ],
                ),
          const SizedBox(height: 12),
          Text(
            '🔒 Tidak ada spam. Bisa unsubscribe kapan saja.',
            style: AppTextStyles.bodyXS
                .copyWith(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      style:
          AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Masukkan email Anda...',
        hintStyle:
            AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgSurface,
        prefixIcon:
            const Icon(Icons.email_outlined, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.brandIndigo, width: 2),
        ),
      ),
    );
  }
}
