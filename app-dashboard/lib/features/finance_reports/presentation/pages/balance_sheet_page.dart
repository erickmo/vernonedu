import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/balance_sheet_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../cubit/balance_sheet_cubit.dart';
import '../widgets/expandable_account_section.dart';
import '../widgets/report_filter_bar.dart';

class BalanceSheetPage extends StatelessWidget {
  const BalanceSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BalanceSheetCubit>()..load(),
      child: const _BalanceSheetView(),
    );
  }
}

class _BalanceSheetView extends StatelessWidget {
  const _BalanceSheetView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Neraca Keuangan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Posisi keuangan perusahaan per periode',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.md),
          BlocBuilder<BalanceSheetCubit, BalanceSheetState>(
            builder: (context, state) {
              return ReportFilterBar(
                initialFilter: state is BalanceSheetLoaded
                    ? state.filter
                    : const ReportFilterEntity(),
                onFilterChanged: (filter) =>
                    context.read<BalanceSheetCubit>().load(filter: filter),
              );
            },
          ),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: BlocBuilder<BalanceSheetCubit, BalanceSheetState>(
              builder: (context, state) {
                if (state is BalanceSheetLoading || state is BalanceSheetInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is BalanceSheetError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppDimensions.sm),
                        Text(state.message,
                            style:
                                const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: AppDimensions.md),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<BalanceSheetCubit>().load(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is BalanceSheetLoaded) {
                  return _BalanceSheetContent(data: state.data);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSheetContent extends StatelessWidget {
  final BalanceSheetEntity data;
  const _BalanceSheetContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column — Aset
              Expanded(
                child: _ColumnPanel(
                  title: 'ASET',
                  titleColor: AppColors.primary,
                  child: ListView(
                    children: data.assetSections
                        .map((s) => ExpandableAccountSection(
                              sectionName: s.name,
                              total: s.total,
                              accounts: s.accounts,
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              // Right column — Kewajiban & Ekuitas
              Expanded(
                child: _ColumnPanel(
                  title: 'KEWAJIBAN & EKUITAS',
                  titleColor: AppColors.secondary,
                  child: ListView(
                    children: [
                      ...data.liabilitySections.map((s) =>
                          ExpandableAccountSection(
                            sectionName: s.name,
                            total: s.total,
                            accounts: s.accounts,
                            headerColor: const Color(0xFFE8F5E9),
                          )),
                      ...data.equitySections.map((s) => ExpandableAccountSection(
                            sectionName: s.name,
                            total: s.total,
                            accounts: s.accounts,
                            headerColor: const Color(0xFFF3E5F5),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        // Footer summary
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg, vertical: AppDimensions.md),
          decoration: BoxDecoration(
            color: data.isBalanced ? AppColors.successSurface : AppColors.errorSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: data.isBalanced ? AppColors.success : AppColors.error,
            ),
          ),
          child: Row(
            children: [
              Icon(
                data.isBalanced ? Icons.check_circle : Icons.cancel,
                color: data.isBalanced ? AppColors.success : AppColors.error,
                size: AppDimensions.iconLg,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Row(
                  children: [
                    Text('Total Aset: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(fmt.format(data.totalAssets),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary)),
                    const SizedBox(width: AppDimensions.xl),
                    Text('Total Kewajiban + Ekuitas: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(fmt.format(data.totalLiabilitiesAndEquity),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.secondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: data.isBalanced ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: Text(
                  data.isBalanced ? '✓ Seimbang' : '✗ Tidak Seimbang',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColumnPanel extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget child;

  const _ColumnPanel({
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.sm, horizontal: AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusMd),
              topRight: Radius.circular(AppDimensions.radiusMd),
            ),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.8,
              color: titleColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusMd),
                bottomRight: Radius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusMd),
                bottomRight: Radius.circular(AppDimensions.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
