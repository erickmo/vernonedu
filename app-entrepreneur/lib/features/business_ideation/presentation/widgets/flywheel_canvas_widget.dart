import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'canvas_section_widget.dart';
import 'canvas_sticky_note_widget.dart';

/// Flywheel Marketing Canvas widget.
///
/// 3 main cards (Attract, Engage, Delight) + 2 support cards (Friction, Force)
/// Desktop: arrange in flywheel hint atau card layout
/// Mobile: vertical list
class FlywheelCanvasWidget extends StatelessWidget {
  final Map<String, List<CanvasItem>> sectionItems;
  final OnItemUpdate onItemUpdate;
  final OnItemDelete onItemDelete;
  final OnAddItem onAddItem;
  final ScrollController? scrollController;
  final Map<String, GlobalKey> sectionKeys;

  const FlywheelCanvasWidget({
    super.key,
    required this.sectionItems,
    required this.onItemUpdate,
    required this.onItemDelete,
    required this.onAddItem,
    this.scrollController,
    required this.sectionKeys,
  });

  String _getSectionTitle(String stageId) {
    const titles = {
      'attract': 'Attract',
      'engage': 'Engage',
      'delight': 'Delight',
      'friction-points': 'Friction Points',
      'force-accelerators': 'Force (Accelerators)',
    };
    return titles[stageId] ?? stageId;
  }

  Color _getSectionColor(String stageId) {
    const colors = {
      'attract': Color(0xFF0168FA),
      'engage': Color(0xFF10B759),
      'delight': Color(0xFFFF6F00),
      'friction-points': Color(0xFFDC3545),
      'force-accelerators': Color(0xFF9C27B0),
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
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingL),
            child: Text(
              'Flywheel Marketing: Attract → Engage → Delight',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Main 3 stages: Attract, Engage, Delight
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildSection('attract'),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildSection('engage'),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildSection('delight'),
                ),
              ),
            ],
          ),

          // Support stages: Friction Points, Force (Accelerators)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppColors.divider,
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildSection('friction-points'),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  child: _buildSection('force-accelerators'),
                ),
              ),
              // Empty space to maintain 3-column grid
              Expanded(
                child: Container(),
              ),
            ],
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
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Text(
              'Flywheel Marketing',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Sections
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: _buildSection('attract'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: _buildSection('engage'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: _buildSection('delight'),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: _buildSection('friction-points'),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: _buildSection('force-accelerators'),
          ),
        ],
      ),
    );
  }
}
