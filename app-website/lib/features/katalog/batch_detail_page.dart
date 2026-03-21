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

/// Batch detail page — /katalog/:courseId/batch/:batchId
class BatchDetailPage extends StatefulWidget {
  final String courseId;
  final String batchId;

  const BatchDetailPage({
    super.key,
    required this.courseId,
    required this.batchId,
  });

  @override
  State<BatchDetailPage> createState() => _BatchDetailPageState();
}

class _BatchDetailPageState extends State<BatchDetailPage> {
  final _service = PublicCourseService();
  PublicBatch? _batch;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final b = await _service.fetchBatchDetail(widget.batchId);
      if (mounted) setState(() { _batch = b; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() { _error = 'Gagal memuat detail kelas.'; _loading = false; });
      }
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 120),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: AppDimensions.s16),
                  Text(_error!, style: AppTextStyles.bodyL),
                  const SizedBox(height: AppDimensions.s24),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (_batch != null)
            _BatchDetailBody(
              batch: _batch!,
              courseId: widget.courseId,
            )
          else
            const SizedBox.shrink(),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ─── Batch Detail Body ────────────────────────────────────────────────────────

class _BatchDetailBody extends StatelessWidget {
  final PublicBatch batch;
  final String courseId;

  const _BatchDetailBody({required this.batch, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile
        ? AppDimensions.s24
        : Responsive.sectionPaddingH(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero section
        _BatchHeroSection(
          batch: batch,
          courseId: courseId,
          hPad: hPad,
          isMobile: isMobile,
        ),

        // 2. Enrollment status section
        _EnrollmentStatusSection(batch: batch, hPad: hPad),

        // 3. Schedule section
        if (batch.schedules.isNotEmpty)
          _ScheduleSection(batch: batch, hPad: hPad),

        // 4. CTA section
        _CtaSection(batch: batch, hPad: hPad),
      ],
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _BatchHeroSection extends StatelessWidget {
  final PublicBatch batch;
  final String courseId;
  final double hPad;
  final bool isMobile;

  const _BatchHeroSection({
    required this.batch,
    required this.courseId,
    required this.hPad,
    required this.isMobile,
  });

  static String _fmtDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _fmtPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

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
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('${AppRouter.katalog}/$courseId'),
                  child: Text(
                    batch.courseName,
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
              Text('Detail Kelas', style: AppTextStyles.bodyS),
            ],
          ),
          const SizedBox(height: AppDimensions.s24),

          // Course type badge
          if (batch.courseType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimensions.r999),
              ),
              child: Text(
                batch.courseType,
                style: AppTextStyles.labelS.copyWith(color: Colors.white),
              ),
            ),
          const SizedBox(height: AppDimensions.s16),

          // Course name
          Text(
            batch.courseName,
            style: isMobile ? AppTextStyles.displayM : AppTextStyles.displayL,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppDimensions.s24),

          // Metadata grid
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildMetaItems(batch),
                )
              : Wrap(
                  spacing: AppDimensions.s32,
                  runSpacing: AppDimensions.s16,
                  children: _buildMetaItems(batch),
                ),
          const SizedBox(height: AppDimensions.s32),

          // CTA
          if (!batch.isFull)
            GradientButton(
              label: 'Daftar Sekarang — ${_fmtPrice(batch.price)}',
              onTap: () => context.go('${AppRouter.daftar}/${batch.id}'),
              height: AppDimensions.btnHeightL,
              horizontalPadding: 32,
              icon: Icons.arrow_forward_rounded,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
          else
            Container(
              padding: const EdgeInsets.all(AppDimensions.s20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(AppDimensions.r12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.textMuted),
                  const SizedBox(width: AppDimensions.s12),
                  Text('Kelas ini sudah penuh.', style: AppTextStyles.bodyM),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMetaItems(PublicBatch b) {
    return [
      _MetaItem(
        icon: Icons.calendar_today_outlined,
        label: 'Mulai',
        value: _fmtDate(b.startDate),
      ),
      if (b.endDate != null)
        _MetaItem(
          icon: Icons.event_outlined,
          label: 'Selesai',
          value: _fmtDate(b.endDate!),
        ),
      if (b.facilitatorName.isNotEmpty)
        _MetaItem(
          icon: Icons.person_outline,
          label: 'Fasilitator',
          value: b.facilitatorName,
        ),
      if (b.location.isNotEmpty)
        _MetaItem(
          icon: Icons.location_on_outlined,
          label: 'Lokasi',
          value: b.location,
        ),
      _MetaItem(
        icon: Icons.group_outlined,
        label: 'Peserta',
        value: '${b.enrolledCount}/${b.maxStudents}',
      ),
      _MetaItem(
        icon: Icons.payments_outlined,
        label: 'Pembayaran',
        value: _paymentLabel(b.paymentMethod),
      ),
    ];
  }

  static String _paymentLabel(String method) {
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

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconS, color: AppColors.brandPurple),
        const SizedBox(width: AppDimensions.s8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodyXS),
            Text(value, style: AppTextStyles.labelM),
          ],
        ),
      ],
    );
  }
}

// ─── Enrollment Status Section ────────────────────────────────────────────────

class _EnrollmentStatusSection extends StatelessWidget {
  final PublicBatch batch;
  final double hPad;

  const _EnrollmentStatusSection({required this.batch, required this.hPad});

  @override
  Widget build(BuildContext context) {
    final fraction = batch.maxStudents > 0
        ? batch.enrolledCount / batch.maxStudents
        : 0.0;
    final pct = (fraction * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s48),
      color: AppColors.bgPrimary,
      child: ScrollAnimateWidget(
        uniqueKey: 'enrollment-status',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Pendaftaran', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.s24),
            Container(
              padding: const EdgeInsets.all(AppDimensions.s24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDimensions.r16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Peserta terdaftar', style: AppTextStyles.bodyS),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${batch.enrolledCount}',
                                  style: AppTextStyles.h2.copyWith(
                                    color: AppColors.brandPurple,
                                  ),
                                ),
                                TextSpan(
                                  text: '/${batch.maxStudents} orang',
                                  style: AppTextStyles.bodyM,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: batch.isFull
                                ? AppColors.textMuted
                                : AppColors.brandPurple,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$pct%',
                            style: AppTextStyles.labelM.copyWith(
                              color: batch.isFull
                                  ? AppColors.textMuted
                                  : AppColors.brandPurple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.r999),
                    child: LinearProgressIndicator(
                      value: fraction.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        batch.isFull
                            ? AppColors.textMuted
                            : AppColors.brandPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s12),
                  Text(
                    batch.isFull
                        ? 'Kuota kelas ini sudah penuh.'
                        : '${batch.availableSlots} slot tersisa. Daftar sekarang sebelum penuh!',
                    style: AppTextStyles.bodyS.copyWith(
                      color: batch.isFull ? AppColors.textMuted : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Section ─────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final PublicBatch batch;
  final double hPad;

  const _ScheduleSection({required this.batch, required this.hPad});

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
            uniqueKey: 'schedule-title',
            child: Text('Jadwal Pertemuan', style: AppTextStyles.h2),
          ),
          const SizedBox(height: AppDimensions.s8),
          Text(
            '${batch.schedules.length} sesi pembelajaran',
            style: AppTextStyles.bodyS,
          ),
          const SizedBox(height: AppDimensions.s32),
          ...batch.schedules.asMap().entries.map(
                (e) => _ScheduleCard(schedule: e.value, index: e.key),
              ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final PublicSchedule schedule;
  final int index;

  const _ScheduleCard({required this.schedule, required this.index});

  @override
  Widget build(BuildContext context) {
    String fmtDate = '';
    String fmtTime = '';
    try {
      final dt = DateTime.parse(schedule.scheduledAt);
      fmtDate = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(dt);
      fmtTime = DateFormat('HH:mm', 'id_ID').format(dt);
    } catch (_) {
      fmtDate = schedule.scheduledAt;
    }

    final duration = schedule.durationMinutes > 0
        ? '${schedule.durationMinutes} menit'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s12),
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.r8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTextStyles.labelM.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.moduleTitle, style: AppTextStyles.labelM),
                const SizedBox(height: AppDimensions.s4),
                Wrap(
                  spacing: AppDimensions.s12,
                  runSpacing: 4,
                  children: [
                    if (fmtDate.isNotEmpty)
                      _ScheduleMeta(
                        icon: Icons.calendar_today_outlined,
                        text: fmtDate,
                      ),
                    if (fmtTime.isNotEmpty)
                      _ScheduleMeta(
                        icon: Icons.access_time_rounded,
                        text: fmtTime,
                      ),
                    if (duration.isNotEmpty)
                      _ScheduleMeta(
                        icon: Icons.timer_outlined,
                        text: duration,
                      ),
                    if (schedule.roomName.isNotEmpty)
                      _ScheduleMeta(
                        icon: Icons.meeting_room_outlined,
                        text: schedule.roomName,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 350.ms)
        .slideX(begin: 0.1, end: 0);
  }
}

class _ScheduleMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScheduleMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.bodyXS),
      ],
    );
  }
}

// ─── CTA Section ─────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final PublicBatch batch;
  final double hPad;

  const _CtaSection({required this.batch, required this.hPad});

  static String _fmtPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      decoration: const BoxDecoration(gradient: AppColors.ctaGradient),
      child: Column(
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'cta-batch',
            child: Column(
              children: [
                Text(
                  batch.isFull ? 'Kuota Kelas Penuh' : 'Siap Bergabung?',
                  style: isMobile
                      ? AppTextStyles.displayM.copyWith(color: Colors.white)
                      : AppTextStyles.h1.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.s16),
                if (!batch.isFull) ...[
                  Text(
                    '${batch.availableSlots} slot tersisa dari ${batch.maxStudents} tempat',
                    style: AppTextStyles.bodyL.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.s8),
                  Text(
                    _fmtPrice(batch.price),
                    style: AppTextStyles.h2.copyWith(color: AppColors.brandGold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GradientButton(
                    label: 'Daftar Sekarang',
                    onTap: () => context.go('${AppRouter.daftar}/${batch.id}'),
                    height: AppDimensions.btnHeightXL,
                    horizontalPadding: 48,
                    gradient: AppColors.goldGradient,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ] else ...[
                  const SizedBox(height: AppDimensions.s16),
                  Text(
                    'Kelas ini sudah tidak tersedia. Lihat jadwal batch berikutnya.',
                    style: AppTextStyles.bodyL.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GradientButton(
                    label: 'Lihat Kelas Lainnya',
                    onTap: () => context.go(AppRouter.katalog),
                    height: AppDimensions.btnHeightL,
                    horizontalPadding: 32,
                    gradient: AppColors.primaryGradient,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
