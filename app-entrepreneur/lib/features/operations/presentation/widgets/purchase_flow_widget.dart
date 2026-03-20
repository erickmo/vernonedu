import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Flow node data.
class _FlowNode {
  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final int count;

  const _FlowNode({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.count,
  });
}

/// Purchase flow diagram ERPNext-style.
/// Menampilkan alur dokumen pembelian dengan visual graph.
class PurchaseFlowWidget extends StatelessWidget {
  const PurchaseFlowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

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
          _buildHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: isDesktop
                ? _buildDesktopFlow()
                : _buildMobileFlow(),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          const Icon(Icons.account_tree_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'Alur Dokumen Pembelian',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              'Document Flow',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DESKTOP FLOW (horizontal graph) ────────────────────────

  Widget _buildDesktopFlow() {
    return Column(
      children: [
        // Main flow: PO → PR → PI
        Row(
          children: [
            Expanded(child: _buildFlowNodeCard(_mainNodes[0])),
            _buildArrow('Terima Barang', false),
            Expanded(child: _buildFlowNodeCard(_mainNodes[1])),
            _buildArrow('Buat Invoice', false),
            Expanded(child: _buildFlowNodeCard(_mainNodes[2])),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),

        // Payment paths
        Row(
          children: [
            // Payment via PO (left)
            Expanded(
              child: _buildPaymentPath(
                'Payment Entry\n(via Purchase Order)',
                Icons.payment_rounded,
                const Color(0xFF6F42C1),
                'DP / Pembayaran langsung',
                4,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            // Return nodes (center)
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildReturnNode(
                    'Purchase Receipt\nReturn',
                    Icons.assignment_return_rounded,
                    const Color(0xFFDC3545),
                    'Retur Barang',
                    2,
                  )),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(child: _buildReturnNode(
                    'Purchase Invoice\nReturn',
                    Icons.receipt_long_rounded,
                    const Color(0xFFDC3545),
                    'Retur Invoice',
                    1,
                  )),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            // Payment via PI (right)
            Expanded(
              child: _buildPaymentPath(
                'Payment Entry\n(via Purchase Invoice)',
                Icons.payment_rounded,
                const Color(0xFF10B759),
                'Pelunasan / Cicilan',
                8,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.spacingM),

        // Connection labels
        _buildConnectionDiagram(),
      ],
    );
  }

  Widget _buildArrow(String label, [bool isDashed = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDashed ? AppColors.textMuted : AppColors.primary,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: isDashed ? AppColors.textMuted : AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowNodeCard(_FlowNode node) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: node.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: node.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: node.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(node.icon, color: node.color, size: 22),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            node.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: node.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Text(
              '${node.count} docs',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: node.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPath(
      String label, IconData icon, Color color, String desc, int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnNode(
      String label, IconData icon, Color color, String desc, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count retur',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionDiagram() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alur Koneksi Dokumen',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingS,
            children: [
              _buildConnectionChip('PO', 'Purchase Receipt', AppColors.primary),
              _buildConnectionChip('PO', 'Payment Entry (DP)', const Color(0xFF6F42C1)),
              _buildConnectionChip('PR', 'Purchase Invoice', const Color(0xFF0168FA)),
              _buildConnectionChip('PR', 'PR Return', const Color(0xFFDC3545)),
              _buildConnectionChip('PI', 'Payment Entry', const Color(0xFF10B759)),
              _buildConnectionChip('PI', 'PI Return', const Color(0xFFDC3545)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionChip(String from, String to, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              from,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded, size: 12, color: color),
          ),
          Text(
            to,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE FLOW (vertical list) ────────────────────────────

  Widget _buildMobileFlow() {
    return Column(
      children: [
        _buildMobileFlowSection(
          'Alur Utama',
          [_mainNodes[0], _mainNodes[1], _mainNodes[2]],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildMobileFlowSection(
          'Pembayaran',
          [
            const _FlowNode(
              id: 'pe-po', label: 'Payment Entry (via PO)',
              shortLabel: 'PE-PO', icon: Icons.payment_rounded,
              color: Color(0xFF6F42C1), count: 4,
            ),
            const _FlowNode(
              id: 'pe-pi', label: 'Payment Entry (via PI)',
              shortLabel: 'PE-PI', icon: Icons.payment_rounded,
              color: Color(0xFF10B759), count: 8,
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildMobileFlowSection(
          'Retur',
          [
            const _FlowNode(
              id: 'pr-return', label: 'Purchase Receipt Return',
              shortLabel: 'PR Retur', icon: Icons.assignment_return_rounded,
              color: Color(0xFFDC3545), count: 2,
            ),
            const _FlowNode(
              id: 'pi-return', label: 'Purchase Invoice Return',
              shortLabel: 'PI Retur', icon: Icons.receipt_long_rounded,
              color: Color(0xFFDC3545), count: 1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFlowSection(String title, List<_FlowNode> nodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textLabel,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ...nodes.asMap().entries.map((entry) {
          return Column(
            children: [
              _buildFlowNodeCard(entry.value),
              if (entry.key < nodes.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: AppColors.textMuted),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        spacing: AppDimensions.spacingM,
        runSpacing: AppDimensions.spacingS,
        children: [
          _buildLegendItem('Purchase Order', AppColors.primary),
          _buildLegendItem('Purchase Receipt', AppColors.info),
          _buildLegendItem('Purchase Invoice', const Color(0xFFFF6F00)),
          _buildLegendItem('Payment Entry', AppColors.success),
          _buildLegendItem('Return', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  static const _mainNodes = [
    _FlowNode(
      id: 'po',
      label: 'Purchase Order',
      shortLabel: 'PO',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFF4D2975),
      count: 24,
    ),
    _FlowNode(
      id: 'pr',
      label: 'Purchase Receipt',
      shortLabel: 'PR',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF0168FA),
      count: 20,
    ),
    _FlowNode(
      id: 'pi',
      label: 'Purchase Invoice',
      shortLabel: 'PI',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFF6F00),
      count: 18,
    ),
  ];
}
