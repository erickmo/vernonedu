import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/public_api_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/navbar_widget.dart';

/// Halaman detail artikel berdasarkan slug.
class ArticleDetailPage extends StatefulWidget {
  final String slug;

  const ArticleDetailPage({super.key, required this.slug});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  PublicArticle? _article;
  List<PublicArticle> _related = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      PublicApiService.getArticles(limit: 4),
      PublicApiService.getArticleBySlug(widget.slug),
    ]);

    final (articles, _) = results[0] as (List<PublicArticle>, int);
    final article = results[1] as PublicArticle?;

    if (mounted) {
      setState(() {
        _article = article;
        _related = articles
            .where((a) => a.slug != widget.slug && a.id != widget.slug)
            .take(3)
            .toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padH = Responsive.sectionPaddingH(context);

    return WebScaffold(
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.s80),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            )
          : _article == null
              ? _NotFoundBody(padH: padH)
              : _ArticleBody(
                  article: _article!,
                  related: _related,
                  padH: padH,
                ),
    );
  }
}

// ─── Not Found ────────────────────────────────────────────────────────────────

class _NotFoundBody extends StatelessWidget {
  final double padH;

  const _NotFoundBody({required this.padH});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: padH, vertical: AppDimensions.s80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined,
              size: 80, color: AppColors.textMuted),
          const SizedBox(height: AppDimensions.s24),
          Text('Artikel tidak ditemukan', style: AppTextStyles.h2),
          const SizedBox(height: AppDimensions.s12),
          Text(
            'Artikel yang Anda cari tidak tersedia atau sudah dihapus.',
            style: AppTextStyles.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.s32),
          TextButton.icon(
            onPressed: () => context.go('/update'),
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.brandIndigo),
            label: Text(
              'Kembali ke Blog',
              style:
                  AppTextStyles.labelM.copyWith(color: AppColors.brandIndigo),
            ),
          ),
          const SizedBox(height: AppDimensions.s80),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ─── Article Body ─────────────────────────────────────────────────────────────

class _ArticleBody extends StatelessWidget {
  final PublicArticle article;
  final List<PublicArticle> related;
  final double padH;

  const _ArticleBody({
    required this.article,
    required this.related,
    required this.padH,
  });

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

  /// Estimasi waktu baca berdasarkan panjang konten.
  String _readTime(String content) {
    final wordCount = content.trim().split(RegExp(r'\s+')).length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes menit baca';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final color = _categoryColor(article.category);
    final icon = _categoryIcon(article.category);
    final content =
        article.content.isNotEmpty ? article.content : article.excerpt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero header
        _ArticleHeroHeader(
          article: article,
          padH: padH,
          color: color,
          icon: icon,
          readTime: _readTime(content),
        ),

        // Content area
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? padH : padH * 2,
            vertical: AppDimensions.s48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              TextButton.icon(
                onPressed: () => context.go('/update'),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.brandIndigo, size: 18),
                label: Text(
                  'Kembali ke Blog',
                  style: AppTextStyles.labelS
                      .copyWith(color: AppColors.brandIndigo),
                ),
              ),

              const SizedBox(height: AppDimensions.s32),

              // Article content
              _buildContent(content),

              const SizedBox(height: AppDimensions.s32),

              // Tags
              if (article.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: article.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '#$tag',
                        style: AppTextStyles.labelS
                            .copyWith(color: color),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimensions.s32),
              ],

              // Share section
              _ShareSection(article: article),

              const SizedBox(height: AppDimensions.s64),

              // Related articles
              if (related.isNotEmpty)
                _RelatedArticles(
                  articles: related,
                  isMobile: isMobile,
                  categoryColor: _categoryColor,
                  categoryIcon: _categoryIcon,
                ),
            ],
          ),
        ),

        const FooterWidget(),
      ],
    );
  }

  Widget _buildContent(String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    final paragraphs = content.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                p.trim(),
                style: AppTextStyles.bodyM.copyWith(height: 1.8),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Article Hero Header ──────────────────────────────────────────────────────

class _ArticleHeroHeader extends StatelessWidget {
  final PublicArticle article;
  final double padH;
  final Color color;
  final IconData icon;
  final String readTime;

  const _ArticleHeroHeader({
    required this.article,
    required this.padH,
    required this.color,
    required this.icon,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: padH, vertical: AppDimensions.s80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.5),
            const Color(0xFF3D2068),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  article.category.toUpperCase(),
                  style: AppTextStyles.badge
                      .copyWith(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.s24),

          // Title
          Text(
            article.title,
            style: AppTextStyles.h1OnDark,
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppDimensions.s16),

          // Metadata
          Wrap(
            spacing: AppDimensions.s16,
            runSpacing: AppDimensions.s8,
            children: [
              _MetaChip(
                icon: Icons.person_outline_rounded,
                label: article.author,
              ),
              if (article.publishedAt.isNotEmpty)
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: article.publishedAt,
                ),
              _MetaChip(
                icon: Icons.access_time_rounded,
                label: readTime,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodyS
              .copyWith(color: Colors.white.withValues(alpha: 0.9)),
        ),
      ],
    );
  }
}

// ─── Share Section ────────────────────────────────────────────────────────────

class _ShareSection extends StatelessWidget {
  final PublicArticle article;

  const _ShareSection({required this.article});

  @override
  Widget build(BuildContext context) {
    final slug =
        article.slug.isNotEmpty ? article.slug : article.id;
    final url = 'https://vernonedu.id/update/$slug';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bagikan Artikel', style: AppTextStyles.labelM),
          const SizedBox(height: AppDimensions.s16),
          Wrap(
            spacing: AppDimensions.s8,
            runSpacing: AppDimensions.s8,
            children: [
              _ShareButton(
                icon: Icons.link_rounded,
                label: 'Salin Link',
                color: AppColors.brandIndigo,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link disalin ke clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              _ShareButton(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  // Opens WhatsApp share — no package needed for web
                },
              ),
              _ShareButton(
                icon: Icons.alternate_email_rounded,
                label: 'Twitter/X',
                color: const Color(0xFF1DA1F2),
                onTap: () {
                  // Opens Twitter share
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.s16, vertical: AppDimensions.s8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppDimensions.r8),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  color: _hovered ? widget.color : AppColors.textMuted,
                  size: 16),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTextStyles.labelS.copyWith(
                  color: _hovered ? widget.color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Related Articles ─────────────────────────────────────────────────────────

class _RelatedArticles extends StatelessWidget {
  final List<PublicArticle> articles;
  final bool isMobile;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _RelatedArticles({
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
        Text('Artikel Terkait', style: AppTextStyles.h2)
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
                        child: _RelatedArticleCard(
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
                        right: e.key < articles.length - 1
                            ? AppDimensions.s16
                            : 0,
                      ),
                      child: _RelatedArticleCard(
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

class _RelatedArticleCard extends StatefulWidget {
  final PublicArticle article;
  final Color Function(String) categoryColor;
  final IconData Function(String) categoryIcon;

  const _RelatedArticleCard({
    required this.article,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<_RelatedArticleCard> createState() => _RelatedArticleCardState();
}

class _RelatedArticleCardState extends State<_RelatedArticleCard> {
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
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppDimensions.r16),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.3)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.r16),
                  topRight: Radius.circular(AppDimensions.r16),
                ),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 40),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.category.toUpperCase(),
                      style: AppTextStyles.badge.copyWith(color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.article.title,
                      style: AppTextStyles.labelM,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.article.publishedAt,
                      style: AppTextStyles.bodyXS,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
