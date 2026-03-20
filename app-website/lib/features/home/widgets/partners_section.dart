import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';

/// Partners/Trusted By section — logo carousel partner perusahaan.
class PartnersSection extends StatefulWidget {
  const PartnersSection({super.key});

  @override
  State<PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<PartnersSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scroll;

  static const _partners = [
    _Partner(name: 'TechCorp ID', initial: 'TC', color: Color(0xFF4F46E5)),
    _Partner(name: 'Nusa Ventures', initial: 'NV', color: Color(0xFF10B981)),
    _Partner(name: 'Garuda Group', initial: 'GG', color: Color(0xFFF59E0B)),
    _Partner(name: 'Invest.id', initial: 'IV', color: Color(0xFF3B82F6)),
    _Partner(name: 'Maju Bersama', initial: 'MB', color: Color(0xFF7C3AED)),
    _Partner(name: 'StartupHub', initial: 'SH', color: Color(0xFFEF4444)),
    _Partner(name: 'BizAcademy', initial: 'BA', color: Color(0xFF14B8A6)),
    _Partner(name: 'Akselerasi', initial: 'AK', color: Color(0xFFEC4899)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _scroll = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padH = Responsive.sectionPaddingH(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: padH,
        vertical: AppDimensions.s64,
      ),
      child: Column(
        children: [
          Text(
            'DIPERCAYA OLEH 100+ PERUSAHAAN & INSTITUSI',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.s32),

          // Auto-scrolling logos
          SizedBox(
            height: 64,
            child: AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: ScrollController(
                    initialScrollOffset:
                        _scroll.value * (_partners.length * 200.0),
                  ),
                  itemCount: _partners.length * 20,
                  itemBuilder: (context, i) {
                    final partner = _partners[i % _partners.length];
                    return _PartnerChip(partner: partner);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }
}

class _PartnerChip extends StatefulWidget {
  final _Partner partner;

  const _PartnerChip({required this.partner});

  @override
  State<_PartnerChip> createState() => _PartnerChipState();
}

class _PartnerChipState extends State<_PartnerChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.partner.color.withValues(alpha: 0.1)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? widget.partner.color.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.partner.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  widget.partner.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.partner.name,
              style: AppTextStyles.labelS.copyWith(
                color: _hovered ? widget.partner.color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Partner {
  final String name;
  final String initial;
  final Color color;

  const _Partner({required this.name, required this.initial, required this.color});
}
