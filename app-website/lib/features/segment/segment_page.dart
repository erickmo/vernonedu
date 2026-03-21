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

/// Page for /untuk/:segment — Universitas, Sekolah, Korporat, Individu.
class SegmentPage extends StatelessWidget {
  final String segment; // universitas | sekolah | korporat | individu

  const SegmentPage({super.key, required this.segment});

  _SegMeta get _meta => switch (segment) {
        'universitas' => const _SegMeta(
            badge: '🎓 Untuk Universitas',
            title: 'Kolaborasi Kurikulum &\nSertifikasi untuk Kampus Anda',
            subtitle:
                'Tingkatkan kualitas lulusan dengan joint program, guest lecturing, dan jalur sertifikasi industri.',
            gradientColors: [Color(0xFF1A0A3C), Color(0xFF3D2068), Color(0xFF7C68EE)],
            ctaLabel: 'Ajukan Kerja Sama',
            ctaRoute: '/hubungi',
            accentColor: AppColors.brandPurple,
          ),
        'sekolah' => const _SegMeta(
            badge: '🏫 Untuk Sekolah',
            title: 'Program Pendamping Belajar\nuntuk Siswa Sekolah',
            subtitle:
                'Perkaya pengalaman belajar siswa dengan after-school program, coding bootcamp, dan bimbingan karir.',
            gradientColors: [Color(0xFF1A2850), Color(0xFF2B4090), Color(0xFF3B90D9)],
            ctaLabel: 'Hubungi Tim Kami',
            ctaRoute: '/hubungi',
            accentColor: AppColors.brandBlue,
          ),
        'korporat' => const _SegMeta(
            badge: '🏢 Untuk Korporat',
            title: 'Inhouse Training &\nTalent Development',
            subtitle:
                'Program pelatihan korporat custom dengan harga bulk, progress tracking, dan sertifikasi tim.',
            gradientColors: [Color(0xFF1B2A1A), Color(0xFF2D5C2B), Color(0xFF00B894)],
            ctaLabel: 'Minta Proposal',
            ctaRoute: '/hubungi',
            accentColor: AppColors.brandGreen,
          ),
        _ => const _SegMeta(
            badge: '👤 Untuk Individu',
            title: 'Tingkatkan Skill,\nRaih Karir Impianmu',
            subtitle:
                'Katalog luas, jadwal fleksibel, berbagai opsi pembayaran, dan dukungan karir penuh.',
            gradientColors: [Color(0xFF3D2068), Color(0xFF5B3A9A), Color(0xFF7C68EE)],
            ctaLabel: 'Jelajahi Kursus',
            ctaRoute: '/katalog',
            accentColor: AppColors.brandPurple,
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
          _SegHero(meta: meta, padH: padH, padV: padV),
          _SegPainPoints(segment: segment, padH: padH, padV: padV),
          _SegSolutions(segment: segment, padH: padH, padV: padV),
          _SegPrograms(segment: segment, padH: padH, padV: padV),
          _SegTestimonial(segment: segment, padH: padH, padV: padV),
          _SegCta(meta: meta, padH: padH, padV: padV),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ── Meta ───────────────────────────────────────────────────────────────────

class _SegMeta {
  final String badge;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final String ctaLabel;
  final String ctaRoute;
  final Color accentColor;

  const _SegMeta({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.ctaLabel,
    required this.ctaRoute,
    required this.accentColor,
  });
}

// ── Hero ───────────────────────────────────────────────────────────────────

class _SegHero extends StatelessWidget {
  final _SegMeta meta;
  final double padH;
  final double padV;

  const _SegHero({required this.meta, required this.padH, required this.padV});

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
            onTap: () => context.go(meta.ctaRoute),
            height: 52,
            horizontalPadding: 32,
            icon: Icons.arrow_forward_rounded,
            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0D8F5)]),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

// ── Pain Points ────────────────────────────────────────────────────────────

class _SegPainPoints extends StatelessWidget {
  final String segment;
  final double padH;
  final double padV;

  const _SegPainPoints({required this.segment, required this.padH, required this.padV});

  List<_SCard3> get _items => switch (segment) {
        'universitas' => const [
            _SCard3(Icons.trending_down_rounded, 'Kurikulum Tidak Up-to-date',
                'Kurikulum akademik seringkali tertinggal dari perkembangan industri.', AppColors.brandOrange),
            _SCard3(Icons.work_off_outlined, 'Lulusan Kurang Siap Kerja',
                'Gap antara kompetensi akademik dan kebutuhan dunia kerja masih besar.', AppColors.brandRed),
            _SCard3(Icons.verified_user_outlined, 'Perlu Sertifikasi Industri',
                'Mahasiswa membutuhkan sertifikasi diakui industri untuk daya saing.', AppColors.brandGold),
          ],
        'sekolah' => const [
            _SCard3(Icons.extension_off_outlined, 'Ekstrakurikuler Terbatas',
                'Kegiatan ekstra tidak selalu memenuhi semua minat dan bakat siswa.', AppColors.brandOrange),
            _SCard3(Icons.trending_up_rounded, 'Butuh Skill Tambahan',
                'Teknologi mensyaratkan skill baru yang belum masuk kurikulum resmi.', AppColors.brandRed),
            _SCard3(Icons.compass_calibration_outlined, 'Persiapan Kuliah & Karir',
                'Siswa perlu bimbingan konkret untuk pilihan jurusan dan karir.', AppColors.brandGold),
          ],
        'korporat' => const [
            _SCard3(Icons.signal_cellular_alt_1_bar_rounded, 'Skill Gap Karyawan',
                'Kesenjangan skill antara kebutuhan bisnis dan kemampuan karyawan.', AppColors.brandOrange),
            _SCard3(Icons.money_off_outlined, 'Biaya Training Tinggi',
                'Program pelatihan konvensional mahal dengan kualitas tidak konsisten.', AppColors.brandRed),
            _SCard3(Icons.analytics_outlined, 'ROI Sulit Diukur',
                'Sulit mengukur dampak nyata investasi training terhadap produktivitas.', AppColors.brandGold),
          ],
        _ => const [
            _SCard3(Icons.help_outline_rounded, 'Tidak Tahu Mulai dari Mana',
                'Banyaknya pilihan membuat bingung memilih yang tepat.', AppColors.brandOrange),
            _SCard3(Icons.schedule_outlined, 'Butuh Fleksibilitas',
                'Kesibukan kerja atau kuliah menyulitkan mengikuti jadwal tetap.', AppColors.brandRed),
            _SCard3(Icons.savings_outlined, 'Biaya Terbatas',
                'Investasi belajar yang mahal menjadi penghalang pengembangan diri.', AppColors.brandGold),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'seg-pain-$segment',
        child: Column(
          children: [
            const SectionHeader(badge: '🔍 Tantangan', title: 'Tantangan yang\nAnda Hadapi'),
            const SizedBox(height: AppDimensions.s48),
            LayoutBuilder(builder: (_, c) {
              final cols = c.maxWidth > 700 ? 3 : 1;
              final sp = AppDimensions.s24;
              final w = (c.maxWidth - (cols - 1) * sp) / cols;
              return Wrap(
                spacing: sp,
                runSpacing: sp,
                children: _items.asMap().entries.map((e) {
                  return SizedBox(width: w, child: _SC3Widget(card: e.value, idx: e.key));
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SCard3 {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _SCard3(this.icon, this.title, this.desc, this.color);
}

class _SC3Widget extends StatelessWidget {
  final _SCard3 card;
  final int idx;

  const _SC3Widget({required this.card, required this.idx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(color: card.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(card.icon, color: card.color, size: 26),
          ),
          const SizedBox(height: AppDimensions.s16),
          Text(card.title, style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.s8),
          Text(card.desc, style: AppTextStyles.bodyS),
        ],
      ),
    ).animate(delay: (idx * 80).ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0);
  }
}

// ── Solutions ──────────────────────────────────────────────────────────────

class _SegSolutions extends StatelessWidget {
  final String segment;
  final double padH;
  final double padV;

  const _SegSolutions({required this.segment, required this.padH, required this.padV});

  List<_SCard3> get _items => switch (segment) {
        'universitas' => const [
            _SCard3(Icons.menu_book_outlined, 'Joint Program Kurikulum',
                'Kolaborasi merancang modul terintegrasi dengan kurikulum kampus.', AppColors.brandPurple),
            _SCard3(Icons.co_present_outlined, 'Guest Lecturing',
                'Praktisi industri hadir sebagai dosen tamu berbagi pengalaman nyata.', AppColors.brandBlue),
            _SCard3(Icons.workspace_premium_outlined, 'Jalur Sertifikasi',
                'Mahasiswa akses ujian sertifikasi dengan harga khusus kampus.', AppColors.brandGold),
            _SCard3(Icons.business_center_outlined, 'Penempatan Magang',
                'Koneksi langsung ke 50+ perusahaan mitra untuk magang terstruktur.', AppColors.brandGreen),
          ],
        'sekolah' => const [
            _SCard3(Icons.brightness_7_outlined, 'Program After-School',
                'Kelas sore fleksibel setelah jam sekolah, tanpa ganggu jadwal akademik.', AppColors.brandBlue),
            _SCard3(Icons.code_rounded, 'Coding Bootcamp',
                'Program coding intensif yang menyenangkan untuk pengenalan pemrograman.', AppColors.brandPurple),
            _SCard3(Icons.lightbulb_outline_rounded, 'Intro Entrepreneurship',
                'Kelas dasar kewirausahaan untuk menumbuhkan mindset bisnis sejak dini.', AppColors.brandGold),
            _SCard3(Icons.track_changes_rounded, 'Bimbingan Karir',
                'Sesi bimbingan mengenal minat, bakat, dan pilihan karir yang tepat.', AppColors.brandGreen),
          ],
        'korporat' => const [
            _SCard3(Icons.build_outlined, 'Custom Inhouse Training',
                'Program 100% disesuaikan dengan kebutuhan dan industri perusahaan.', AppColors.brandGreen),
            _SCard3(Icons.group_work_outlined, 'Harga Bulk Kompetitif',
                'Semakin banyak karyawan dilatih, semakin hemat per orang.', AppColors.brandBlue),
            _SCard3(Icons.bar_chart_rounded, 'Progress Tracking',
                'Dashboard HR untuk memantau perkembangan belajar karyawan realtime.', AppColors.brandPurple),
            _SCard3(Icons.workspace_premium_outlined, 'Sertifikasi Tim',
                'Karyawan mendapat sertifikat kompetensi resmi yang meningkatkan nilai.', AppColors.brandGold),
          ],
        _ => const [
            _SCard3(Icons.auto_awesome_outlined, 'Katalog Luas',
                'Ratusan kursus di berbagai bidang untuk semua level.', AppColors.brandPurple),
            _SCard3(Icons.schedule_outlined, 'Jadwal Fleksibel',
                'Kelas pagi, siang, malam, tatap muka, atau online.', AppColors.brandBlue),
            _SCard3(Icons.payments_outlined, 'Berbagai Opsi Pembayaran',
                'Lunas, cicilan, atau per sesi sesuai kondisi finansialmu.', AppColors.brandGreen),
            _SCard3(Icons.work_outline_rounded, 'Dukungan Karir',
                'Talent Pool, rekomendasi karir, dan jaringan alumni VernonEdu.', AppColors.brandGold),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'seg-sol-$segment',
        child: Column(
          children: [
            const SectionHeader(badge: '✅ Solusi', title: 'Solusi yang Kami\nTawarkan'),
            const SizedBox(height: AppDimensions.s48),
            LayoutBuilder(builder: (_, c) {
              final cols = c.maxWidth > 700 ? 2 : 1;
              final sp = AppDimensions.s24;
              final w = (c.maxWidth - (cols - 1) * sp) / cols;
              return Wrap(
                spacing: sp,
                runSpacing: sp,
                children: _items.asMap().entries.map((e) {
                  return SizedBox(
                    width: w,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.s24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(AppDimensions.r20),
                        border: Border.all(color: e.value.color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: e.value.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(e.value.icon, color: e.value.color, size: 26),
                          ),
                          const SizedBox(width: AppDimensions.s16),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.title, style: AppTextStyles.h4),
                              const SizedBox(height: AppDimensions.s8),
                              Text(e.value.desc, style: AppTextStyles.bodyS),
                            ],
                          )),
                        ],
                      ),
                    ).animate(delay: (e.key * 80).ms).fadeIn(duration: 500.ms)
                        .slideX(begin: e.key.isEven ? -0.08 : 0.08, end: 0),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Programs ───────────────────────────────────────────────────────────────

class _SegPrograms extends StatelessWidget {
  final String segment;
  final double padH;
  final double padV;

  const _SegPrograms({required this.segment, required this.padH, required this.padV});

  List<_PLink> get _links => switch (segment) {
        'universitas' => const [
            _PLink('Kolaborasi Universitas', Icons.account_balance_outlined, '/program/karir', AppColors.brandPurple),
            _PLink('Sertifikasi', Icons.verified_outlined, '/program/sertifikasi', AppColors.brandGold),
            _PLink('Program Karir', Icons.emoji_events_outlined, '/program/karir', AppColors.brandGreen),
          ],
        'sekolah' => const [
            _PLink('Kolaborasi Sekolah', Icons.account_balance_outlined, '/program/reguler', AppColors.brandBlue),
            _PLink('Kursus Reguler', Icons.menu_book_outlined, '/program/reguler', AppColors.brandPurple),
          ],
        'korporat' => const [
            _PLink('Inhouse Training', Icons.business_center_outlined, '/program/reguler', AppColors.brandGreen),
            _PLink('Sertifikasi Tim', Icons.workspace_premium_outlined, '/program/sertifikasi', AppColors.brandGold),
            _PLink('Kursus Privat', Icons.person_pin_outlined, '/program/privat', AppColors.brandBlue),
          ],
        _ => const [
            _PLink('Program Karir', Icons.emoji_events_outlined, '/program/karir', AppColors.brandPurple),
            _PLink('Kursus Reguler', Icons.menu_book_outlined, '/program/reguler', AppColors.brandBlue),
            _PLink('Kursus Privat', Icons.person_pin_outlined, '/program/privat', AppColors.brandGreen),
            _PLink('Sertifikasi', Icons.verified_outlined, '/program/sertifikasi', AppColors.brandGold),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'seg-prog-$segment',
        child: Column(
          children: [
            const SectionHeader(badge: '📚 Program', title: 'Program Relevan\nuntuk Anda'),
            const SizedBox(height: AppDimensions.s48),
            LayoutBuilder(builder: (_, c) {
              final cols = _links.length == 4 ? (c.maxWidth > 800 ? 4 : 2) : (c.maxWidth > 700 ? _links.length : 1);
              final sp = AppDimensions.s20;
              final w = (c.maxWidth - (cols - 1) * sp) / cols;
              return Wrap(
                spacing: sp,
                runSpacing: sp,
                children: _links.asMap().entries.map((e) {
                  return SizedBox(width: w, child: _PLinkWidget(link: e.value, idx: e.key));
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PLink {
  final String title;
  final IconData icon;
  final String route;
  final Color color;

  const _PLink(this.title, this.icon, this.route, this.color);
}

class _PLinkWidget extends StatefulWidget {
  final _PLink link;
  final int idx;

  const _PLinkWidget({required this.link, required this.idx});

  @override
  State<_PLinkWidget> createState() => _PLinkWidgetState();
}

class _PLinkWidgetState extends State<_PLinkWidget> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => context.go(widget.link.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.s20),
          decoration: BoxDecoration(
            color: _h ? widget.link.color.withValues(alpha: 0.06) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r20),
            border: Border.all(
              color: _h ? widget.link.color.withValues(alpha: 0.5) : AppColors.border,
              width: _h ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: widget.link.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.link.icon, color: widget.link.color, size: 24),
              ),
              const SizedBox(height: AppDimensions.s12),
              Text(widget.link.title, style: AppTextStyles.h4),
              const SizedBox(height: AppDimensions.s12),
              Row(children: [
                Text('Pelajari', style: AppTextStyles.labelS.copyWith(
                  color: widget.link.color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: widget.link.color),
              ]),
            ],
          ),
        ),
      ),
    ).animate(delay: (widget.idx * 80).ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Testimonial ────────────────────────────────────────────────────────────

class _SegTestimonial extends StatelessWidget {
  final String segment;
  final double padH;
  final double padV;

  const _SegTestimonial({required this.segment, required this.padH, required this.padV});

  ({String quote, String name, String role, String initials, Color color}) get _data =>
      switch (segment) {
        'universitas' => (
            quote:
                '"Program kolaborasi dengan VernonEdu sangat membantu mahasiswa kami. Kurikulum yang relevan dengan industri membuat lulusan lebih mudah terserap di pasar kerja."',
            name: 'Dr. Rahma Kusuma',
            role: 'Dekan Fakultas Teknik Informatika\nUniversitas Nusantara',
            initials: 'DR',
            color: AppColors.brandPurple,
          ),
        'sekolah' => (
            quote:
                '"Program after-school VernonEdu sangat disukai siswa-siswi kami. Mereka lebih percaya diri menghadapi era digital."',
            name: 'Bapak Prasetyo',
            role: 'Kepala Sekolah\nSMAN 12 Jakarta',
            initials: 'BP',
            color: AppColors.brandBlue,
          ),
        'korporat' => (
            quote:
                '"Program inhouse training VernonEdu mengubah kapabilitas tim kami. Produktivitas divisi digital marketing meningkat 40% dalam 3 bulan."',
            name: 'Andi Wibowo',
            role: 'VP Human Resources\nPT Maju Bersama Tbk.',
            initials: 'AW',
            color: AppColors.brandGreen,
          ),
        _ => (
            quote:
                '"Saya daftar Program Karir VernonEdu setelah resign. Dalam 6 bulan sudah magang di startup unicorn dan diterima sebagai karyawan tetap dengan gaji 2x lipat."',
            name: 'Nadia Aulia',
            role: 'Product Manager\nUnicorn Startup Indonesia',
            initials: 'NA',
            color: AppColors.brandPurple,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: ScrollAnimateWidget(
        uniqueKey: 'seg-testi-$segment',
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.s40),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppDimensions.r32),
            border: Border.all(color: d.color.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: d.color.withValues(alpha: 0.08), blurRadius: 32, offset: const Offset(0, 12))],
          ),
          child: Column(
            children: [
              Icon(Icons.format_quote_rounded, color: d.color, size: 48),
              const SizedBox(height: AppDimensions.s20),
              Text(d.quote,
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, height: 1.7),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppDimensions.s24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [d.color, d.color.withValues(alpha: 0.7)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text(d.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                  ),
                  const SizedBox(width: AppDimensions.s16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: AppTextStyles.labelL),
                    Text(d.role, style: AppTextStyles.bodyXS),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CTA ────────────────────────────────────────────────────────────────────

class _SegCta extends StatelessWidget {
  final _SegMeta meta;
  final double padH;
  final double padV;

  const _SegCta({required this.meta, required this.padH, required this.padV});

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
        uniqueKey: 'seg-cta-${meta.badge}',
        child: Column(
          children: [
            Text(meta.ctaLabel,
                style: AppTextStyles.displayM.copyWith(color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.s16),
            Text('Tim kami siap mendiskusikan solusi terbaik yang sesuai dengan kebutuhan Anda.',
                style: AppTextStyles.bodyLOnDark, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.s40),
            GradientButton(
              label: meta.ctaLabel,
              onTap: () => context.go(meta.ctaRoute),
              height: 56,
              horizontalPadding: 40,
              icon: Icons.arrow_forward_rounded,
              gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0D8F5)]),
            ),
          ],
        ),
      ),
    );
  }
}
