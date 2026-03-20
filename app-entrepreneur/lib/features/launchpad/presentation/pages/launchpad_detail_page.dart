import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/launchpad_step_card.dart';

/// Detail page untuk proses launching bisnis — 8 tahapan.
class LaunchpadDetailPage extends StatelessWidget {
  final String businessId;

  const LaunchpadDetailPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    // TODO: load from Cubit based on businessId
    const businessName = 'Bisnis 001';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildHeader(businessName),
          const SizedBox(height: AppDimensions.spacingXS),
          _buildProgressSummary(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildSteps(context),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/launchpad'),
          child: Text(
            'Business Launchpad',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.textMuted),
        ),
        Text(
          'Bisnis 001',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(Icons.rocket_launch_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Selesaikan semua tahapan untuk meluncurkan bisnis kamu',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch Progress',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2 dari 8 tahapan selesai',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: const LinearProgressIndicator(
                    value: 0.25,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Text(
            '25%',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    const steps = [
      LaunchpadStepInfo(
        key: 'business-profile',
        title: 'Business Profile',
        description: 'Nama bisnis resmi, logo, deskripsi, visi & misi, tagline',
        icon: Icons.storefront_rounded,
        color: Color(0xFF4D2975),
        status: StepStatus.completed,
        checklist: [
          'Tentukan nama bisnis resmi',
          'Buat logo atau identitas visual',
          'Tulis deskripsi bisnis (elevator pitch)',
          'Definisikan visi & misi',
          'Buat tagline yang memorable',
        ],
      ),
      LaunchpadStepInfo(
        key: 'key-partnerships',
        title: 'Key Partnerships',
        description: 'Identifikasi dan dapatkan partner strategis untuk bisnis kamu',
        icon: Icons.handshake_rounded,
        color: Color(0xFF0168FA),
        status: StepStatus.completed,
        checklist: [
          'List semua partner potensial (supplier, distributor, dll)',
          'Riset profil dan kontak masing-masing partner',
          'Siapkan proposal kerjasama',
          'Hubungi dan presentasi ke calon partner',
          'Negosiasi terms & conditions',
          'Finalisasi dan tandatangani kesepakatan',
        ],
      ),
      LaunchpadStepInfo(
        key: 'key-activities',
        title: 'Key Activities',
        description: 'Susun aktivitas utama bisnis beserta SOP pelaksanaannya',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF10B759),
        status: StepStatus.inProgress,
        checklist: [
          'List semua aktivitas utama yang harus dijalankan',
          'Tentukan PIC (person in charge) per aktivitas',
          'Identifikasi tools/resources yang dibutuhkan',
          'Tentukan frekuensi pelaksanaan (harian/mingguan/bulanan)',
          'Buat SOP singkat per aktivitas',
          'Setup tracking/monitoring sistem',
        ],
      ),
      LaunchpadStepInfo(
        key: 'key-resources',
        title: 'Key Resources',
        description: 'Identifikasi dan akuisisi sumber daya yang dibutuhkan',
        icon: Icons.inventory_2_rounded,
        color: Color(0xFFFF6F00),
        status: StepStatus.notStarted,
        checklist: [
          'List semua resources yang dibutuhkan (manusia, teknologi, modal, aset)',
          'Estimasi biaya per resource',
          'Identifikasi sumber akuisisi (beli, sewa, rekrut, dll)',
          'Buat timeline akuisisi per resource',
          'Mulai proses akuisisi sesuai prioritas',
          'Verifikasi resources sudah tersedia dan siap digunakan',
        ],
      ),
      LaunchpadStepInfo(
        key: 'channels',
        title: 'Channels',
        description: 'Setup channel distribusi dan komunikasi ke customer',
        icon: Icons.share_rounded,
        color: Color(0xFF1DA1F2),
        status: StepStatus.notStarted,
        checklist: [
          'Identifikasi channel distribusi (online store, marketplace, fisik)',
          'Identifikasi channel komunikasi (social media, email, WhatsApp)',
          'Buat akun dan setup setiap channel',
          'Siapkan content/materi per channel',
          'Test alur customer journey di setiap channel',
          'Tentukan KPI per channel',
        ],
      ),
      LaunchpadStepInfo(
        key: 'product-service',
        title: 'Product / Service Setup',
        description: 'Detail produk atau jasa, pricing, dan katalog awal',
        icon: Icons.category_rounded,
        color: Color(0xFFDC3545),
        status: StepStatus.notStarted,
        checklist: [
          'Finalisasi detail produk/jasa (nama, spesifikasi, ukuran)',
          'Tentukan pricing strategy dan harga jual',
          'Siapkan packaging atau presentation',
          'Buat katalog produk/jasa',
          'Siapkan stok awal atau kapasitas layanan',
          'Test quality produk/jasa sebelum launch',
        ],
      ),
      LaunchpadStepInfo(
        key: 'launch-plan',
        title: 'Launch Plan',
        description: 'Timeline peluncuran, milestone, dan final checklist',
        icon: Icons.event_note_rounded,
        color: Color(0xFF6F42C1),
        status: StepStatus.notStarted,
        checklist: [
          'Tentukan tanggal target launch',
          'Buat timeline mundur (T-30, T-14, T-7, T-1)',
          'Set milestone per minggu sebelum launch',
          'Siapkan launch campaign (teaser, countdown)',
          'Koordinasi dengan semua partner dan tim',
          'Dry run / simulasi operasional sebelum launch',
          'Siapkan contingency plan',
        ],
      ),
      LaunchpadStepInfo(
        key: 'go-live',
        title: 'Go Live',
        description: 'Review final dan luncurkan bisnis kamu!',
        icon: Icons.rocket_rounded,
        color: Color(0xFF10B759),
        status: StepStatus.notStarted,
        checklist: [
          'Review semua tahapan sebelumnya sudah complete',
          'Final check semua channel aktif',
          'Final check stok/kapasitas siap',
          'Final check tim siap operasional',
          'Publish dan umumkan ke publik',
          'Monitor feedback customer pertama',
        ],
      ),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        return LaunchpadStepCard(
          step: entry.value,
          stepNumber: entry.key + 1,
          isLast: entry.key == steps.length - 1,
          onOpen: () {
            context.go('/launchpad/$businessId/step/${entry.value.key}');
          },
        );
      }).toList(),
    );
  }
}
