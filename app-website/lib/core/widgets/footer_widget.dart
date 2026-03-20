import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import '../router/app_router.dart';
import '../utils/responsive.dart';

/// Footer website VernonEdu — 4 kolom, social links, copyright.
class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      color: AppColors.bgSecondary,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? AppDimensions.s24
            : AppDimensions.sectionPaddingH,
        vertical: AppDimensions.s80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section
          isMobile
              ? _MobileFooterContent()
              : _DesktopFooterContent(),

          const SizedBox(height: AppDimensions.s64),

          // Divider
          Container(
            height: 1,
            color: AppColors.border,
          ),

          const SizedBox(height: AppDimensions.s32),

          // Bottom
          _BottomBar(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _DesktopFooterContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand column
        Expanded(flex: 3, child: _BrandColumn()),
        const SizedBox(width: AppDimensions.s64),
        // Link columns
        Expanded(flex: 2, child: _FooterLinkColumn(
          title: 'Platform',
          links: const [
            _FooterLink(label: 'Beranda', path: AppRouter.home),
            _FooterLink(label: 'Kursus', path: AppRouter.kursus),
            _FooterLink(label: 'Update & Blog', path: AppRouter.update),
            _FooterLink(label: 'Hubungi Kami', path: AppRouter.hubungi),
          ],
        )),
        const SizedBox(width: AppDimensions.s48),
        Expanded(flex: 2, child: _FooterLinkColumn(
          title: 'Kursus',
          links: const [
            _FooterLink(label: 'Bisnis dari Nol', path: AppRouter.kursus),
            _FooterLink(label: 'Digital Marketing', path: AppRouter.kursus),
            _FooterLink(label: 'Manajemen Keuangan', path: AppRouter.kursus),
            _FooterLink(label: 'E-Commerce', path: AppRouter.kursus),
            _FooterLink(label: 'Leadership', path: AppRouter.kursus),
          ],
        )),
        const SizedBox(width: AppDimensions.s48),
        Expanded(flex: 2, child: _FooterContactColumn()),
      ],
    );
  }
}

class _MobileFooterContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandColumn(),
        const SizedBox(height: AppDimensions.s40),
        _FooterLinkColumn(
          title: 'Platform',
          links: const [
            _FooterLink(label: 'Beranda', path: AppRouter.home),
            _FooterLink(label: 'Kursus', path: AppRouter.kursus),
            _FooterLink(label: 'Update & Blog', path: AppRouter.update),
            _FooterLink(label: 'Hubungi Kami', path: AppRouter.hubungi),
          ],
        ),
        const SizedBox(height: AppDimensions.s32),
        _FooterContactColumn(),
      ],
    );
  }
}

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Vernon',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'Edu',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = AppColors.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 80, 30),
                    ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.s16),
        Text(
          'Platform edukasi wirausaha terdepan yang membantu Anda membangun dan mengembangkan bisnis dengan kursus berkualitas.',
          style: AppTextStyles.bodyS.copyWith(
            color: AppColors.textMuted,
            height: 1.7,
          ),
          maxLines: 4,
        ),
        const SizedBox(height: AppDimensions.s24),
        // Social media
        Row(
          children: [
            _SocialButton(icon: Icons.telegram, label: 'Telegram'),
            const SizedBox(width: AppDimensions.s12),
            _SocialButton(icon: Icons.play_circle_outline, label: 'YouTube'),
            const SizedBox(width: AppDimensions.s12),
            _SocialButton(icon: Icons.linked_camera_outlined, label: 'LinkedIn'),
            const SizedBox(width: AppDimensions.s12),
            _SocialButton(icon: Icons.camera_alt_outlined, label: 'Instagram'),
          ],
        ),
        const SizedBox(height: AppDimensions.s24),
        // Trust badges
        Row(
          children: [
            _TrustBadge(label: '10K+ Pelajar'),
            const SizedBox(width: AppDimensions.s8),
            _TrustBadge(label: '95% Berhasil'),
          ],
        ),
      ],
    );
  }
}

class _FooterLinkColumn extends StatelessWidget {
  final String title;
  final List<_FooterLink> links;

  const _FooterLinkColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelL.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.s20),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.s12),
              child: _FooterLinkItem(link: link),
            )),
      ],
    );
  }
}

class _FooterLink {
  final String label;
  final String path;
  const _FooterLink({required this.label, required this.path});
}

class _FooterLinkItem extends StatefulWidget {
  final _FooterLink link;
  const _FooterLinkItem({required this.link});

  @override
  State<_FooterLinkItem> createState() => _FooterLinkItemState();
}

class _FooterLinkItemState extends State<_FooterLinkItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.link.path),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppTextStyles.bodyS.copyWith(
            color: _hovered ? AppColors.textPrimary : AppColors.textMuted,
          ),
          child: Text(widget.link.label),
        ),
      ),
    );
  }
}

class _FooterContactColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kontak',
          style: AppTextStyles.labelL.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.s20),
        _ContactItem(
          icon: Icons.email_outlined,
          text: 'hello@vernonedu.id',
        ),
        const SizedBox(height: AppDimensions.s12),
        _ContactItem(
          icon: Icons.phone_outlined,
          text: '+62 811-0000-0000',
        ),
        const SizedBox(height: AppDimensions.s12),
        _ContactItem(
          icon: Icons.location_on_outlined,
          text: 'Jakarta, Indonesia',
        ),
        const SizedBox(height: AppDimensions.s24),
        // Newsletter mini
        Text(
          'Dapatkan update terbaru',
          style: AppTextStyles.labelS,
        ),
        const SizedBox(height: AppDimensions.s12),
        _NewsletterInput(),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.brandIndigo, size: 16),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  final IconData icon;
  final String label;

  const _SocialButton({required this.icon, required this.label});

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: _hovered ? AppColors.primaryGradient : null,
            color: _hovered ? null : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? Colors.white : AppColors.textMuted,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final String label;

  const _TrustBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.brandIndigo.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyXS.copyWith(color: AppColors.textAccent),
      ),
    );
  }
}

class _NewsletterInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              style: AppTextStyles.bodyS.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Email Anda...',
                hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bgSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.brandIndigo),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool isMobile;

  const _BottomBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final copyright = Text(
      '© 2026 VernonEdu. Seluruh hak cipta dilindungi.',
      style: AppTextStyles.bodyXS.copyWith(color: AppColors.textMuted),
    );

    final links = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegalLink(label: 'Kebijakan Privasi'),
        const SizedBox(width: 20),
        _LegalLink(label: 'Syarat & Ketentuan'),
        const SizedBox(width: 20),
        _LegalLink(label: 'Cookie Policy'),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copyright,
          const SizedBox(height: 12),
          links,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [copyright, links],
    );
  }
}

class _LegalLink extends StatefulWidget {
  final String label;

  const _LegalLink({required this.label});

  @override
  State<_LegalLink> createState() => _LegalLinkState();
}

class _LegalLinkState extends State<_LegalLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Text(
        widget.label,
        style: AppTextStyles.bodyXS.copyWith(
          color: _hovered ? AppColors.textPrimary : AppColors.textMuted,
          decoration: _hovered ? TextDecoration.underline : null,
        ),
      ),
    );
  }
}
