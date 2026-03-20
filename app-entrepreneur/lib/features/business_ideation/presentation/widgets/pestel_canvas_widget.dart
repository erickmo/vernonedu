import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'canvas_section_widget.dart';
import 'canvas_sticky_note_widget.dart';

/// PESTEL Analysis Canvas widget — 3x2 grid layout.
///
/// [Political]      [Economic]       [Social]
/// [Technological]  [Environmental]  [Legal]
///
/// Desktop: 3x2 grid
/// Mobile: 1 kolom vertical
class PestelCanvasWidget extends StatelessWidget {
  final Map<String, List<CanvasItem>> sectionItems;
  final OnItemUpdate onItemUpdate;
  final OnItemDelete onItemDelete;
  final OnAddItem onAddItem;
  final ScrollController? scrollController;
  final Map<String, GlobalKey> sectionKeys;

  const PestelCanvasWidget({
    super.key,
    required this.sectionItems,
    required this.onItemUpdate,
    required this.onItemDelete,
    required this.onAddItem,
    this.scrollController,
    required this.sectionKeys,
  });

  static const _categories = [
    'political',
    'economic',
    'social',
    'technological',
    'environmental',
    'legal',
  ];

  String _getSectionTitle(String categoryId) {
    const titles = {
      'political': 'Political',
      'economic': 'Economic',
      'social': 'Social',
      'technological': 'Technological',
      'environmental': 'Environmental',
      'legal': 'Legal',
    };
    return titles[categoryId] ?? categoryId;
  }

  Color _getSectionColor(String categoryId) {
    const colors = {
      'political': Color(0xFF4D2975),
      'economic': Color(0xFFFF6F00),
      'social': Color(0xFF10B759),
      'technological': Color(0xFF0168FA),
      'environmental': Color(0xFF00BCD4),
      'legal': Color(0xFFDC3545),
    };
    return colors[categoryId] ?? AppColors.primary;
  }

  Widget _buildSection(String categoryId) {
    final items = sectionItems[categoryId] ?? [];
    final color = _getSectionColor(categoryId);

    return Container(
      key: sectionKeys[categoryId],
      child: CanvasSectionWidget(
        sectionId: categoryId,
        title: _getSectionTitle(categoryId),
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
          // Row 1: Political, Economic, Social
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
                  child: _buildSection('political'),
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
                  child: _buildSection('economic'),
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
                  child: _buildSection('social'),
                ),
              ),
            ],
          ),

          // Row 2: Technological, Environmental, Legal
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
                  child: _buildSection('technological'),
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
                    ),
                  ),
                  child: _buildSection('environmental'),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  child: _buildSection('legal'),
                ),
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
          ..._categories.map((categoryId) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: _buildSection(categoryId),
            );
          }),
        ],
      ),
    );
  }
}
