import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

export '../../../accounting/presentation/pages/transaction_page.dart'
    show TransactionPage;
export '../../../accounting/presentation/pages/transaction_form_page.dart'
    show TransactionFormPage;
export '../../../accounting/presentation/pages/chart_of_accounts_page.dart'
    show ChartOfAccountsPage;
export '../../../accounting/presentation/pages/journal_page.dart'
    show JournalPage;

export '../../../finance_reports/presentation/pages/report_navigation_page.dart'
    show ReportNavigationPage;
export '../../../finance_reports/presentation/pages/balance_sheet_page.dart'
    show BalanceSheetPage;
export '../../../finance_reports/presentation/pages/profit_loss_page.dart'
    show ProfitLossPage;
export '../../../finance_reports/presentation/pages/cash_flow_page.dart'
    show CashFlowPage;
export '../../../finance_reports/presentation/pages/ledger_page.dart'
    show GeneralLedgerPage;
export '../../../finance_reports/presentation/pages/trial_balance_page.dart'
    show TrialBalancePage;

export '../../../payable/presentation/pages/payable_page.dart' show PayablePage;
export '../../../finance_invoices/presentation/pages/invoice_page.dart'
    show InvoicePage;
export '../../../finance_analysis/presentation/pages/financial_analysis_page.dart'
    show FinancialAnalysisPage;

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ComingSoonPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction_outlined,
                      size: 64, color: AppColors.textHint),
                  SizedBox(height: AppDimensions.md),
                  Text(
                    'Sedang dalam pengembangan',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: AppDimensions.sm),
                  Text(
                    'Fitur ini akan segera tersedia di versi berikutnya.',
                    style: TextStyle(fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
