import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Tab Finance — overview keuangan, P&L summary, cash flow, journal entries.
class FinanceTab extends StatelessWidget {
  const FinanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildFinanceFlow(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildPnLSummary(context),
          const SizedBox(height: AppDimensions.spacingL),
          _buildJournalEntries(),
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
        _StatCard(icon: Icons.account_balance_rounded, color: Color(0xFF4D2975), value: 'Rp 28.3M', sub: 'Total Balance'),
        _StatCard(icon: Icons.trending_up_rounded, color: Color(0xFF10B759), value: 'Rp 32.5M', sub: 'Total Income'),
        _StatCard(icon: Icons.trending_down_rounded, color: Color(0xFFDC3545), value: 'Rp 15.2M', sub: 'Total Expense'),
        _StatCard(icon: Icons.savings_rounded, color: Color(0xFFFF6F00), value: 'Rp 17.3M', sub: 'Net Profit'),
      ],
    );
  }

  Widget _buildFinanceFlow(BuildContext context) {
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
                Text('Alur Dokumen Keuangan', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: isDesktop ? _buildDesktopFinanceFlow() : _buildMobileFinanceFlow(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFinanceFlow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildFlowNode('Journal Entry', Icons.edit_note_rounded, const Color(0xFF4D2975), 15)),
            _buildFlowArrow(),
            Expanded(child: _buildFlowNode('General Ledger', Icons.menu_book_rounded, const Color(0xFF0168FA), 0)),
            _buildFlowArrow(),
            Expanded(child: _buildFlowNode('Trial Balance', Icons.balance_rounded, const Color(0xFFFF6F00), 0)),
            _buildFlowArrow(),
            Expanded(child: _buildFlowNode('Financial\nStatements', Icons.assessment_rounded, const Color(0xFF10B759), 0)),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Row(
          children: [
            Expanded(child: _buildFlowNode('Payment Entry', Icons.payment_rounded, const Color(0xFF10B759), 18)),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(child: _buildFlowNode('Bank\nReconciliation', Icons.account_balance_rounded, const Color(0xFF1DA1F2), 3)),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(child: _buildFlowNode('Accounts\nReceivable', Icons.request_page_rounded, const Color(0xFFFF6F00), 12)),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(child: _buildFlowNode('Accounts\nPayable', Icons.receipt_rounded, const Color(0xFFDC3545), 7)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFinanceFlow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alur Utama', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textLabel)),
        const SizedBox(height: AppDimensions.spacingS),
        _buildFlowNode('Journal Entry', Icons.edit_note_rounded, const Color(0xFF4D2975), 15),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
        _buildFlowNode('General Ledger', Icons.menu_book_rounded, const Color(0xFF0168FA), 0),
        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
        _buildFlowNode('Trial Balance → Financial Statements', Icons.assessment_rounded, const Color(0xFF10B759), 0),
        const SizedBox(height: AppDimensions.spacingL),
        Text('Transaksi', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textLabel)),
        const SizedBox(height: AppDimensions.spacingS),
        _buildFlowNode('Payment Entry', Icons.payment_rounded, const Color(0xFF10B759), 18),
        const SizedBox(height: AppDimensions.spacingS),
        _buildFlowNode('Bank Reconciliation', Icons.account_balance_rounded, const Color(0xFF1DA1F2), 3),
      ],
    );
  }

  Widget _buildFlowNode(String label, IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: AppDimensions.spacingS),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3), textAlign: TextAlign.center),
          if (count > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusCircle)),
              child: Text('$count docs', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
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

  Widget _buildPnLSummary(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

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
                Text('Profit & Loss Summary', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusS), border: Border.all(color: AppColors.divider)),
                  child: Text('Maret 2026', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
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
                      Expanded(child: _buildPnLColumn('Income', const Color(0xFF10B759), _incomeItems)),
                      const SizedBox(width: AppDimensions.spacingL),
                      Expanded(child: _buildPnLColumn('Expense', const Color(0xFFDC3545), _expenseItems)),
                    ],
                  )
                : Column(
                    children: [
                      _buildPnLColumn('Income', const Color(0xFF10B759), _incomeItems),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildPnLColumn('Expense', const Color(0xFFDC3545), _expenseItems),
                    ],
                  ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Profit', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Rp 17,300,000', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF10B759))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnLColumn(String title, Color color, List<_PnLItem> items) {
    final total = items.fold<int>(0, (sum, i) => sum + i.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const Spacer(),
            Text('Rp ${_formatNum(total)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(item.label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
              Text('Rp ${_formatNum(item.amount)}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildJournalEntries() {
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
                Text('Journal Entries Terbaru', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Buat Journal', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._journalEntries.map((je) => _buildJERow(je)),
        ],
      ),
    );
  }

  Widget _buildJERow(_JournalEntry je) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(je.id, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(je.remark, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          )),
          Text('Rp ${_formatNum(je.amount)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(width: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: je.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(je.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: je.statusColor)),
          ),
        ],
      ),
    );
  }

  static String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }

  static const _incomeItems = [
    _PnLItem('Penjualan Produk', 25000000),
    _PnLItem('Penjualan Jasa', 5500000),
    _PnLItem('Pendapatan Lainnya', 2000000),
  ];

  static const _expenseItems = [
    _PnLItem('Bahan Baku', 8000000),
    _PnLItem('Gaji & Upah', 4000000),
    _PnLItem('Sewa & Utilities', 1500000),
    _PnLItem('Marketing', 1200000),
    _PnLItem('Operasional Lainnya', 500000),
  ];

  static const _journalEntries = [
    _JournalEntry('JE-2026-015', 'Pembelian bahan baku dari PT Sumber Makmur', 2500000, 'Submitted', AppColors.info),
    _JournalEntry('JE-2026-014', 'Pembayaran gaji karyawan bulan Maret', 4000000, 'Submitted', AppColors.info),
    _JournalEntry('JE-2026-013', 'Penerimaan pembayaran dari CV Berkah', 8000000, 'Submitted', AppColors.info),
    _JournalEntry('JE-2026-012', 'Pembayaran sewa tempat', 1500000, 'Draft', AppColors.textMuted),
  ];
}

class _PnLItem {
  final String label;
  final int amount;
  const _PnLItem(this.label, this.amount);
}

class _JournalEntry {
  final String id;
  final String remark;
  final int amount;
  final String status;
  final Color statusColor;
  const _JournalEntry(this.id, this.remark, this.amount, this.status, this.statusColor);
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusM), border: Border.all(color: AppColors.divider.withValues(alpha: 0.5))),
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
