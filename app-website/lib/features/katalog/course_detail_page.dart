import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/public_course_model.dart';
import '../../core/router/app_router.dart';
import '../../core/services/public_course_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';
import '../../core/widgets/scroll_animate_widget.dart';

/// Course detail page — /katalog/:courseId
class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _service = PublicCourseService();
  PublicCourseDetailV2? _detail;
  bool _loading = true;
  String? _error;
  final _batchSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = await _service.fetchCourseDetailV2(widget.courseId);
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Gagal memuat detail kursus.'; _loading = false; });
      }
    }
  }

  void _scrollToBatch() {
    final ctx = _batchSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      body: Column(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 160),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorBody(message: _error!, onRetry: _load)
          else if (_detail != null)
            _CourseDetailBody(
              detail: _detail!,
              batchSectionKey: _batchSectionKey,
              onScrollToBatch: _scrollToBatch,
            )
          else
            const SizedBox.shrink(),
          const FooterWidget(),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Column(
        children: [
          Text(message, style: AppTextStyles.bodyL),
          const SizedBox(height: AppDimensions.s24),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _CourseDetailBody extends StatefulWidget {
  final PublicCourseDetailV2 detail;
  final GlobalKey batchSectionKey;
  final VoidCallback onScrollToBatch;

  const _CourseDetailBody({
    required this.detail,
    required this.batchSectionKey,
    required this.onScrollToBatch,
  });

  @override
  State<_CourseDetailBody> createState() => _CourseDetailBodyState();
}

class _CourseDetailBodyState extends State<_CourseDetailBody> {
  int _selectedTypeIndex = 0;

  PublicCourseTypeDetail? get _selectedType =>
      widget.detail.courseTypes.isNotEmpty
          ? widget.detail.courseTypes[_selectedTypeIndex]
          : null;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile
        ? AppDimensions.s24
        : Responsive.sectionPaddingH(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero section
        _HeroSection(
          detail: detail,
          hPad: hPad,
          isMobile: isMobile,
          onScrollToBatch: widget.onScrollToBatch,
        ),

        // 2. Tentang section
        _TentangSection(detail: detail, hPad: hPad),

        // 3. Tipe Program section
        if (detail.courseTypes.isNotEmpty)
          _TipeSection(
            courseTypes: detail.courseTypes,
            selectedIndex: _selectedTypeIndex,
            onTypeSelected: (i) => setState(() => _selectedTypeIndex = i),
            hPad: hPad,
          ),

        // 4. Batch section
        if (_selectedType != null)
          KeyedSubtree(
            key: widget.batchSectionKey,
            child: _BatchSection(
              courseId: detail.id,
              selectedType: _selectedType!,
              hPad: hPad,
            ),
          ),

        // 5. Fasilitator section
        if (detail.facilitators.isNotEmpty)
          _FasilitatorSection(
            facilitators: detail.facilitators,
            hPad: hPad,
          ),

        // 6. Testimoni section
        if (detail.testimonials.isNotEmpty)
          _TestimoniSection(
            testimonials: detail.testimonials,
            hPad: hPad,
          ),

        // 7. FAQ section
        if (detail.faqs.isNotEmpty)
          _FaqSection(faqs: detail.faqs, hPad: hPad),
      ],
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final PublicCourseDetailV2 detail;
  final double hPad;
  final bool isMobile;
  final VoidCallback onScrollToBatch;

  const _HeroSection({
    required this.detail,
    required this.hPad,
    required this.isMobile,
    required this.onScrollToBatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go(AppRouter.katalog),
                  child: Text(
                    'Katalog',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.brandPurple,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s8),
                child: Text('/', style: AppTextStyles.bodyS),
              ),
              Text(detail.name, style: AppTextStyles.bodyS),
            ],
          ),
          const SizedBox(height: AppDimensions.s24),

          // Type pills
          if (detail.courseTypes.isNotEmpty)
            Wrap(
              spacing: AppDimensions.s8,
              runSpacing: AppDimensions.s8,
              children: detail.courseTypes.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.s12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.r999),
                  ),
                  child: Text(
                    t.name,
                    style: AppTextStyles.labelS.copyWith(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: AppDimensions.s16),

          // Course name
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              detail.name,
              style: isMobile ? AppTextStyles.displayM : AppTextStyles.displayL,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          ),
          const SizedBox(height: AppDimensions.s16),

          // Short description
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              detail.shortDesc,
              style: AppTextStyles.bodyL,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          ),
          const SizedBox(height: AppDimensions.s24),

          // Stats row
          Wrap(
            spacing: AppDimensions.s24,
            runSpacing: AppDimensions.s12,
            children: [
              _StatChip(
                icon: Icons.group_outlined,
                text: '${detail.totalStudents} siswa',
              ),
              _StatChip(
                icon: Icons.class_outlined,
                text: '${detail.totalBatches} batch',
              ),
              if (detail.rating > 0)
                _StatChip(
                  icon: Icons.star_rounded,
                  text: detail.rating.toStringAsFixed(1),
                  iconColor: AppColors.brandGold,
                ),
              if (detail.departmentName.isNotEmpty)
                _StatChip(
                  icon: Icons.business_outlined,
                  text: detail.departmentName,
                ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: AppDimensions.s32),

          // CTA
          GradientButton(
            label: 'Pilih Jadwal & Daftar',
            onTap: onScrollToBatch,
            height: AppDimensions.btnHeightL,
            horizontalPadding: 32,
            icon: Icons.calendar_today_rounded,
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _StatChip({required this.icon, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s12,
        vertical: AppDimensions.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? AppColors.brandPurple),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.labelS),
        ],
      ),
    );
  }
}

// ─── Tentang Section ──────────────────────────────────────────────────────────

class _TentangSection extends StatelessWidget {
  final PublicCourseDetailV2 detail;
  final double hPad;

  const _TentangSection({required this.detail, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'tentang-title',
            child: Text('Tentang Program', style: AppTextStyles.h2),
          ),
          const SizedBox(height: AppDimensions.s24),
          ScrollAnimateWidget(
            uniqueKey: 'tentang-desc',
            child: Text(detail.description, style: AppTextStyles.bodyM),
          ),

          if (detail.requirements.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.s40),
            ScrollAnimateWidget(
              uniqueKey: 'tentang-req-title',
              child: Text('Syarat Peserta', style: AppTextStyles.h3),
            ),
            const SizedBox(height: AppDimensions.s16),
            ...detail.requirements.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppDimensions.s8),
                    Expanded(child: Text(r, style: AppTextStyles.bodyM)),
                  ],
                ),
              ),
            ),
          ],

          if (detail.objectives.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.s40),
            ScrollAnimateWidget(
              uniqueKey: 'tentang-obj-title',
              child: Text('Yang Akan Kamu Pelajari', style: AppTextStyles.h3),
            ),
            const SizedBox(height: AppDimensions.s16),
            Wrap(
              spacing: AppDimensions.s12,
              runSpacing: AppDimensions.s12,
              children: detail.objectives
                  .map((o) => _ObjectiveChip(text: o))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ObjectiveChip extends StatelessWidget {
  final String text;

  const _ObjectiveChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s16,
        vertical: AppDimensions.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
          const SizedBox(width: AppDimensions.s8),
          Text(text, style: AppTextStyles.bodyS),
        ],
      ),
    );
  }
}

// ─── Tipe Section ─────────────────────────────────────────────────────────────

class _TipeSection extends StatelessWidget {
  final List<PublicCourseTypeDetail> courseTypes;
  final int selectedIndex;
  final void Function(int) onTypeSelected;
  final double hPad;

  const _TipeSection({
    required this.courseTypes,
    required this.selectedIndex,
    required this.onTypeSelected,
    required this.hPad,
  });

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final selected = courseTypes[selectedIndex];
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'tipe-title',
            child: Text('Tipe Program Tersedia', style: AppTextStyles.h2),
          ),
          const SizedBox(height: AppDimensions.s24),

          // Horizontal pill selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: courseTypes.asMap().entries.map((e) {
                final isSelected = e.key == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: AppDimensions.s8),
                  child: _TypePill(
                    label: e.value.name,
                    selected: isSelected,
                    onTap: () => onTypeSelected(e.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppDimensions.s24),

          // Type detail card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(selectedIndex),
              padding: const EdgeInsets.all(AppDimensions.s24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDimensions.r16),
                border: Border.all(color: AppColors.border),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildTypeInfoItems(selected),
                    )
                  : Row(
                      children: _buildTypeInfoItems(selected)
                          .map((w) => Expanded(child: w))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeInfoItems(PublicCourseTypeDetail t) {
    return [
      _TypeInfoItem(
        label: 'Harga',
        value: '${_formatPrice(t.minPrice)} — ${_formatPrice(t.normalPrice)}',
      ),
      _TypeInfoItem(
        label: 'Durasi',
        value: '${t.sessionCount} sesi',
      ),
      _TypeInfoItem(
        label: 'Peserta',
        value: '${t.minParticipants}–${t.maxParticipants} orang/batch',
      ),
      _TypeInfoItem(
        label: 'Sertifikat',
        customValue: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.hasCertParticipant)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text('Peserta', style: AppTextStyles.bodyS),
                ],
              ),
            if (t.hasCertCompetency)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.brandGold),
                  const SizedBox(width: 4),
                  Text('Kompetensi', style: AppTextStyles.bodyS),
                ],
              ),
            if (!t.hasCertParticipant && !t.hasCertCompetency)
              Text('—', style: AppTextStyles.bodyS),
          ],
        ),
      ),
    ];
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s20,
            vertical: AppDimensions.s12,
          ),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r999),
            border: Border.all(
              color: selected ? AppColors.brandPurple : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelM.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeInfoItem extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? customValue;

  const _TypeInfoItem({required this.label, this.value, this.customValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.s16,
        right: AppDimensions.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyXS.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          if (customValue != null)
            customValue!
          else
            Text(value ?? '—', style: AppTextStyles.labelM),
        ],
      ),
    );
  }
}

// ─── Batch Section ────────────────────────────────────────────────────────────

class _BatchSection extends StatelessWidget {
  final String courseId;
  final PublicCourseTypeDetail selectedType;
  final double hPad;

  const _BatchSection({
    required this.courseId,
    required this.selectedType,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'batch-title-${selectedType.id}',
            child: Text(
              'Batch Tersedia — ${selectedType.name}',
              style: AppTextStyles.h2,
            ),
          ),
          const SizedBox(height: AppDimensions.s24),
          if (selectedType.batches.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.s24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: Text(
                      'Belum ada jadwal tersedia. Hubungi kami untuk info lebih lanjut.',
                      style: AppTextStyles.bodyM,
                    ),
                  ),
                ],
              ),
            )
          else
            ...selectedType.batches.map(
              (b) => _BatchCard(
                batch: b,
                courseId: courseId,
              ),
            ),
        ],
      ),
    );
  }
}

class _BatchCard extends StatefulWidget {
  final PublicBatch batch;
  final String courseId;

  const _BatchCard({required this.batch, required this.courseId});

  @override
  State<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<_BatchCard> {
  bool _showSchedule = false;

  String _fmtDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _fmtPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.batch;
    final isMobile = Responsive.isMobile(context);
    final enrollFraction = b.maxStudents > 0
        ? b.enrolledCount / b.maxStudents
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(
          color: b.isFull ? AppColors.border : AppColors.brandPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: full badge + price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (b.isFull)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.s8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(AppDimensions.r4),
                              ),
                              child: Text(
                                'KUOTA PENUH',
                                style: AppTextStyles.badge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (b.isFull) const SizedBox(height: AppDimensions.s8),
                          Text(
                            '${_fmtDate(b.startDate)} — ${b.endDate != null ? _fmtDate(b.endDate!) : "TBD"}',
                            style: AppTextStyles.labelM,
                          ),
                          const SizedBox(height: AppDimensions.s4),
                          if (b.facilitatorName.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  b.facilitatorName,
                                  style: AppTextStyles.bodyS,
                                ),
                              ],
                            ),
                          const SizedBox(height: AppDimensions.s4),
                          if (b.location.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(b.location, style: AppTextStyles.bodyS),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtPrice(b.price),
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.brandPurple,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.s4),
                        Text(
                          _paymentLabel(b.paymentMethod),
                          style: AppTextStyles.bodyXS,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.s16),

                // Enrollment progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${b.enrolledCount}/${b.maxStudents} peserta',
                          style: AppTextStyles.bodyXS,
                        ),
                        Text(
                          b.isFull ? 'Penuh' : '${b.availableSlots} slot tersisa',
                          style: AppTextStyles.bodyXS.copyWith(
                            color: b.isFull ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.r999),
                      child: LinearProgressIndicator(
                        value: enrollFraction.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          b.isFull ? AppColors.textMuted : AppColors.brandPurple,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.s16),

                // Action row
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildActionWidgets(context, b),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _buildActionWidgets(context, b),
                      ),
              ],
            ),
          ),

          // Expandable schedule
          if (_showSchedule && b.schedules.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: const BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.r16),
                  bottomRight: Radius.circular(AppDimensions.r16),
                ),
              ),
              padding: const EdgeInsets.all(AppDimensions.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jadwal Sesi', style: AppTextStyles.labelM),
                  const SizedBox(height: AppDimensions.s12),
                  ...b.schedules.map((s) => _ScheduleRow(schedule: s)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActionWidgets(BuildContext context, PublicBatch b) {
    return [
      TextButton.icon(
        onPressed: () => setState(() => _showSchedule = !_showSchedule),
        icon: Icon(
          _showSchedule
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: AppDimensions.iconS,
        ),
        label: Text(
          _showSchedule ? 'Sembunyikan Jadwal' : 'Lihat Jadwal',
          style: AppTextStyles.labelS.copyWith(color: AppColors.brandPurple),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPurple,
          padding: EdgeInsets.zero,
        ),
      ),
      if (b.isFull)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s16,
            vertical: AppDimensions.s8,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppDimensions.r8),
          ),
          child: Text('Kuota Penuh', style: AppTextStyles.bodyS),
        )
      else
        GradientButton(
          label: 'Daftar →',
          onTap: () => context.go('${AppRouter.daftar}/${b.id}'),
          height: 40,
          horizontalPadding: AppDimensions.s20,
          borderRadius: AppDimensions.r8,
        ),
    ];
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'upfront':
        return 'Bayar penuh';
      case 'scheduled':
        return 'Cicilan terjadwal';
      case 'monthly':
        return 'Cicilan bulanan';
      case 'batch_lump':
        return 'Lump sum';
      case 'per_session':
        return 'Per sesi';
      default:
        return method;
    }
  }
}

class _ScheduleRow extends StatelessWidget {
  final PublicSchedule schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    String fmtDate = schedule.scheduledAt;
    String fmtTime = '';
    try {
      final dt = DateTime.parse(schedule.scheduledAt);
      fmtDate = DateFormat('d MMM yyyy', 'id_ID').format(dt);
      fmtTime = DateFormat('HH:mm', 'id_ID').format(dt);
    } catch (_) {}

    final duration = schedule.durationMinutes > 0
        ? '${schedule.durationMinutes} menit'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s8),
      padding: const EdgeInsets.all(AppDimensions.s12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.r999),
            ),
          ),
          const SizedBox(width: AppDimensions.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.moduleTitle, style: AppTextStyles.labelM),
                const SizedBox(height: 2),
                Text(
                  [fmtDate, if (fmtTime.isNotEmpty) fmtTime, if (duration.isNotEmpty) duration].join(' · '),
                  style: AppTextStyles.bodyXS,
                ),
              ],
            ),
          ),
          if (schedule.roomName.isNotEmpty)
            Text(schedule.roomName, style: AppTextStyles.bodyXS),
        ],
      ),
    );
  }
}

// ─── Fasilitator Section ──────────────────────────────────────────────────────

class _FasilitatorSection extends StatelessWidget {
  final List<PublicFacilitator> facilitators;
  final double hPad;

  const _FasilitatorSection({required this.facilitators, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'fasilitator-title',
            child: Text('Fasilitator', style: AppTextStyles.h2),
          ),
          const SizedBox(height: AppDimensions.s32),
          Wrap(
            spacing: AppDimensions.s24,
            runSpacing: AppDimensions.s24,
            children: facilitators.map((f) => _FasilitatorCard(f: f)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FasilitatorCard extends StatelessWidget {
  final PublicFacilitator f;

  const _FasilitatorCard({required this.f});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenW = MediaQuery.of(context).size.width;
    final hPad = Responsive.sectionPaddingH(context);
    final available = screenW - hPad * 2;
    final cardW = isMobile ? available : (available / 2 - AppDimensions.s12).clamp(280.0, 400.0);

    return Container(
      width: cardW,
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.bgSurface,
            backgroundImage: f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
            child: f.photoUrl == null
                ? Text(
                    f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                    style: AppTextStyles.h3.copyWith(color: AppColors.brandPurple),
                  )
                : null,
          ),
          const SizedBox(width: AppDimensions.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, style: AppTextStyles.h4),
                const SizedBox(height: 2),
                Text(f.level, style: AppTextStyles.bodyS),
                const SizedBox(height: AppDimensions.s8),
                Text(
                  f.bio,
                  style: AppTextStyles.bodyXS,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Testimoni Section ────────────────────────────────────────────────────────

class _TestimoniSection extends StatelessWidget {
  final List<PublicTestimonial> testimonials;
  final double hPad;

  const _TestimoniSection({required this.testimonials, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'testimoni-title',
            child: Text('Testimoni Alumni', style: AppTextStyles.h2),
          ),
          const SizedBox(height: AppDimensions.s32),
          Wrap(
            spacing: AppDimensions.s24,
            runSpacing: AppDimensions.s24,
            children: testimonials
                .asMap()
                .entries
                .map((e) => _TestimonialCard(t: e.value, index: e.key))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final PublicTestimonial t;
  final int index;

  const _TestimonialCard({required this.t, required this.index});

  String _fmtDate(String raw) {
    try {
      return DateFormat('MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenW = MediaQuery.of(context).size.width;
    final hPad = Responsive.sectionPaddingH(context);
    final available = screenW - hPad * 2;
    final crossCount = isMobile ? 1 : (Responsive.isTablet(context) ? 2 : 3);
    final cardW = crossCount == 1
        ? available
        : (available - AppDimensions.s24 * (crossCount - 1)) / crossCount;

    return Container(
      width: cardW,
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(5, (i) {
              final full = i < t.rating.floor();
              final half = !full && (t.rating - t.rating.floor()) >= 0.5 && i == t.rating.floor();
              return Icon(
                half ? Icons.star_half_rounded : Icons.star_rounded,
                size: 16,
                color: full || half ? AppColors.brandGold : AppColors.border,
              );
            }),
          ),
          const SizedBox(height: AppDimensions.s12),
          // Quote
          Text(
            '"${t.message}"',
            style: AppTextStyles.bodyM.copyWith(fontStyle: FontStyle.italic),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.s16),
          // Name + info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.bgSurface,
                backgroundImage: t.photoUrl != null ? NetworkImage(t.photoUrl!) : null,
                child: t.photoUrl == null
                    ? Text(
                        t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                        style: AppTextStyles.labelS.copyWith(
                          color: AppColors.brandPurple,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppDimensions.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: AppTextStyles.labelM),
                    Text(
                      '${t.courseTypeName} · ${_fmtDate(t.date)}',
                      style: AppTextStyles.bodyXS,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ─── FAQ Section ──────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final List<PublicFaq> faqs;
  final double hPad;

  const _FaqSection({required this.faqs, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'faq-title',
            child: Text('FAQ', style: AppTextStyles.h2),
          ),
          const SizedBox(height: AppDimensions.s24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: faqs
                  .asMap()
                  .entries
                  .map((e) => _FaqItem(faq: e.value, index: e.key))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final PublicFaq faq;
  final int index;

  const _FaqItem({required this.faq, required this.index});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(
          color: _expanded ? AppColors.brandPurple.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(widget.faq.question, style: AppTextStyles.labelM),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.brandPurple,
            ),
          ),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s20,
            vertical: AppDimensions.s8,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.s20,
                0,
                AppDimensions.s20,
                AppDimensions.s20,
              ),
              child: Text(widget.faq.answer, style: AppTextStyles.bodyM),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (widget.index * 60).ms, duration: 400.ms);
  }
}
