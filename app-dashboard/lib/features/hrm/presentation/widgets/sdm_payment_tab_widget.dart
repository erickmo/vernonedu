import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab riwayat pembayaran / fee SDM.
class SdmPaymentTabWidget extends StatelessWidget {
  final List<SdmPaymentEntity> payments;

  const SdmPaymentTabWidget({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return _buildEmpty(context);
    }
    final totalPaid = payments
        .where((p) => p.status == SdmPaymentStatus.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(context, totalPaid),
          const SizedBox(height: AppDimensions.lg),
          _buildListHeader(context),
          const SizedBox(height: AppDimensions.md),
          ...payments
              .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                    child: _buildPaymentRow(context, p),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, double totalPaid) => Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.sdmPaymentTotal,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnPrimary.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    _fmtCurrency(totalPaid),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textOnPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${payments.length} transaksi',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textOnPrimary.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.textOnPrimary,
              size: 48,
            ),
          ],
        ),
      );

  Widget _buildListHeader(BuildContext context) => Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              AppStrings.sdmPaymentDescription,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.sdmPaymentType,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.sdmPaymentAmount,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          SizedBox(
            width: 80,
            child: Text(
              AppStrings.sdmPaymentStatus,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );

  Widget _buildPaymentRow(BuildContext context, SdmPaymentEntity payment) =>
      Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (payment.programName != null)
                    Text(
                      payment.programName!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  Text(
                    _fmtDate(payment.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildTypeChip(context, payment.type),
            ),
            Expanded(
              child: Text(
                _fmtCurrency(payment.amount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            SizedBox(
              width: 80,
              child: _buildStatusBadge(context, payment.status),
            ),
          ],
        ),
      );

  Widget _buildTypeChip(BuildContext context, SdmPaymentType type) {
    final label = _typeLabel(type);
    final color = _typeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SdmPaymentStatus status) {
    final color = _statusColor(status);
    final bgColor = _statusBgColor(status);
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                AppStrings.sdmNoPaymentData,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );

  String _typeLabel(SdmPaymentType t) {
    switch (t) {
      case SdmPaymentType.honorarium:
        return 'Honorarium';
      case SdmPaymentType.bonus:
        return 'Bonus';
      case SdmPaymentType.reimbursement:
        return 'Reimburse';
      case SdmPaymentType.other:
        return 'Lainnya';
    }
  }

  Color _typeColor(SdmPaymentType t) {
    switch (t) {
      case SdmPaymentType.honorarium:
        return AppColors.primary;
      case SdmPaymentType.bonus:
        return AppColors.success;
      case SdmPaymentType.reimbursement:
        return AppColors.info;
      case SdmPaymentType.other:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(SdmPaymentStatus s) {
    switch (s) {
      case SdmPaymentStatus.paid:
        return 'Dibayar';
      case SdmPaymentStatus.pending:
        return 'Pending';
      case SdmPaymentStatus.cancelled:
        return 'Batal';
    }
  }

  Color _statusColor(SdmPaymentStatus s) {
    switch (s) {
      case SdmPaymentStatus.paid:
        return AppColors.success;
      case SdmPaymentStatus.pending:
        return AppColors.warning;
      case SdmPaymentStatus.cancelled:
        return AppColors.error;
    }
  }

  Color _statusBgColor(SdmPaymentStatus s) {
    switch (s) {
      case SdmPaymentStatus.paid:
        return AppColors.successSurface;
      case SdmPaymentStatus.pending:
        return AppColors.warningSurface;
      case SdmPaymentStatus.cancelled:
        return AppColors.errorSurface;
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _fmtCurrency(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $formatted';
  }
}
