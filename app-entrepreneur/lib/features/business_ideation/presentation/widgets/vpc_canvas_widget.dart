import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'canvas_section_widget.dart';
import 'canvas_sticky_note_widget.dart';

/// Value Proposition Canvas widget — 2-sisi layout.
///
/// Kiri: Value Map
///   - Products & Services (tengah)
///   - Pain Relievers (kiri)
///   - Gain Creators (kanan)
///
/// Kanan: Customer Profile
///   - Customer Jobs (tengah atas)
///   - Pains (kiri bawah)
///   - Gains (kanan bawah)
class VPCCanvasWidget extends StatelessWidget {
  final Map<String, List<CanvasItem>> sectionItems;
  final OnItemUpdate onItemUpdate;
  final OnItemDelete onItemDelete;
  final OnAddItem onAddItem;
  final ScrollController? scrollController;
  final Map<String, GlobalKey> sectionKeys;

  const VPCCanvasWidget({
    super.key,
    required this.sectionItems,
    required this.onItemUpdate,
    required this.onItemDelete,
    required this.onAddItem,
    this.scrollController,
    required this.sectionKeys,
  });

  String _getSectionTitle(String sectionId) {
    const titles = {
      'customer-jobs': 'Customer Jobs',
      'pains': 'Pains',
      'gains': 'Gains',
      'products-services': 'Products & Services',
      'pain-relievers': 'Pain Relievers',
      'gain-creators': 'Gain Creators',
    };
    return titles[sectionId] ?? sectionId;
  }

  Color _getSectionColor(String sectionId) {
    const colors = {
      'customer-jobs': Color(0xFF10B759),
      'pains': Color(0xFFDC3545),
      'gains': Color(0xFF10B759),
      'products-services': Color(0xFFFF6F00),
      'pain-relievers': Color(0xFF0168FA),
      'gain-creators': Color(0xFFFFB300),
    };
    return colors[sectionId] ?? AppColors.primary;
  }

  Widget _buildSection(String sectionId) {
    final items = sectionItems[sectionId] ?? [];
    final color = _getSectionColor(sectionId);

    return Container(
      key: sectionKeys[sectionId],
      child: CanvasSectionWidget(
        sectionId: sectionId,
        title: _getSectionTitle(sectionId),
        color: color,
        items: items,
        linkedSections: const [],
        onItemUpdate: onItemUpdate,
        onItemDelete: onItemDelete,
        onAddItem: onAddItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    if (!isDesktop) {
      return _buildMobileLayout();
    }

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          // Header
          _buildCanvasHeader(),
          const SizedBox(height: AppDimensions.spacingL),

          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Value Map
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.divider, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                              AppDimensions.spacingM),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F00)
                                .withValues(alpha: 0.08),
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '💡 Value Map',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(
                              AppDimensions.spacingM),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pain Relievers (kiri)
                              Expanded(
                                child: _buildSection('pain-relievers'),
                              ),
                              const SizedBox(width: AppDimensions.spacingM),
                              // Products & Services (tengah)
                              Expanded(
                                child: _buildSection('products-services'),
                              ),
                              const SizedBox(width: AppDimensions.spacingM),
                              // Gain Creators (kanan)
                              Expanded(
                                child: _buildSection('gain-creators'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.spacingL),

              // RIGHT: Customer Profile
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.divider, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                              AppDimensions.spacingM),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B759)
                                .withValues(alpha: 0.08),
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            '👤 Customer Profile',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(
                              AppDimensions.spacingM),
                          child: Column(
                            children: [
                              // Customer Jobs (tengah atas)
                              Container(
                                margin: const EdgeInsets.only(
                                    bottom: AppDimensions.spacingM),
                                child: _buildSection('customer-jobs'),
                              ),
                              // Pains (kiri) + Gains (kanan)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildSection('pains'),
                                  ),
                                  const SizedBox(
                                      width: AppDimensions.spacingM),
                                  Expanded(
                                    child: _buildSection('gains'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B759).withValues(alpha: 0.1),
            const Color(0xFF10B759).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: const Color(0xFF10B759).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Value Proposition Canvas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pemetaan kecocokan antara value yang kamu tawarkan dengan customer needs',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          // Value Map section
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Value Map',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildSection('pain-relievers'),
                const SizedBox(height: AppDimensions.spacingM),
                _buildSection('products-services'),
                const SizedBox(height: AppDimensions.spacingM),
                _buildSection('gain-creators'),
              ],
            ),
          ),

          // Customer Profile section
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Profile',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildSection('customer-jobs'),
                const SizedBox(height: AppDimensions.spacingM),
                _buildSection('pains'),
                const SizedBox(height: AppDimensions.spacingM),
                _buildSection('gains'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
