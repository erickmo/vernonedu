import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/business_entity.dart';
import '../cubit/business_cubit.dart';
import '../cubit/business_state.dart';
import '../widgets/business_card_widget.dart';

/// Local UI data model untuk satu bisnis — menggabungkan BusinessEntity
/// dengan WorksheetStatus yang merupakan UI concern saja.
class Business {
  final String id;
  final String name;
  final DateTime createdAt;
  final Map<String, WorksheetStatus> worksheets;

  const Business({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.worksheets,
  });

  int get completedCount =>
      worksheets.values.where((s) => s == WorksheetStatus.completed).length;

  int get totalWorksheets => worksheets.length;

  double get progress =>
      totalWorksheets > 0 ? completedCount / totalWorksheets : 0.0;

  factory Business.fromEntity(BusinessEntity entity) {
    return Business(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      worksheets: {
        'pestel': WorksheetStatus.notStarted,
        'design-thinking': WorksheetStatus.notStarted,
        'value-proposition': WorksheetStatus.notStarted,
        'business-model-canvas': WorksheetStatus.notStarted,
        'flywheel-marketing': WorksheetStatus.notStarted,
      },
    );
  }
}

enum WorksheetStatus { notStarted, inProgress, completed }

/// Business Ideation page — list bisnis milik user.
/// User bisa membuat bisnis baru (auto-numbered: Bisnis 001, 002, ...).
class BusinessIdeationPage extends StatelessWidget {
  const BusinessIdeationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BusinessCubit, BusinessState>(
      listener: (context, state) {
        if (state is BusinessError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                onCreateBusiness: () =>
                    _showCreateBusinessDialog(context, state),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              if (state is BusinessLoading)
                const _LoadingWidget()
              else if (state is BusinessLoaded && state.businesses.isEmpty)
                _EmptyState(
                  onCreateBusiness: () =>
                      _showCreateBusinessDialog(context, state),
                )
              else if (state is BusinessLoaded)
                _BusinessList(businesses: state.businesses)
              else if (state is BusinessError)
                _ErrorWidget(
                  message: state.message,
                  onRetry: () =>
                      context.read<BusinessCubit>().getBusinesses(),
                )
              else
                const _LoadingWidget(),
            ],
          ),
        );
      },
    );
  }

  void _showCreateBusinessDialog(BuildContext context, BusinessState state) {
    final existingCount = state is BusinessLoaded ? state.businesses.length : 0;
    final number = (existingCount + 1).toString().padLeft(3, '0');
    final nameController = TextEditingController(text: 'Bisnis $number');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Buat Bisnis Baru',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Bisnis'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<BusinessCubit>().createBusiness(name: name);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final VoidCallback onCreateBusiness;

  const _PageHeader({required this.onCreateBusiness});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Ideation',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                'Buat dan kembangkan ide bisnis kamu melalui 5 tahapan worksheet.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        ElevatedButton.icon(
          onPressed: onCreateBusiness,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(
            'Bisnis Baru',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ],
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade400),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateBusiness;

  const _EmptyState({required this.onCreateBusiness});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'Belum ada bisnis',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'Mulai perjalanan entrepreneurship kamu\ndengan membuat bisnis pertama!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ElevatedButton.icon(
              onPressed: onCreateBusiness,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Buat Bisnis Pertama',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessList extends StatelessWidget {
  final List<BusinessEntity> businesses;

  const _BusinessList({required this.businesses});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.spacingM,
        crossAxisSpacing: AppDimensions.spacingM,
        childAspectRatio: isDesktop ? 1.3 : (isTablet ? 1.2 : 1.8),
      ),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        final business = Business.fromEntity(businesses[index]);
        return BusinessCardWidget(
          business: business,
          onTap: () {
            context.go('/business-ideation/${businesses[index].id}');
          },
        );
      },
    );
  }
}
