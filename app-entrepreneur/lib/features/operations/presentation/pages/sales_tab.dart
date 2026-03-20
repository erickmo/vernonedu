import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Tab Penjualan — statistik, flow diagram, dan daftar dokumen penjualan.
/// Alur: Quotation → Sales Order → Delivery Note → Sales Invoice → Payment Entry
/// Return: DN Return, SI Return
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildFlowDiagram(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildDocumentList(),
        ],
      ),
    );
  }

  // ─── STATS ──────────────────────────────────────────────────

  Widget _buildStats(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 2.2 : (isTablet ? 2.0 : 3.0),
      children: const [
        _StatCard(icon: Icons.request_quote_rounded, color: Color(0xFF4D2975), value: '18', label: 'Total SO', sub: 'Sales Orders'),
        _StatCard(icon: Icons.attach_money_rounded, color: Color(0xFF10B759), value: 'Rp 32.5M', label: 'Revenue', sub: 'Bulan ini'),
        _StatCard(icon: Icons.local_shipping_rounded, color: Color(0xFF0168FA), value: '5', label: 'Pending Delivery', sub: 'Belum dikirim'),
        _StatCard(icon: Icons.check_circle_rounded, color: Color(0xFFFF6F00), value: '12', label: 'Unpaid Invoice', sub: 'Belum dibayar'),
      ],
    );
  }

  // ─── FLOW DIAGRAM ──────────────────────────────────────────

  Widget _buildFlowDiagram(BuildContext context) {
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
        children: [
          _buildFlowHeader(),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: isDesktop ? _buildDesktopFlow() : _buildMobileFlow(),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildFlowHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          const Icon(Icons.account_tree_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'Alur Dokumen Penjualan',
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

  Widget _buildDesktopFlow() {
    return Column(
      children: [
        // Main flow: Quotation → SO → DN → SI
        Row(
          children: [
            Expanded(child: _buildNode('Quotation', Icons.description_rounded, const Color(0xFF8E44AD), 12)),
            _buildArrow('Confirm'),
            Expanded(child: _buildNode('Sales Order', Icons.request_quote_rounded, const Color(0xFF4D2975), 18)),
            _buildArrow('Kirim'),
            Expanded(child: _buildNode('Delivery Note', Icons.local_shipping_rounded, const Color(0xFF0168FA), 15)),
            _buildArrow('Invoice'),
            Expanded(child: _buildNode('Sales Invoice', Icons.receipt_long_rounded, const Color(0xFFFF6F00), 14)),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // Payment & Returns
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(child: _buildSmallNode('DN Return', Icons.assignment_return_rounded, const Color(0xFFDC3545), 1)),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(child: _buildSmallNode('SI Return', Icons.receipt_long_rounded, const Color(0xFFDC3545), 0)),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              flex: 2,
              child: _buildPaymentNode(
                'Payment Entry\n(via Sales Invoice)',
                Icons.payment_rounded,
                const Color(0xFF10B759),
                'Pembayaran customer',
                10,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildConnections(),
      ],
    );
  }

  Widget _buildMobileFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobileSection('Alur Utama', [
          _buildNode('Quotation', Icons.description_rounded, const Color(0xFF8E44AD), 12),
          _buildNode('Sales Order', Icons.request_quote_rounded, const Color(0xFF4D2975), 18),
          _buildNode('Delivery Note', Icons.local_shipping_rounded, const Color(0xFF0168FA), 15),
          _buildNode('Sales Invoice', Icons.receipt_long_rounded, const Color(0xFFFF6F00), 14),
        ]),
        const SizedBox(height: AppDimensions.spacingL),
        _buildMobileSection('Pembayaran', [
          _buildNode('Payment Entry', Icons.payment_rounded, const Color(0xFF10B759), 10),
        ]),
        const SizedBox(height: AppDimensions.spacingL),
        _buildMobileSection('Retur', [
          _buildNode('DN Return', Icons.assignment_return_rounded, const Color(0xFFDC3545), 1),
          _buildNode('SI Return', Icons.receipt_long_rounded, const Color(0xFFDC3545), 0),
        ]),
      ],
    );
  }

  Widget _buildMobileSection(String title, List<Widget> nodes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textLabel)),
        const SizedBox(height: AppDimensions.spacingS),
        ...nodes.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < nodes.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildNode(String label, IconData icon, Color color, int count) {
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
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusCircle)),
            child: Text('$count docs', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallNode(String label, IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('$count retur', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildPaymentNode(String label, IconData icon, Color color, String desc, int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
                const SizedBox(height: 2),
                Text(desc, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusCircle)),
            child: Text('$count', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Row(
              children: [
                Expanded(child: Container(height: 2, color: AppColors.primary)),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnections() {
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
          Text('Alur Koneksi Dokumen', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingS,
            children: [
              _chip('QTN', 'Sales Order', const Color(0xFF8E44AD)),
              _chip('SO', 'Delivery Note', AppColors.primary),
              _chip('DN', 'Sales Invoice', const Color(0xFF0168FA)),
              _chip('DN', 'DN Return', const Color(0xFFDC3545)),
              _chip('SI', 'Payment Entry', const Color(0xFF10B759)),
              _chip('SI', 'SI Return', const Color(0xFFDC3545)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String from, String to, Color color) {
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
            child: Text(from, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded, size: 12, color: color),
          ),
          Text(to, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        spacing: AppDimensions.spacingM,
        runSpacing: AppDimensions.spacingS,
        children: [
          _legendItem('Quotation', const Color(0xFF8E44AD)),
          _legendItem('Sales Order', AppColors.primary),
          _legendItem('Delivery Note', const Color(0xFF0168FA)),
          _legendItem('Sales Invoice', const Color(0xFFFF6F00)),
          _legendItem('Payment Entry', const Color(0xFF10B759)),
          _legendItem('Return', const Color(0xFFDC3545)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  // ─── DOCUMENT LIST ─────────────────────────────────────────

  Widget _buildDocumentList() {
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
                Text('Daftar Dokumen Penjualan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Buat Quotation', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._sampleDocs.map((doc) => _buildDocRow(doc)),
        ],
      ),
    );
  }

  Widget _buildDocRow(_SalesDoc doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: doc.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Icon(doc.icon, color: doc.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(doc.id, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: doc.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
                      child: Text(doc.type, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: doc.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(doc.customer, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(doc.amount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: doc.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(doc.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: doc.statusColor)),
          ),
        ],
      ),
    );
  }

  static const _sampleDocs = [
    _SalesDoc('QTN-2026-005', 'QTN', 'Toko Maju Bersama', 'Rp 5.2M', 'Draft', Icons.description_rounded, Color(0xFF8E44AD), AppColors.textMuted),
    _SalesDoc('SO-2026-012', 'SO', 'CV Berkah Selalu', 'Rp 8.0M', 'Submitted', Icons.request_quote_rounded, Color(0xFF4D2975), AppColors.info),
    _SalesDoc('DN-2026-008', 'DN', 'PT Harmoni Digital', 'Rp 3.5M', 'Completed', Icons.local_shipping_rounded, Color(0xFF0168FA), AppColors.success),
    _SalesDoc('SI-2026-010', 'SI', 'CV Berkah Selalu', 'Rp 8.0M', 'Unpaid', Icons.receipt_long_rounded, Color(0xFFFF6F00), Color(0xFFFF6F00)),
    _SalesDoc('PE-2026-003', 'PE', 'PT Harmoni Digital', 'Rp 3.5M', 'Paid', Icons.payment_rounded, Color(0xFF10B759), AppColors.success),
  ];
}

class _SalesDoc {
  final String id;
  final String type;
  final String customer;
  final String amount;
  final String status;
  final IconData icon;
  final Color color;
  final Color statusColor;

  const _SalesDoc(this.id, this.type, this.customer, this.amount, this.status, this.icon, this.color, this.statusColor);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String sub;

  const _StatCard({required this.icon, required this.color, required this.value, required this.label, required this.sub});

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
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
