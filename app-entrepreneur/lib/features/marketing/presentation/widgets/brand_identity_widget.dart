import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Brand identity card — logo, warna, typography, tone of voice, USP.
class BrandIdentityWidget extends StatelessWidget {
  const BrandIdentityWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                const Icon(Icons.palette_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Brand Identity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: Text('Edit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildBrandCard()),
                      const SizedBox(width: AppDimensions.spacingM),
                      Expanded(child: _buildColorPalette()),
                      const SizedBox(width: AppDimensions.spacingM),
                      Expanded(child: _buildBrandVoice()),
                    ],
                  )
                : Column(
                    children: [
                      _buildBrandCard(),
                      const SizedBox(height: AppDimensions.spacingM),
                      _buildColorPalette(),
                      const SizedBox(height: AppDimensions.spacingM),
                      _buildBrandVoice(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
                child: const Icon(Icons.store_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bisnis 001', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Your tagline here', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _infoRow('USP', 'Belum diisi — definisikan keunikan bisnis kamu'),
          _infoRow('Target Market', 'Belum diisi — siapa audience utama kamu?'),
          _infoRow('Positioning', 'Belum diisi — posisi brand di pasar'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textLabel)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brand Colors', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _colorSwatch(const Color(0xFF4D2975), 'Primary'),
              const SizedBox(width: AppDimensions.spacingS),
              _colorSwatch(const Color(0xFF7B52A3), 'Secondary'),
              const SizedBox(width: AppDimensions.spacingS),
              _colorSwatch(const Color(0xFFFF6F00), 'Accent'),
              const SizedBox(width: AppDimensions.spacingS),
              _colorSwatch(const Color(0xFF1B2E4B), 'Dark'),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text('Typography', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Heading: Inter Bold', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          Text('Body: Inter Regular', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _colorSwatch(Color color, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBrandVoice() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brand Voice & Tone', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _voiceChip('Friendly', const Color(0xFF10B759)),
          _voiceChip('Professional', const Color(0xFF0168FA)),
          _voiceChip('Inspirational', const Color(0xFFFF6F00)),
          _voiceChip('Educational', const Color(0xFF4D2975)),
          const SizedBox(height: AppDimensions.spacingM),
          Text('Do\'s', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
          const SizedBox(height: 4),
          Text('• Gunakan bahasa yang mudah dipahami\n• Fokus pada manfaat untuk customer', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: AppDimensions.spacingS),
          Text('Don\'ts', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
          const SizedBox(height: 4),
          Text('• Jangan terlalu formal atau kaku\n• Hindari jargon teknis berlebihan', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _voiceChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
