import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _OrgNode {
  final String name;
  final String role;
  final Color color;
  final List<_OrgNode> children;
  const _OrgNode(this.name, this.role, this.color, [this.children = const []]);
}

/// Org chart — struktur organisasi visual.
class OrgChartWidget extends StatelessWidget {
  const OrgChartWidget({super.key});

  static const _org = _OrgNode('Kamu', 'CEO / Founder', Color(0xFF4D2975), [
    _OrgNode('Divisi Operasional', 'Operations', Color(0xFF0168FA), [
      _OrgNode('Ahmad', 'Produksi', Color(0xFF0168FA)),
      _OrgNode('Budi', 'Logistik', Color(0xFF0168FA)),
    ]),
    _OrgNode('Divisi Marketing', 'Marketing', Color(0xFF10B759), [
      _OrgNode('Citra', 'Social Media', Color(0xFF10B759)),
      _OrgNode('Dina', 'Content Creator', Color(0xFF10B759)),
    ]),
    _OrgNode('Divisi Finance', 'Finance & Admin', Color(0xFFFF6F00), [
      _OrgNode('Eka', 'Accounting', Color(0xFFFF6F00)),
      _OrgNode('Fani', 'Admin', Color(0xFFFF6F00)),
    ]),
  ]);

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
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                const Icon(Icons.account_tree_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Struktur Organisasi', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: isDesktop ? _buildDesktopChart() : _buildMobileChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopChart() {
    return Column(
      children: [
        _buildNodeCard(_org),
        _buildVerticalLine(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _org.children.asMap().entries.map((entry) {
            return Expanded(
              child: Column(
                children: [
                  Container(height: 2, color: AppColors.divider),
                  _buildVerticalLine(),
                  _buildNodeCard(entry.value),
                  if (entry.value.children.isNotEmpty) ...[
                    _buildVerticalLine(),
                    Row(
                      children: entry.value.children.map((child) {
                        return Expanded(child: _buildLeafNode(child));
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileChart() {
    return Column(
      children: [
        _buildNodeCard(_org),
        ..._org.children.map((div) {
          return Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacingM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: div.color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: div.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildNodeCard(div),
                  if (div.children.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                      child: Row(
                        children: div.children.map((child) {
                          return Expanded(child: _buildLeafNode(child));
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNodeCard(_OrgNode node) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: node.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: node.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: node.color.withValues(alpha: 0.2),
            child: Text(
              node.name[0],
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: node.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(node.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          Text(node.role, style: GoogleFonts.inter(fontSize: 10, color: node.color, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLeafNode(_OrgNode node) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: node.color.withValues(alpha: 0.15),
              child: Text(node.name[0], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: node.color)),
            ),
            const SizedBox(height: 4),
            Text(node.name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
            Text(node.role, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLine() {
    return Container(width: 2, height: 20, color: AppColors.divider);
  }
}
