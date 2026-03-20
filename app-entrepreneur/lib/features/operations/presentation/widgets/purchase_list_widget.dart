import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

enum DocType { po, pr, pi, pepo, pepi, prReturn, piReturn }

enum DocStatus { draft, submitted, paid, cancelled, returned }

class PurchaseDoc {
  final String id;
  final DocType type;
  final String supplier;
  final double amount;
  final DateTime date;
  final DocStatus status;
  final String? linkedFrom;

  const PurchaseDoc({
    required this.id,
    required this.type,
    required this.supplier,
    required this.amount,
    required this.date,
    required this.status,
    this.linkedFrom,
  });
}

/// Daftar dokumen pembelian — filterable per tipe.
class PurchaseListWidget extends StatefulWidget {
  const PurchaseListWidget({super.key});

  @override
  State<PurchaseListWidget> createState() => _PurchaseListWidgetState();
}

class _PurchaseListWidgetState extends State<PurchaseListWidget> {
  DocType? _filterType;

  // TODO: replace with Cubit state
  static final _docs = [
    PurchaseDoc(
      id: 'PO-2026-001', type: DocType.po, supplier: 'PT Sumber Makmur',
      amount: 2500000, date: DateTime(2026, 3, 15), status: DocStatus.submitted,
    ),
    PurchaseDoc(
      id: 'PO-2026-002', type: DocType.po, supplier: 'CV Abadi Jaya',
      amount: 1800000, date: DateTime(2026, 3, 14), status: DocStatus.paid,
    ),
    PurchaseDoc(
      id: 'PR-2026-001', type: DocType.pr, supplier: 'PT Sumber Makmur',
      amount: 2500000, date: DateTime(2026, 3, 15), status: DocStatus.submitted,
      linkedFrom: 'PO-2026-001',
    ),
    PurchaseDoc(
      id: 'PI-2026-001', type: DocType.pi, supplier: 'PT Sumber Makmur',
      amount: 2500000, date: DateTime(2026, 3, 16), status: DocStatus.submitted,
      linkedFrom: 'PR-2026-001',
    ),
    PurchaseDoc(
      id: 'PE-2026-001', type: DocType.pepi, supplier: 'PT Sumber Makmur',
      amount: 2500000, date: DateTime(2026, 3, 16), status: DocStatus.paid,
      linkedFrom: 'PI-2026-001',
    ),
    PurchaseDoc(
      id: 'PE-2026-002', type: DocType.pepo, supplier: 'CV Abadi Jaya',
      amount: 900000, date: DateTime(2026, 3, 14), status: DocStatus.paid,
      linkedFrom: 'PO-2026-002',
    ),
    PurchaseDoc(
      id: 'PR-RET-001', type: DocType.prReturn, supplier: 'CV Abadi Jaya',
      amount: 300000, date: DateTime(2026, 3, 13), status: DocStatus.returned,
      linkedFrom: 'PR-2026-002',
    ),
    PurchaseDoc(
      id: 'PO-2026-003', type: DocType.po, supplier: 'UD Sejahtera',
      amount: 4200000, date: DateTime(2026, 3, 12), status: DocStatus.draft,
    ),
  ];

  List<PurchaseDoc> get _filteredDocs {
    if (_filterType == null) return _docs;
    return _docs.where((d) => d.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(),
          const Divider(height: 1, color: AppColors.divider),
          _buildFilterChips(),
          const Divider(height: 1, color: AppColors.divider),
          _buildTable(context),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Text(
            'Daftar Dokumen Pembelian',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: create new PO
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(
              'Buat PO',
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Row(
        children: [
          _buildChip('Semua', null),
          _buildChip('Purchase Order', DocType.po),
          _buildChip('Purchase Receipt', DocType.pr),
          _buildChip('Purchase Invoice', DocType.pi),
          _buildChip('Payment (PO)', DocType.pepo),
          _buildChip('Payment (PI)', DocType.pepi),
          _buildChip('PR Return', DocType.prReturn),
          _buildChip('PI Return', DocType.piReturn),
        ],
      ),
    );
  }

  Widget _buildChip(String label, DocType? type) {
    final isSelected = _filterType == type;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingS),
      child: InkWell(
        onTap: () => setState(() => _filterType = type),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final docs = _filteredDocs;

    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Center(
          child: Text(
            'Tidak ada dokumen.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, index) => _buildDocRow(docs[index]),
    );
  }

  Widget _buildDocRow(PurchaseDoc doc) {
    final typeConfig = _typeConfig(doc.type);
    final statusConfig = _statusConfig(doc.status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeConfig.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(typeConfig.icon, color: typeConfig.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      doc.id,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeConfig.color.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        typeConfig.label,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: typeConfig.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  doc.supplier,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (doc.linkedFrom != null)
                  Text(
                    'dari ${doc.linkedFrom}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(doc.amount),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusConfig.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              statusConfig.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusConfig.color,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Text(
            _formatDate(doc.date),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  _TypeConfig _typeConfig(DocType type) {
    switch (type) {
      case DocType.po:
        return const _TypeConfig('PO', Icons.shopping_cart_rounded, Color(0xFF4D2975));
      case DocType.pr:
        return const _TypeConfig('PR', Icons.local_shipping_rounded, Color(0xFF0168FA));
      case DocType.pi:
        return const _TypeConfig('PI', Icons.receipt_long_rounded, Color(0xFFFF6F00));
      case DocType.pepo:
        return const _TypeConfig('PE-PO', Icons.payment_rounded, Color(0xFF6F42C1));
      case DocType.pepi:
        return const _TypeConfig('PE-PI', Icons.payment_rounded, Color(0xFF10B759));
      case DocType.prReturn:
        return const _TypeConfig('PR-RET', Icons.assignment_return_rounded, Color(0xFFDC3545));
      case DocType.piReturn:
        return const _TypeConfig('PI-RET', Icons.receipt_long_rounded, Color(0xFFDC3545));
    }
  }

  _TypeConfig _statusConfig(DocStatus status) {
    switch (status) {
      case DocStatus.draft:
        return const _TypeConfig('Draft', Icons.edit_rounded, AppColors.textMuted);
      case DocStatus.submitted:
        return const _TypeConfig('Submitted', Icons.check_rounded, AppColors.info);
      case DocStatus.paid:
        return const _TypeConfig('Paid', Icons.check_circle_rounded, AppColors.success);
      case DocStatus.cancelled:
        return const _TypeConfig('Cancelled', Icons.cancel_rounded, AppColors.error);
      case DocStatus.returned:
        return const _TypeConfig('Returned', Icons.assignment_return_rounded, Color(0xFFDC3545));
    }
  }
}

class _TypeConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _TypeConfig(this.label, this.icon, this.color);
}
