import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../cubit/sdm_detail_cubit.dart';
import '../cubit/sdm_detail_state.dart';
import '../widgets/sdm_profile_header_widget.dart';
import '../widgets/sdm_cv_tab_widget.dart';
import '../widgets/sdm_program_tab_widget.dart';
import '../widgets/sdm_class_history_tab_widget.dart';
import '../widgets/sdm_payment_tab_widget.dart';
import '../widgets/sdm_evaluation_tab_widget.dart';
import '../widgets/sdm_schedule_tab_widget.dart';
import '../widgets/sdm_documents_tab_widget.dart';

/// Halaman detail lengkap SDM dengan tab — CV, Program, Kelas, Pembayaran,
/// Evaluasi, Jadwal, Dokumen.
class SdmDetailPage extends StatelessWidget {
  final String sdmId;

  const SdmDetailPage({super.key, required this.sdmId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SdmDetailCubit>()..loadDetail(sdmId),
      child: const _SdmDetailView(),
    );
  }
}

class _SdmDetailView extends StatelessWidget {
  const _SdmDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SdmDetailCubit, SdmDetailState>(
      builder: (context, state) {
        if (state is SdmDetailLoading || state is SdmDetailInitial) {
          return _buildLoading(context);
        }
        if (state is SdmDetailError) {
          return _buildError(context, state.message);
        }
        if (state is SdmDetailLoaded) {
          return _SdmDetailContent(detail: state.detail);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoading(BuildContext context) => Column(
        children: [
          _buildTopBar(context, AppStrings.sdmDetailLoading),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );

  Widget _buildError(BuildContext context, String message) => Column(
        children: [
          _buildTopBar(context, AppStrings.sdmDetail),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<SdmDetailCubit>()
                        .loadDetail(
                            (context.read<SdmDetailCubit>().state
                                    as SdmDetailError)
                                .message),
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildTopBar(BuildContext context, String title) => Container(
        height: 56,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
              color: AppColors.textPrimary,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppDimensions.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      );
}

class _SdmDetailContent extends StatefulWidget {
  final dynamic detail;

  const _SdmDetailContent({required this.detail});

  @override
  State<_SdmDetailContent> createState() => _SdmDetailContentState();
}

class _SdmDetailContentState extends State<_SdmDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (Icons.person_outlined, 'CV & Resume'),
    (Icons.layers_outlined, 'Program'),
    (Icons.class_outlined, 'Riwayat Kelas'),
    (Icons.receipt_long_outlined, 'Pembayaran'),
    (Icons.rate_review_outlined, 'Evaluasi'),
    (Icons.calendar_month_outlined, 'Jadwal'),
    (Icons.folder_outlined, 'Dokumen'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return Column(
      children: [
        _buildTopBar(context, detail.name),
        SdmProfileHeaderWidget(detail: detail),
        _buildTabBar(context),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SdmCvTabWidget(resume: detail.resume),
              SdmProgramTabWidget(programs: detail.programs),
              SdmClassHistoryTabWidget(classHistory: detail.classHistory),
              SdmPaymentTabWidget(payments: detail.paymentHistory),
              SdmEvaluationTabWidget(evaluations: detail.evaluations),
              SdmScheduleTabWidget(schedules: detail.schedules),
              SdmDocumentsTabWidget(documents: detail.documents),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, String name) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
              color: AppColors.textPrimary,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppDimensions.xs),
            Expanded(
              child: Row(
                children: [
                  Text(
                    AppStrings.navHrm,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.xs),
                    child: Icon(
                      Icons.chevron_right,
                      size: AppDimensions.iconSm,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildTabBar(BuildContext context) => Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _tabs
              .map((t) => Tab(
                    child: Row(
                      children: [
                        Icon(t.$1, size: AppDimensions.iconSm),
                        const SizedBox(width: AppDimensions.xs),
                        Text(t.$2),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );
}
