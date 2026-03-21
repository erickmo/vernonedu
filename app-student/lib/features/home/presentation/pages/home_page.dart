import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class _BannerInfo {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;
  const _BannerInfo(this.title, this.subtitle, this.colors, this.icon);
}

class _SchedulePreview {
  final String courseName;
  final String time;
  final String date;
  final bool isToday;
  final bool isOnline;
  const _SchedulePreview(this.courseName, this.time, this.date, this.isToday, this.isOnline);
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────

const _banners = [
  _BannerInfo(
    'Pendaftaran Batch Baru!',
    'Digital Marketing & UI/UX Design\nbuka sekarang, tempat terbatas.',
    AppColors.gradientPrimary,
    Icons.campaign_rounded,
  ),
  _BannerInfo(
    'Webinar Gratis: Entrepreneurship',
    'Sabtu, 22 Maret 2026 · Pukul 09.00 WIB\nDaftar sekarang!',
    AppColors.gradientAccent,
    Icons.live_tv_rounded,
  ),
  _BannerInfo(
    'Raih Sertifikat Kompetensimu',
    'Selesaikan semua modul dan ujian\nuntuk mendapatkan sertifikat resmi.',
    AppColors.gradientSuccess,
    Icons.workspace_premium_rounded,
  ),
];

const _schedules = [
  _SchedulePreview('Digital Marketing Dasar', '09.00 – 11.00 WIB', 'Hari Ini', true, true),
  _SchedulePreview('Teknik SEO & SEM', '13.00 – 15.00 WIB', 'Besok', false, false),
  _SchedulePreview('Content Strategy', '09.00 – 11.00 WIB', 'Rabu, 25 Mar', false, true),
];

// ─── PAGE ────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final name = state is AuthAuthenticated ? state.name : '';
        final initials = state is AuthAuthenticated ? state.initials : '?';
        return CustomScrollView(
          slivers: [
            _buildSliverHeader(context, name, initials),
            SliverToBoxAdapter(child: _buildBannerSlider()),
            SliverToBoxAdapter(child: _buildStatCards()),
            SliverToBoxAdapter(child: _buildQuickAccess(context)),
            SliverToBoxAdapter(child: _buildUpcomingSchedule(context)),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),
          ],
        );
      },
    );
  }

  Widget _buildSliverHeader(BuildContext context, String name, String initials) =>
      SliverAppBar(
        expandedHeight: 100,
        floating: false,
        pinned: true,
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientPrimary,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePadding,
              AppDimensions.xl,
              AppDimensions.pagePadding,
              AppDimensions.md,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(child: _buildGreeting(context, name)),
                  _buildAvatar(initials),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildGreeting(BuildContext context, String name) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${AppStrings.greeting}, ${name.split(' ').first}! 👋',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            AppStrings.homeSubtitle,
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      );

  Widget _buildAvatar(String initials) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      );

  Widget _buildBannerSlider() => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.lg,
          AppDimensions.pagePadding,
          0,
        ),
        child: Column(
          children: [
            SizedBox(
              height: AppDimensions.sliderHeight,
              child: PageView.builder(
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemBuilder: (context, i) => _BannerCard(banner: _banners[i]),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            _buildDotIndicator(),
          ],
        ),
      );

  Widget _buildDotIndicator() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _banners.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _bannerIndex == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _bannerIndex == i ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
          ),
        ),
      );

  Widget _buildStatCards() => const Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.lg,
          AppDimensions.pagePadding,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: AppStrings.activeCourses,
                value: '2',
                icon: Icons.menu_book_rounded,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _StatCard(
                label: AppStrings.completedCourses,
                value: '5',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
              ),
            ),
            SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _StatCard(
                label: AppStrings.totalCertificates,
                value: '3',
                icon: Icons.workspace_premium_outlined,
                color: Color(0xFFE65100),
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickAccess(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.lg,
          AppDimensions.pagePadding,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.quickAccess, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Jadwal\nKelas',
                    color: AppColors.primary,
                    onTap: () => context.go('/schedule'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Daftar\nKelas',
                    color: AppColors.accent,
                    onTap: () => context.go('/course'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Sertifikat\nSaya',
                    color: const Color(0xFFE65100),
                    onTap: () => context.go('/certificate'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _QuickAccessCard(
                    icon: Icons.history_rounded,
                    label: 'Riwayat\nBelajar',
                    color: AppColors.success,
                    onTap: () => context.go('/course'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildUpcomingSchedule(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.lg,
          AppDimensions.pagePadding,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.upcomingSchedule, style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/schedule'),
                  child: const Text(AppStrings.seeAll, style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            ..._schedules.map((s) => _SchedulePreviewCard(schedule: s)),
          ],
        ),
      );
}

// ─── WIDGETS ─────────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final _BannerInfo banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: banner.colors,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                  ),
                  child: const Text(
                    'INFO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  banner.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(banner.icon, size: 60, color: Colors.white.withValues(alpha: 0.25)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchedulePreviewCard extends StatelessWidget {
  final _SchedulePreview schedule;
  const _SchedulePreviewCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: schedule.isToday ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
        ),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          _buildDateBadge(),
          const SizedBox(width: AppDimensions.md),
          Expanded(child: _buildInfo(context)),
          _buildTypeBadge(),
        ],
      ),
    );
  }

  Widget _buildDateBadge() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: schedule.isToday ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: schedule.isToday ? Colors.white : AppColors.textSecondary,
            ),
            Text(
              schedule.date.split(',').first,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: schedule.isToday ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildInfo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.courseName,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            schedule.time,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );

  Widget _buildTypeBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: schedule.isOnline ? AppColors.accentSurface : AppColors.successSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
        child: Text(
          schedule.isOnline ? AppStrings.sessionOnline : AppStrings.sessionOffline,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: schedule.isOnline ? AppColors.accent : AppColors.success,
          ),
        ),
      );
}
