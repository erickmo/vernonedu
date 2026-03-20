import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Tab Stock — overview stok, stock ledger, warehouse summary.
class StockTab extends StatelessWidget {
  const StockTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildStockFlow(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildStockTable(),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 2.2 : (isTablet ? 2.0 : 3.0),
      children: const [
        _StatCard(icon: Icons.inventory_2_rounded, color: Color(0xFF4D2975), value: '156', sub: 'Total Item'),
        _StatCard(icon: Icons.warehouse_rounded, color: Color(0xFF0168FA), value: '3', sub: 'Warehouse'),
        _StatCard(icon: Icons.warning_amber_rounded, color: Color(0xFFFF6F00), value: '12', sub: 'Low Stock'),
        _StatCard(icon: Icons.trending_up_rounded, color: Color(0xFF10B759), value: 'Rp 45.8M', sub: 'Stock Value'),
      ],
    );
  }

  Widget _buildStockFlow(BuildContext context) {
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
                Text('Alur Stock', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: isDesktop ? _buildDesktopStockFlow() : _buildMobileStockFlow(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStockFlow() {
    return Row(
      children: [
        Expanded(child: _buildFlowNode('Stock Entry\n(Material Receipt)', Icons.input_rounded, const Color(0xFF10B759), 'Barang Masuk', 45)),
        _buildFlowArrow(),
        Expanded(child: _buildFlowNode('Warehouse', Icons.warehouse_rounded, const Color(0xFF0168FA), 'Penyimpanan', 156)),
        _buildFlowArrow(),
        Expanded(child: _buildFlowNode('Stock Entry\n(Material Issue)', Icons.output_rounded, const Color(0xFFFF6F00), 'Barang Keluar', 38)),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(child: _buildFlowNode('Stock\nReconciliation', Icons.sync_rounded, const Color(0xFF4D2975), 'Penyesuaian', 5)),
      ],
    );
  }

  Widget _buildMobileStockFlow() {
    return Column(
      children: [
        _buildFlowNode('Stock Entry (Material Receipt)', Icons.input_rounded, const Color(0xFF10B759), 'Barang Masuk', 45),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
        _buildFlowNode('Warehouse', Icons.warehouse_rounded, const Color(0xFF0168FA), 'Penyimpanan', 156),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
        _buildFlowNode('Stock Entry (Material Issue)', Icons.output_rounded, const Color(0xFFFF6F00), 'Barang Keluar', 38),
        const SizedBox(height: AppDimensions.spacingS),
        _buildFlowNode('Stock Reconciliation', Icons.sync_rounded, const Color(0xFF4D2975), 'Penyesuaian', 5),
      ],
    );
  }

  Widget _buildFlowNode(String label, IconData icon, Color color, String desc, int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusCircle)),
            child: Text('$count', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.textMuted),
    );
  }

  Widget _buildStockTable() {
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
                Text('Stock Ledger', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Stock Entry', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._stockItems.map((item) => _buildStockRow(item)),
        ],
      ),
    );
  }

  Widget _buildStockRow(_StockItem item) {
    final stockColor = item.qty <= item.reorderLevel ? AppColors.error : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(item.warehouse, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          )),
          Expanded(flex: 1, child: Text('${item.qty} ${item.uom}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: stockColor), textAlign: TextAlign.right)),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(flex: 1, child: Text(item.value, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.right)),
          const SizedBox(width: AppDimensions.spacingM),
          if (item.qty <= item.reorderLevel)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
              child: Text('Low', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
              child: Text('OK', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
        ],
      ),
    );
  }

  static const _stockItems = [
    _StockItem('Bahan Baku A', 'Gudang Utama', 150, 50, 'pcs', 'Rp 3.0M'),
    _StockItem('Bahan Baku B', 'Gudang Utama', 30, 50, 'kg', 'Rp 1.5M'),
    _StockItem('Packaging Box M', 'Gudang Packaging', 500, 100, 'pcs', 'Rp 2.5M'),
    _StockItem('Label Produk', 'Gudang Packaging', 80, 200, 'pcs', 'Rp 400K'),
    _StockItem('Produk Jadi X', 'Gudang Produk', 45, 20, 'pcs', 'Rp 9.0M'),
    _StockItem('Produk Jadi Y', 'Gudang Produk', 12, 15, 'pcs', 'Rp 4.8M'),
  ];
}

class _StockItem {
  final String name;
  final String warehouse;
  final int qty;
  final int reorderLevel;
  final String uom;
  final String value;

  const _StockItem(this.name, this.warehouse, this.qty, this.reorderLevel, this.uom, this.value);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String sub;

  const _StatCard({required this.icon, required this.color, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ])),
        ],
      ),
    );
  }
}
