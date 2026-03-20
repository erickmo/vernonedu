import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'canvas_section_widget.dart';
import 'canvas_sticky_note_widget.dart';

/// Design Thinking Canvas widget — 5-tahap linear layout.
///
/// [Empathize] → [Define] → [Ideate] → [Prototype] → [Test]
///
/// Desktop: horizontal dengan panah penghubung
/// Mobile: vertical dengan panah bawah
class DTCanvasWidget extends StatelessWidget {
  final Map<String, List<CanvasItem>> sectionItems;
  final OnItemUpdate onItemUpdate;
  final OnItemDelete onItemDelete;
  final OnAddItem onAddItem;
  final ScrollController? scrollController;
  final Map<String, GlobalKey> sectionKeys;

  const DTCanvasWidget({
    super.key,
    required this.sectionItems,
    required this.onItemUpdate,
    required this.onItemDelete,
    required this.onAddItem,
    this.scrollController,
    required this.sectionKeys,
  });

  static const _stages = [
    'empathize',
    'define',
    'ideate',
    'prototype',
    'test',
  ];

  String _getSectionTitle(String stageId) {
    const titles = {
      'empathize': 'Empathize',
      'define': 'Define',
      'ideate': 'Ideate',
      'prototype': 'Prototype',
      'test': 'Test',
    };
    return titles[stageId] ?? stageId;
  }

  Color _getSectionColor(String stageId) {
    const colors = {
      'empathize': Color(0xFF0168FA),
      'define': Color(0xFF10B759),
      'ideate': Color(0xFFFF6F00),
      'prototype': Color(0xFF9C27B0),
      'test': Color(0xFFDC3545),
    };
    return colors[stageId] ?? AppColors.primary;
  }

  Widget _buildSection(String stageId) {
    final items = sectionItems[stageId] ?? [];
    final color = _getSectionColor(stageId);

    return Container(
      key: sectionKeys[stageId],
      child: CanvasSectionWidget(
        sectionId: stageId,
        title: _getSectionTitle(stageId),
        color: color,
        items: items,
        linkedSections: const [],
        onItemUpdate: onItemUpdate,
        onItemDelete: onItemDelete,
        onAddItem: onAddItem,
        isCompact: true,
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

          // Horizontal stages dengan panah
          SizedBox(
            height: 420,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._stages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stageId = entry.value;
                  final isLast = index == _stages.length - 1;
                  final color = _getSectionColor(stageId);

                  return Expanded(
                    child: Column(
                      children: [
                        // Stage section dengan container
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(
                              left: AppDimensions.spacingS,
                              right: AppDimensions.spacingS,
                            ),
                            padding: const EdgeInsets.all(
                                AppDimensions.spacingM),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              color: color.withValues(alpha: 0.02),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildSection(stageId),
                          ),
                        ),

                        // Arrow ke stage berikutnya
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.spacingM,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.divider,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
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
            const Color(0xFF0168FA).withValues(alpha: 0.1),
            const Color(0xFF0168FA).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: const Color(0xFF0168FA).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design Thinking Framework',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Framework inovasi 5-tahap untuk memahami masalah dan merancang solusi yang user-centric',
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
          ..._stages.asMap().entries.map((entry) {
            final index = entry.key;
            final stageId = entry.value;
            final isLast = index == _stages.length - 1;

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: _buildSection(stageId),
                ),
                if (!isLast)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingS,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: AppColors.divider,
                      size: 24,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
