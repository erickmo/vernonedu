import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _PayrollItem {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  const _PayrollItem(this.label, this.amount, this.icon, this.color);
}

/// Ringkasan payroll bulan ini.
class PayrollWidget extends StatelessWidget {
  const PayrollWidget({super.key});

  static const _items = [
    _PayrollItem('Total Gaji Pokok', 'Rp 3,200,000', Icons.payments_rounded, Color(0xFF4D2975)),
    _PayrollItem('Tunjangan', 'Rp 480,000', Icons.card_giftcard_rounded, Color(0xFF0168FA)),
    _PayrollItem('Bonus / Insentif', 'Rp 320,000', Icons.star_rounded, Color(0xFFFF6F00)),
    _PayrollItem('Potongan', 'Rp 160,000', Icons.remove_circle_rounded, Color(0xFFDC3545)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Payroll — Maret 2026', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Total
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd]),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              children: [
                Text('Total Payroll', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('Rp 3,840,000', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('8 anggota', style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          // Breakdown
          ..._items.map((item) => _buildItem(item)),
          const SizedBox(height: AppDimensions.spacingS),
        ],
      ),
    );
  }

  Widget _buildItem(_PayrollItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(item.label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
          Text(item.amount, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
