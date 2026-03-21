import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';
import '../../core/widgets/scroll_animate_widget.dart';
import '../../core/widgets/section_header.dart';
import 'widgets/course_card.dart';

/// Page for /program/:type — Program Karir, Reguler, Privat, Sertifikasi.
class ProgramPage extends StatefulWidget {
  final String programType; // karir | reguler | privat | sertifikasi

  const ProgramPage({super.key, required this.programType});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  late final Future<List<CourseData>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _fetchCourses();
  }

  Future<List<CourseData>> _fetchCourses() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:8081/api/v1',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final res = await dio.get<Map<String, dynamic>>(
        '/public/courses',
        queryParameters: {'type': widget.programType, 'limit': 6},
      );
      final list = (res.data?['data'] as List<dynamic>?) ?? [];
      return list.map((e) => CourseData.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  _ProgramMeta get _meta => switch (widget.programType) {
        'karir' => const _ProgramMeta(
            badge: '🚀 Program Karir',
            title: 'Belajar, Magang,\nBerkarir',
            subtitle:
                'Program komprehensif dari pembelajaran intensif, magang terstruktur, hingga masuk jaringan Talent Pool.',
            gradientColors: [Color(0xFF3D2068), Color(0xFF5B3A9A), Color(0xFF7C68EE)],
            ctaLabel: 'Lihat Kursus',
            accentColor: AppColors.brandPurple,
          ),
        'reguler' => const _ProgramMeta(
            badge: '📖 Kursus Reguler',
            title: 'Kuasai Skill Baru dengan\nJadwal Fleksibel',
            subtitle:
                'Belajar dengan instruktur berpengalaman dalam kelas kecil yang interaktif.',
            gradientColors: [Color(0xFF1A2850), Color(0xFF2B4090), Color(0xFF3B90D9)],
            ctaLabel: 'Jelajahi Kursus',
            accentColor: AppColors.brandBlue,
          ),
        'privat' => const _ProgramMeta(
            badge: '🎯 Kursus Privat',
            title: 'Belajar 1-on-1\nSesuai Kebutuhanmu',
            subtitle:
                'Instruktur dedicated, kurikulum custom, jadwal sepenuhnya di tanganmu.',
            gradientColors: [Color(0xFF1B3A2D), Color(0xFF1E6E50), Color(0xFF00B894)],
            ctaLabel: 'Konsultasi Gratis',
            accentColor: AppColors.brandGreen,
          ),
        _ => const _ProgramMeta(
            badge: '🏆 Sertifikasi',
            title: 'Buktikan Kompetensimu\ndengan Sertifikat Resmi',
            subtitle:
                'Sertifikat diakui industri, verifikasi QR online, valid seumur hidup.',
            gradientColors: [Color(0xFF3D2800), Color(0xFF8B6000), Color(0xFFF59E0B)],
            ctaLabel: 'Ikut Sertifikasi',
            accentColor: AppColors.brandGold,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final padH = Responsive.sectionPaddingH(context);
    final padV = Responsive.sectionPaddingV(context);
    final meta = _meta;

    return WebScaffold(
      body: Column(
        children: [
          _ProgramHero(meta: meta, padH: padH, padV: padV),
          _ProgramBenefits(programType: widget.programType, padH: padH, padV: padV),
          _ProgramHowItWorks(programType: widget.programType, padH: padH, padV: padV),
          _ProgramCourses(future: _coursesFuture, padH: padH, padV: padV),
          _ProgramFaq(programType: widget.programType, padH: padH, padV: padV),
          _ProgramCta(meta: meta, padH: padH, padV: padV),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ── Meta data ──────────────────────────────────────────────────────────────

class _ProgramMeta {
  final String badge;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String ctaLabel;
  final Color accentColor;

  const _ProgramMeta({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.ctaLabel,
    required this.accentColor,
  });
}

// ── Hero ───────────────────────────────────────────────────────────────────

class _ProgramHero extends StatelessWidget {
  final _ProgramMeta meta;
  final double padH;
  final double padV;

  const _ProgramHero({required this.meta, required this.padH, required this.padV});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: meta.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          SectionHeader(
            badge: meta.badge,
            title: meta.title,
            subtitle: meta.subtitle,
            isDark: true,
          ),
          const SizedBox(height: AppDimensions.s40),
          GradientButton(
            label: meta.ctaLabel,
            onTap: () {},
            height: 52,
            horizontalPadding: 32,
            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0D8F5)]),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ── Benefits ───────────────────────────────────────────────────────────────

class _ProgramBenefits extends StatelessWidget {
  final String programType;
  final double padH;
  final double padV;

  const _ProgramBenefits({
    required this.programType,
    required this.padH,
    required this.padV,
  });

  List<_BItem> get _items => switch (programType) {
        'karir' => const [
            _BItem(Icons.school_outlined, 'Kurikulum Industri',
                'Materi dirancang bersama praktisi industri aktif.', AppColors.brandPurple),
            _BItem(Icons.business_center_outlined, 'Magang Terstruktur',
                'Program magang 3 bulan di perusahaan mitra.', AppColors.brandBlue),
            _BItem(Icons.hub_outlined, 'Talent Pool Network',
                'Jaringan eksklusif yang direkomendasikan ke ratusan perusahaan.', AppColors.brandGreen),
            _BItem(Icons.verified_outlined, 'Sertifikasi Kompetensi',
                'Sertifikat resmi diakui industri.', AppColors.brandGold),
          ],
        'reguler' => const [
            _BItem(Icons.person_pin_outlined, 'Instruktur Berpengalaman',
                'Praktisi industri aktif dengan pengalaman min. 5 tahun.', AppColors.brandPurple),
            _BItem(Icons.schedule_outlined, 'Jadwal Fleksibel',
                'Kelas pagi, siang, malam — hari kerja maupun akhir pekan.', AppColors.brandBlue),
            _BItem(Icons.group_outlined, 'Kelas Kecil',
                'Maks 15 peserta per kelas, perhatian penuh dari instruktur.', AppColors.brandGreen),
            _BItem(Icons.card_membership_outlined, 'Sertifikat Peserta',
                'Sertifikat resmi yang dapat diverifikasi online.', AppColors.brandGold),
          ],
        'privat' => const [
            _BItem(Icons.schedule_outlined, 'Jadwal Fleksibel',
                'Atur jadwal sepenuhnya sesuai kesibukan Anda.', AppColors.brandGreen),
            _BItem(Icons.tune_outlined, 'Kurikulum Custom',
                'Materi disesuaikan dengan level dan target Anda.', AppColors.brandBlue),
            _BItem(Icons.support_agent_outlined, 'Instruktur Dedicated',
                'Satu instruktur, satu peserta — fokus penuh.', AppColors.brandPurple),
            _BItem(Icons.receipt_outlined, 'Bayar Per Sesi',
                'Tidak ada biaya pendaftaran, bayar sesi yang dijalani.', AppColors.brandOrange),
          ],
        _ => const [
            _BItem(Icons.handshake_outlined, 'Diakui Industri',
                'Sertifikat diakui oleh 50+ perusahaan mitra.', AppColors.brandGold),
            _BItem(Icons.qr_code_2_rounded, 'QR Verification',
                'Setiap sertifikat memiliki QR code verifikasi online.', AppColors.brandBlue),
            _BItem(Icons.all_inclusive_rounded, 'Valid Seumur Hidup',
                'Tidak ada masa kedaluwarsa.', AppColors.brandGreen),
            _BItem(Icons.refresh_rounded, 'Gratis Ujian Ulang',
                'Boleh mengulang ujian tanpa biaya tambahan.', AppColors.brandPurple),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'prog-benefits-$programType',
        child: Column(
          children: [
            const SectionHeader(badge: '✨ Keunggulan', title: 'Mengapa Memilih\nProgram Ini?'),
            const SizedBox(height: AppDimensions.s48),
            LayoutBuilder(builder: (ctx, c) {
              final cols = c.maxWidth > 800 ? 4 : 2;
              final sp = AppDimensions.s20;
              final w = (c.maxWidth - (cols - 1) * sp) / cols;
              return Wrap(
                spacing: sp,
                runSpacing: sp,
                children: _items.asMap().entries.map((e) {
                  return SizedBox(width: w, child: _BCard(item: e.value, idx: e.key));
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BItem {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _BItem(this.icon, this.title, this.desc, this.color);
}

class _BCard extends StatelessWidget {
  final _BItem item;
  final int idx;

  const _BCard({required this.item, required this.idx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(color: item.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: AppDimensions.s16),
          Text(item.title, style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.s8),
          Text(item.desc, style: AppTextStyles.bodyS),
        ],
      ),
    ).animate(delay: (idx * 80).ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0);
  }
}

// ── How It Works ───────────────────────────────────────────────────────────

class _ProgramHowItWorks extends StatelessWidget {
  final String programType;
  final double padH;
  final double padV;

  const _ProgramHowItWorks({
    required this.programType,
    required this.padH,
    required this.padV,
  });

  List<_SItem> get _steps => switch (programType) {
        'karir' => const [
            _SItem('01', 'Daftar Kursus', 'Pilih Program Karir yang sesuai minat.'),
            _SItem('02', 'Ikuti Pembelajaran', 'Belajar intensif dengan instruktur industri.'),
            _SItem('03', 'Magang 3 Bulan', 'Jalani magang di perusahaan mitra.'),
            _SItem('04', 'Masuk Talent Pool', 'Lulus tes & bergabung ke jaringan karir.'),
          ],
        'reguler' => const [
            _SItem('01', 'Pilih Kursus', 'Telusuri katalog dan temukan kursus yang tepat.'),
            _SItem('02', 'Ikuti Kelas', 'Hadiri kelas tatap muka atau online.'),
            _SItem('03', 'Dapat Sertifikat', 'Terima sertifikat setelah menyelesaikan kursus.'),
          ],
        'privat' => const [
            _SItem('01', 'Konsultasi Kebutuhan', 'Ceritakan tujuan dan jadwal belajarmu.'),
            _SItem('02', 'Matching Instruktur', 'Kami mencarikan instruktur paling cocok.'),
            _SItem('03', 'Mulai Belajar', 'Sesi pertama bisa dimulai dalam 24–48 jam.'),
          ],
        _ => const [
            _SItem('01', 'Daftar', 'Pilih kursus + sertifikasi atau langsung ujian.'),
            _SItem('02', 'Ujian Online', 'Ujian berbasis komputer yang terstandarisasi.'),
            _SItem('03', 'Penilaian', 'Tim asesor menilai dalam 3 hari kerja.'),
            _SItem('04', 'Terima Sertifikat', 'Sertifikat digital langsung diterbitkan.'),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'prog-how-$programType',
        child: Column(
          children: [
            const SectionHeader(badge: '📋 Cara Kerja', title: 'Bagaimana Program\nIni Berjalan?'),
            const SizedBox(height: AppDimensions.s48),
            LayoutBuilder(builder: (ctx, c) {
              final cols = _steps.length > 3 ? (c.maxWidth > 800 ? 4 : 2) : (c.maxWidth > 700 ? 3 : 1);
              final sp = AppDimensions.s24;
              final w = (c.maxWidth - (cols - 1) * sp) / cols;
              return Wrap(
                spacing: sp,
                runSpacing: sp,
                children: _steps.asMap().entries.map((e) {
                  return SizedBox(width: w, child: _SCard(step: e.value, idx: e.key));
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SItem {
  final String num;
  final String title;
  final String desc;

  const _SItem(this.num, this.title, this.desc);
}

class _SCard extends StatelessWidget {
  final _SItem step;
  final int idx;

  const _SCard({required this.step, required this.idx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: Text(step.num,
                style: AppTextStyles.statNumber.copyWith(fontSize: 32, color: Colors.white)),
          ),
          const SizedBox(height: AppDimensions.s12),
          Text(step.title, style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.s8),
          Text(step.desc, style: AppTextStyles.bodyS),
        ],
      ),
    ).animate(delay: (idx * 80).ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0);
  }
}

// ── Courses ────────────────────────────────────────────────────────────────

class _ProgramCourses extends StatelessWidget {
  final Future<List<CourseData>> future;
  final double padH;
  final double padV;

  const _ProgramCourses({required this.future, required this.padH, required this.padV});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'prog-courses',
        child: Column(
          children: [
            const SectionHeader(badge: '📚 Kursus Tersedia', title: 'Pilih Kursus\nTerbaik Untukmu'),
            const SizedBox(height: AppDimensions.s48),
            CoursesGrid(future: future),
          ],
        ),
      ),
    );
  }
}

// ── FAQ ────────────────────────────────────────────────────────────────────

class _ProgramFaq extends StatelessWidget {
  final String programType;
  final double padH;
  final double padV;

  const _ProgramFaq({required this.programType, required this.padH, required this.padV});

  List<_FItem> get _faqs => switch (programType) {
        'karir' => const [
            _FItem('Siapa yang bisa mendaftar?',
                'Terbuka untuk fresh graduate, mahasiswa tingkat akhir, dan profesional yang ingin beralih karir.'),
            _FItem('Berapa lama total durasi?',
                'Total 6–9 bulan: 3 bulan kursus + 3 bulan magang + proses seleksi Talent Pool.'),
            _FItem('Apakah magang dibayar?',
                'Sebagian besar menawarkan uang saku. Kami membantu negosiasi kondisi terbaik.'),
            _FItem('Apa itu Talent Pool?',
                'Jaringan eksklusif profesional terverifikasi yang aktif dicari perusahaan mitra.'),
          ],
        'reguler' => const [
            _FItem('Apakah tersedia online dan offline?',
                'Ya, kedua pilihan tersedia. Kelas online via Zoom dengan kualitas interaksi yang sama.'),
            _FItem('Berapa lama durasi satu kursus?',
                'Rata-rata 4–8 minggu dengan 2–3 sesi per minggu, masing-masing 2 jam.'),
            _FItem('Bisakah pindah jadwal?',
                'Ya, maksimal 2 kali selama kursus, minimal 24 jam sebelum sesi.'),
          ],
        'privat' => const [
            _FItem('Apakah perlu pengalaman sebelumnya?',
                'Tidak perlu. Instruktur menyesuaikan materi dengan level Anda.'),
            _FItem('Bagaimana cara memilih instruktur?',
                'Kami merekomendasikan 2–3 instruktur paling cocok berdasarkan konsultasi.'),
            _FItem('Ada batas minimum sesi?',
                'Tidak ada. Kami merekomendasikan minimal 4 sesi untuk hasil optimal.'),
          ],
        _ => const [
            _FItem('Perbedaan Sertifikat Peserta dan Kompetensi?',
                'Sertifikat Peserta otomatis setelah kursus. Sertifikat Kompetensi melalui ujian terpisah.'),
            _FItem('Bisa ikut ujian tanpa kursus?',
                'Ya. Profesional berpengalaman dapat langsung daftar ujian kompetensi.'),
            _FItem('Berapa kali bisa mengulang ujian?',
                'Tidak ada batas. Setiap ujian ulang sepenuhnya gratis.'),
            _FItem('Apakah sertifikat bisa dicabut?',
                'Dalam kondisi tertentu, sertifikat dapat dicabut melalui proses review multi-level.'),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'prog-faq-$programType',
        child: Column(
          children: [
            const SectionHeader(badge: '❓ FAQ', title: 'Pertanyaan yang\nSering Ditanyakan'),
            const SizedBox(height: AppDimensions.s48),
            Column(
              children: _faqs.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.s12),
                  child: _FaqTile(item: e.value, idx: e.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FItem {
  final String q;
  final String a;

  const _FItem(this.q, this.a);
}

class _FaqTile extends StatefulWidget {
  final _FItem item;
  final int idx;

  const _FaqTile({required this.item, required this.idx});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _open ? AppColors.brandPurple.withValues(alpha: 0.05) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(
          color: _open ? AppColors.brandPurple.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: ExpansionTile(
        onExpansionChanged: (v) => setState(() => _open = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        collapsedIconColor: AppColors.textMuted,
        iconColor: AppColors.brandPurple,
        title: Text(widget.item.q,
            style: AppTextStyles.labelL.copyWith(
              color: _open ? AppColors.textPrimary : AppColors.textSecondary,
            )),
        children: [Text(widget.item.a, style: AppTextStyles.bodyM)],
      ),
    ).animate(delay: (widget.idx * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── CTA Banner ─────────────────────────────────────────────────────────────

class _ProgramCta extends StatelessWidget {
  final _ProgramMeta meta;
  final double padH;
  final double padV;

  const _ProgramCta({required this.meta, required this.padH, required this.padV});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: meta.gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ScrollAnimateWidget(
        uniqueKey: 'prog-cta-${meta.badge}',
        child: Column(
          children: [
            Text('Mulai Sekarang', style: AppTextStyles.displayM.copyWith(color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.s16),
            Text('Bergabunglah dengan ribuan alumni VernonEdu yang telah meraih karir impian mereka.',
                style: AppTextStyles.bodyLOnDark, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.s40),
            Wrap(
              spacing: AppDimensions.s16,
              runSpacing: AppDimensions.s12,
              alignment: WrapAlignment.center,
              children: [
                GradientButton(
                  label: meta.ctaLabel,
                  onTap: () => context.go('/katalog'),
                  height: 56,
                  horizontalPadding: 40,
                  icon: Icons.arrow_forward_rounded,
                  gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0D8F5)]),
                ),
                OutlineButton(
                  label: 'Hubungi Kami',
                  onTap: () => context.go('/hubungi'),
                  height: 56,
                  horizontalPadding: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
