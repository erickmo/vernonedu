import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';
import '../../core/widgets/section_header.dart';
import 'data/article_data.dart';

/// Halaman Update/Blog VernonEdu.
class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  String _selectedCategory = 'Semua';

  List<ArticleModel> get _filtered => ArticleData.articles.where((a) {
        return _selectedCategory == 'Semua' ||
            a.category.toLowerCase() ==
                _selectedCategory.toLowerCase();
      }).toList();

  @override
  Widget build(BuildContext context) {
    final padH = Responsive.sectionPaddingH(context);
    final isMobile = Responsive.isMobile(context);

    return WebScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _UpdatePageHeader(padH: padH),

          // Categories
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: AppDimensions.s24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ArticleData.categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          color: isSelected ? null : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppColors.border,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: AppTextStyles.labelS.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Featured articles (top 2)
          if (_selectedCategory == 'Semua') ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padH),
              child: _FeaturedArticles(
                articles: _filtered.where((a) => a.isFeatured).take(2).toList(),
                isMobile: isMobile,
              ),
            ),
            const SizedBox(height: AppDimensions.s40),
          ],

          // All articles grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCategory == 'Semua')
                  Text(
                    'Artikel Terbaru',
                    style: AppTextStyles.h2,
                  ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: AppDimensions.s24),
                _ArticleGrid(
                  articles: _selectedCategory == 'Semua'
                      ? _filtered.where((a) => !a.isFeatured).toList()
                      : _filtered,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),

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
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: AppDimensions.s80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3D2068), Color(0xFF5B3A9A), Color(0xFF7C68EE)],
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
  final List<ArticleModel> articles;
  final bool isMobile;

  const _FeaturedArticles({required this.articles, required this.isMobile});

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
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.s16),
                          child: _FeaturedArticleCard(article: a),
                        ))
                    .toList(),
              )
            : Row(
                children: articles.asMap().entries.map((e) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: e.key == 0 ? 16 : 0),
                      child: _FeaturedArticleCard(article: e.value),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

class _FeaturedArticleCard extends StatefulWidget {
  final ArticleModel article;

  const _FeaturedArticleCard({required this.article});

  @override
  State<_FeaturedArticleCard> createState() => _FeaturedArticleCardState();
}

class _FeaturedArticleCardState extends State<_FeaturedArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppDimensions.r20),
          border: Border.all(
            color: _hovered
                ? widget.article.color.withValues(alpha: 0.4)
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
                      widget.article.color,
                      widget.article.color.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        widget.article.icon,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 80,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandGold,
                          borderRadius: BorderRadius.circular(999),
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
              padding: const EdgeInsets.all(AppDimensions.s20),
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
                        backgroundColor: widget.article.color,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.article.author, style: AppTextStyles.labelS),
                            Text(
                              '${widget.article.date} · ${widget.article.readTime} baca',
                              style: AppTextStyles.bodyXS,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.brandIndigo, size: 16),
                          Text(
                            'Baca',
                            style: AppTextStyles.labelS.copyWith(color: AppColors.brandIndigo),
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
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}

class _ArticleGrid extends StatelessWidget {
  final List<ArticleModel> articles;
  final bool isMobile;

  const _ArticleGrid({required this.articles, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : (MediaQuery.of(context).size.width < 1100 ? 2 : 3),
        mainAxisSpacing: AppDimensions.s20,
        crossAxisSpacing: AppDimensions.s20,
        childAspectRatio: isMobile ? 3.0 : 0.85,
      ),
      itemCount: articles.length,
      itemBuilder: (context, i) => _ArticleCard(article: articles[i], index: i),
    );
  }
}

class _ArticleCard extends StatefulWidget {
  final ArticleModel article;
  final int index;

  const _ArticleCard({required this.article, required this.index});

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppDimensions.r16),
          border: Border.all(
            color: _hovered
                ? widget.article.color.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: isMobile
            ? _MobileArticleCard(article: widget.article)
            : _DesktopArticleCardContent(article: widget.article, hovered: _hovered),
      )
          .animate(delay: (widget.index * 80).ms)
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.15, end: 0),
    );
  }
}

class _DesktopArticleCardContent extends StatelessWidget {
  final ArticleModel article;
  final bool hovered;

  const _DesktopArticleCardContent({required this.article, required this.hovered});

  @override
  Widget build(BuildContext context) {
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
                colors: [article.color, article.color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(article.icon,
                      color: Colors.white.withValues(alpha: 0.3), size: 48),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      article.category,
                      style: AppTextStyles.badge.copyWith(color: Colors.white, fontSize: 9),
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
                    style: AppTextStyles.bodyXS.copyWith(height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: article.color,
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
                        '${article.date} · ${article.readTime}',
                        style: AppTextStyles.bodyXS.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: article.color, size: 14),
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
  final ArticleModel article;

  const _MobileArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [article.color, article.color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.r16),
              bottomLeft: Radius.circular(AppDimensions.r16),
            ),
          ),
          child: Center(
            child: Icon(article.icon, color: Colors.white.withValues(alpha: 0.6), size: 26),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(article.title, style: AppTextStyles.labelM, maxLines: 2),
                const SizedBox(height: 4),
                Text('${article.date} · ${article.readTime} baca',
                    style: AppTextStyles.bodyXS),
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
      padding: EdgeInsets.all(isMobile ? AppDimensions.s24 : AppDimensions.s48),
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
            style: AppTextStyles.bodyXS.copyWith(color: Colors.white.withValues(alpha: 0.7)),
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
      style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Masukkan email Anda...',
        hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgSurface,
        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
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
          borderSide: const BorderSide(color: AppColors.brandIndigo, width: 2),
        ),
      ),
    );
  }
}
