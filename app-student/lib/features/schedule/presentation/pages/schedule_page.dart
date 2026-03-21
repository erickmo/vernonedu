import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

// ─── DATA ─────────────────────────────────────────────────────────────────────

class _ScheduleItem {
  final String id;
  final String courseName;
  final String moduleTitle;
  final String startTime;
  final String endTime;
  final String date;
  final String day;
  final bool isOnline;
  final String location;
  final String status; // hari_ini | akan_datang | selesai
  final String facilitator;

  const _ScheduleItem({
    required this.id,
    required this.courseName,
    required this.moduleTitle,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.day,
    required this.isOnline,
    required this.location,
    required this.status,
    required this.facilitator,
  });
}

final _mockSchedule = [
  const _ScheduleItem(
    id: '1', courseName: 'Digital Marketing Dasar',
    moduleTitle: 'Modul 3: Strategi Media Sosial',
    startTime: '09.00', endTime: '11.00', date: '20 Mar', day: 'Kamis',
    isOnline: true, location: 'Zoom Meeting', status: 'hari_ini', facilitator: 'Budi Santoso',
  ),
  const _ScheduleItem(
    id: '2', courseName: 'UI/UX Design Fundamentals',
    moduleTitle: 'Modul 1: Pengenalan Design Thinking',
    startTime: '13.00', endTime: '16.00', date: '20 Mar', day: 'Kamis',
    isOnline: false, location: 'Ruang A - Lantai 2', status: 'hari_ini', facilitator: 'Siti Rahayu',
  ),
  const _ScheduleItem(
    id: '3', courseName: 'Digital Marketing Dasar',
    moduleTitle: 'Modul 4: SEO & SEM Dasar',
    startTime: '09.00', endTime: '11.00', date: '21 Mar', day: 'Jumat',
    isOnline: true, location: 'Google Meet', status: 'akan_datang', facilitator: 'Budi Santoso',
  ),
  const _ScheduleItem(
    id: '4', courseName: 'Content Creator Pro',
    moduleTitle: 'Modul 2: Video Editing Dasar',
    startTime: '13.00', endTime: '15.00', date: '22 Mar', day: 'Sabtu',
    isOnline: false, location: 'Studio Kreatif - Lt. 3', status: 'akan_datang', facilitator: 'Rina Wulandari',
  ),
  const _ScheduleItem(
    id: '5', courseName: 'UI/UX Design Fundamentals',
    moduleTitle: 'Modul 2: Wireframing dengan Figma',
    startTime: '09.00', endTime: '12.00', date: '25 Mar', day: 'Selasa',
    isOnline: false, location: 'Lab Komputer', status: 'akan_datang', facilitator: 'Siti Rahayu',
  ),
  const _ScheduleItem(
    id: '6', courseName: 'Digital Marketing Dasar',
    moduleTitle: 'Modul 1: Pengenalan Digital Marketing',
    startTime: '09.00', endTime: '11.00', date: '15 Mar', day: 'Sabtu',
    isOnline: true, location: 'Zoom Meeting', status: 'selesai', facilitator: 'Budi Santoso',
  ),
  const _ScheduleItem(
    id: '7', courseName: 'Digital Marketing Dasar',
    moduleTitle: 'Modul 2: Facebook Ads',
    startTime: '09.00', endTime: '11.00', date: '17 Mar', day: 'Senin',
    isOnline: true, location: 'Zoom Meeting', status: 'selesai', facilitator: 'Budi Santoso',
  ),
];

// ─── PAGE ─────────────────────────────────────────────────────────────────────

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int _filterIndex = 0;
  static const _filters = ['Semua', 'Hari Ini', 'Akan Datang', 'Selesai'];

  List<_ScheduleItem> get _filteredSchedule {
    switch (_filterIndex) {
      case 1: return _mockSchedule.where((s) => s.status == 'hari_ini').toList();
      case 2: return _mockSchedule.where((s) => s.status == 'akan_datang').toList();
      case 3: return _mockSchedule.where((s) => s.status == 'selesai').toList();
      default: return _mockSchedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildFilterChips()),
          _filteredSchedule.isEmpty
              ? const SliverFillRemaining(child: _EmptySchedule())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ScheduleCard(item: _filteredSchedule[i]),
                    childCount: _filteredSchedule.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) => SliverAppBar(
        pinned: true,
        backgroundColor: AppColors.primary,
        title: const Text(AppStrings.scheduleTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        ),
      );

  Widget _buildFilterChips() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.pagePadding,
          vertical: AppDimensions.sm,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              _filters.length,
              (i) => Padding(
                padding: const EdgeInsets.only(right: AppDimensions.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.xs + 2),
                    decoration: BoxDecoration(
                      color: _filterIndex == i ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _filterIndex == i ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ─── WIDGETS ──────────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final _ScheduleItem item;
  const _ScheduleCard({required this.item});

  Color get _statusColor {
    switch (item.status) {
      case 'hari_ini': return AppColors.primary;
      case 'akan_datang': return AppColors.accent;
      case 'selesai': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case 'hari_ini': return 'Hari Ini';
      case 'akan_datang': return 'Akan Datang';
      case 'selesai': return 'Selesai';
      default: return '';
    }
  }

  Color get _statusBg {
    switch (item.status) {
      case 'hari_ini': return AppColors.primarySurface;
      case 'akan_datang': return AppColors.accentSurface;
      case 'selesai': return AppColors.successSurface;
      default: return AppColors.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.pagePadding,
        AppDimensions.sm,
        AppDimensions.pagePadding,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: item.status == 'hari_ini'
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.divider),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
              ),
            ),
            const Spacer(),
            Text(
              '${item.day}, ${item.date}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _buildBody(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeline(),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: _buildContent(context)),
          ],
        ),
      );

  Widget _buildTimeline() => Column(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Column(
              children: [
                Text(
                  item.startTime,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _statusColor),
                ),
                Container(width: 1, height: 12, color: _statusColor.withValues(alpha: 0.3)),
                Text(
                  item.endTime,
                  style: TextStyle(fontSize: 11, color: _statusColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildContent(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.courseName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            item.moduleTitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.sm),
          _buildInfoRow(
            icon: item.isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
            label: item.location,
            color: item.isOnline ? AppColors.accent : AppColors.success,
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: item.facilitator,
            color: AppColors.textSecondary,
          ),
          if (item.status == 'hari_ini') ...[
            const SizedBox(height: AppDimensions.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Gabung Sekarang', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _buildInfoRow({required IconData icon, required String label, required Color color}) => Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: const Icon(Icons.event_busy_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.md),
          const Text(
            AppStrings.noSchedule,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.xs),
          const Text(
            'Tidak ada jadwal pada filter ini',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
