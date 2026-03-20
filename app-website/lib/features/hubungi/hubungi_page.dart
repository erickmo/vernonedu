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

/// Halaman Hubungi Kami VernonEdu.
class HubungiPage extends StatelessWidget {
  const HubungiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);

    return WebScaffold(
      body: Column(
        children: [
          // Header
          _HubungiHeader(padH: padH),

          // Main content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padH,
              vertical: AppDimensions.s80,
            ),
            child: isMobile
                ? _MobileContent()
                : _DesktopContent(),
          ),

          // Map / office info
          _OfficeSection(padH: padH, isMobile: isMobile),

          const SizedBox(height: AppDimensions.s80),

          // FAQ mini
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH),
            child: const _FaqSection(),
          ),

          const SizedBox(height: AppDimensions.s80),

          const FooterWidget(),
        ],
      ),
    );
  }
}

class _HubungiHeader extends StatelessWidget {
  final double padH;

  const _HubungiHeader({required this.padH});

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
        badge: '📞 Hubungi Kami',
        title: 'Kami Siap Membantu\nPerjalanan Bisnis Anda',
        subtitle:
            'Punya pertanyaan tentang kursus, kolaborasi, atau membutuhkan konsultasi? Tim kami siap membantu Anda.',
        isDark: true,
      ),
    );
  }
}

class _DesktopContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _ContactForm()),
        const SizedBox(width: AppDimensions.s64),
        Expanded(flex: 4, child: _ContactInfo()),
      ],
    );
  }
}

class _MobileContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContactInfo(),
        const SizedBox(height: AppDimensions.s40),
        _ContactForm(),
      ],
    );
  }
}

/// Form kontak.
class _ContactForm extends StatefulWidget {
  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  String _selectedTopic = 'Informasi Kursus';
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SuccessMessage();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s32),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.r24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandIndigo.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kirim Pesan', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Kami akan membalas dalam 1x24 jam di hari kerja.',
              style: AppTextStyles.bodyS,
            ),

            const SizedBox(height: AppDimensions.s32),

            // Name + Email row
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    label: 'Nama Lengkap',
                    hint: 'Budi Santoso',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: AppDimensions.s16),
                Expanded(
                  child: _FormField(
                    label: 'Email',
                    hint: 'budi@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Email tidak valid' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.s20),

            // Phone
            _FormField(
              label: 'Nomor WhatsApp',
              hint: '+62 812-0000-0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: AppDimensions.s20),

            // Topic dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Topik', style: AppTextStyles.labelM),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTopic,
                      isExpanded: true,
                      dropdownColor: AppColors.bgCard,
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                      icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
                      items: const [
                        'Informasi Kursus',
                        'Pendaftaran & Pembayaran',
                        'Kemitraan & Kolaborasi',
                        'Sertifikasi',
                        'Lainnya',
                      ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) =>
                          v != null ? setState(() => _selectedTopic = v) : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.s20),

            // Message
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesan', style: AppTextStyles.labelM),
                const SizedBox(height: 8),
                TextFormField(
                  maxLines: 5,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ceritakan kebutuhan atau pertanyaan Anda...',
                    hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.bgInput,
                    contentPadding: const EdgeInsets.all(16),
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
                  validator: (v) =>
                      v == null || v.length < 10 ? 'Pesan minimal 10 karakter' : null,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.s32),

            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Kirim Pesan',
                onTap: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    setState(() => _submitted = true);
                  }
                },
                height: 56,
                horizontalPadding: 32,
                icon: Icons.send_rounded,
              ),
            ),

            const SizedBox(height: AppDimensions.s16),

            Text(
              'Dengan mengirim pesan ini, Anda menyetujui Kebijakan Privasi kami.',
              style: AppTextStyles.bodyXS.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.15, end: 0);
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelM),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            filled: true,
            fillColor: AppColors.bgInput,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.r24),
        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.brandGreen, size: 72),
          const SizedBox(height: 24),
          Text('Pesan Terkirim!', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Text(
            'Terima kasih telah menghubungi VernonEdu. Tim kami akan membalas pesan Anda dalam 1x24 jam di hari kerja.',
            style: AppTextStyles.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.brandGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Atau hubungi WhatsApp kami untuk respon lebih cepat',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.brandGreen),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(duration: 500.ms);
  }
}

/// Info kontak sidebar.
class _ContactInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Lain\nMenghubungi Kami', style: AppTextStyles.h2),

        const SizedBox(height: AppDimensions.s32),

        _ContactCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'WhatsApp',
          subtitle: 'Respon tercepat — biasanya < 1 jam',
          value: '+62 811-0000-0000',
          color: const Color(0xFF25D366),
        ),

        const SizedBox(height: AppDimensions.s16),

        _ContactCard(
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: 'Untuk pertanyaan formal & kemitraan',
          value: 'hello@vernonedu.id',
          color: AppColors.brandIndigo,
        ),

        const SizedBox(height: AppDimensions.s16),

        _ContactCard(
          icon: Icons.telegram,
          title: 'Telegram',
          subtitle: 'Komunitas & update kursus terbaru',
          value: '@vernonedu',
          color: const Color(0xFF229ED9),
        ),

        const SizedBox(height: AppDimensions.s32),

        // Office hours
        Container(
          padding: const EdgeInsets.all(AppDimensions.s20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      color: AppColors.brandIndigo, size: 20),
                  const SizedBox(width: 8),
                  Text('Jam Operasional', style: AppTextStyles.labelM),
                ],
              ),
              const SizedBox(height: 16),
              _HourRow(day: 'Senin — Jumat', hours: '09:00 — 17:00 WIB'),
              _HourRow(day: 'Sabtu', hours: '09:00 — 13:00 WIB'),
              _HourRow(day: 'Minggu & Libur Nasional', hours: 'Tutup'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online Sekarang',
                      style: AppTextStyles.bodyXS.copyWith(color: AppColors.brandGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.s24),

        // Social media
        Text('Ikuti Kami', style: AppTextStyles.labelM),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SocialBtn(icon: Icons.camera_alt_outlined, label: 'Instagram', color: Color(0xFFE1306C)),
            _SocialBtn(icon: Icons.play_circle_outline_rounded, label: 'YouTube', color: Color(0xFFFF0000)),
            _SocialBtn(icon: Icons.work_outline_rounded, label: 'LinkedIn', color: Color(0xFF0077B5)),
            _SocialBtn(icon: Icons.music_note_rounded, label: 'TikTok', color: Color(0xFF444444)),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.15, end: 0);
  }
}

class _ContactCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.s16),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withValues(alpha: 0.08) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.r16),
          border: Border.all(
            color: _hovered ? widget.color.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: AppDimensions.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.labelM),
                  Text(widget.subtitle, style: AppTextStyles.bodyXS, maxLines: 1),
                  const SizedBox(height: 2),
                  Text(
                    widget.value,
                    style: AppTextStyles.bodyS.copyWith(color: widget.color),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  final String day;
  final String hours;

  const _HourRow({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppTextStyles.bodyXS.copyWith(color: AppColors.textMuted)),
          Text(
            hours,
            style: AppTextStyles.bodyXS.copyWith(
              color: hours == 'Tutup' ? AppColors.error : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SocialBtn({required this.icon, required this.label, required this.color});

  @override
  State<_SocialBtn> createState() => _SocialBtnState();
}

class _SocialBtnState extends State<_SocialBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.12) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? widget.color.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: _hovered ? widget.color : AppColors.textMuted, size: 18),
              const SizedBox(width: 6),
              Text(widget.label, style: AppTextStyles.labelS.copyWith(
                color: _hovered ? widget.color : AppColors.textMuted,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficeSection extends StatelessWidget {
  final double padH;
  final bool isMobile;

  const _OfficeSection({required this.padH, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary.withValues(alpha: 0.3),
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: AppDimensions.s64),
      child: Column(
        children: [
          Text('Kantor Kami', style: AppTextStyles.h2, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.s40),
          Wrap(
            spacing: AppDimensions.s24,
            runSpacing: AppDimensions.s24,
            alignment: WrapAlignment.center,
            children: const [
              _OfficeCard(
                city: 'Jakarta (HQ)',
                address: 'Jl. Sudirman No. 123, Lantai 15\nJakarta Pusat, DKI Jakarta 10220',
                phone: '+62 21-0000-0000',
                isHQ: true,
              ),
              _OfficeCard(
                city: 'Surabaya',
                address: 'Jl. Pemuda No. 45, Lantai 8\nSurabaya, Jawa Timur 60271',
                phone: '+62 31-0000-0000',
                isHQ: false,
              ),
              _OfficeCard(
                city: 'Bali',
                address: 'Jl. Sunset Road No. 88\nKuta, Badung, Bali 80361',
                phone: '+62 361-0000-0000',
                isHQ: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final String city;
  final String address;
  final String phone;
  final bool isHQ;

  const _OfficeCard({
    required this.city,
    required this.address,
    required this.phone,
    required this.isHQ,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(
          color: isHQ ? AppColors.brandIndigo.withValues(alpha: 0.5) : AppColors.border,
          width: isHQ ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: isHQ ? AppColors.brandIndigo : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(city, style: AppTextStyles.h4),
              if (isHQ) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('HQ',
                      style: AppTextStyles.badge.copyWith(
                          color: Colors.white, fontSize: 9)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(address, style: AppTextStyles.bodyS.copyWith(height: 1.6)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(phone, style: AppTextStyles.bodyXS),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const _faqs = [
    _Faq(
      q: 'Bagaimana cara mendaftar kursus di VernonEdu?',
      a: 'Klik tombol "Mulai Belajar" di halaman utama, pilih kursus yang Anda inginkan, lalu lengkapi proses pembayaran. Akses kursus akan langsung tersedia setelah pembayaran dikonfirmasi.',
    ),
    _Faq(
      q: 'Apakah sertifikat VernonEdu diakui oleh perusahaan?',
      a: 'Ya, sertifikat VernonEdu diakui oleh 100+ perusahaan dan institusi mitra kami. Sertifikat dapat diverifikasi secara online menggunakan kode unik yang tertera.',
    ),
    _Faq(
      q: 'Bisakah saya mengakses kursus setelah pembelian?',
      a: 'Setelah membeli kursus, Anda mendapatkan akses seumur hidup ke semua materi, termasuk update konten di masa depan. Tidak ada batasan waktu akses.',
    ),
    _Faq(
      q: 'Apakah ada garansi uang kembali?',
      a: 'Ya, kami menawarkan garansi uang kembali 30 hari tanpa pertanyaan. Jika Anda tidak puas dengan kursus dalam 30 hari pertama, kami akan mengembalikan pembayaran penuh.',
    ),
    _Faq(
      q: 'Bagaimana sistem mentoring berjalan?',
      a: 'Setiap kursus premium dilengkapi dengan sesi mentoring group mingguan via Zoom. Untuk mentoring 1-on-1, dapat dijadwalkan melalui dashboard sesuai ketersediaan mentor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          badge: '❓ FAQ',
          title: 'Pertanyaan yang Sering\nDitanyakan',
        ),
        const SizedBox(height: AppDimensions.s48),
        Column(
          children: _faqs.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FaqItem(faq: e.value, index: e.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  final _Faq faq;
  final int index;

  const _FaqItem({required this.faq, required this.index});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _expanded ? AppColors.brandIndigo.withValues(alpha: 0.05) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(
          color: _expanded ? AppColors.brandIndigo.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: ExpansionTile(
        onExpansionChanged: (v) => setState(() => _expanded = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        collapsedIconColor: AppColors.textMuted,
        iconColor: AppColors.brandIndigo,
        title: Text(
          widget.faq.q,
          style: AppTextStyles.labelL.copyWith(
            color: _expanded ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        children: [
          Text(widget.faq.a, style: AppTextStyles.bodyM),
        ],
      ),
    )
        .animate(delay: (widget.index * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _Faq {
  final String q;
  final String a;

  const _Faq({required this.q, required this.a});
}
