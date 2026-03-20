import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'canvas_section_widget.dart';
import 'canvas_sticky_note_widget.dart';

/// Business Model Canvas widget — 9 blok layout.
///
/// Layout desktop:
/// ┌─────┬─────────┬──────────┬──────────┬─────────┐
/// │ KP  │  KA     │   VP     │  CR      │  CS     │
/// │     │  KR     │          │  C       │         │
/// └─────┴─────────┴──────────┴──────────┴─────────┘
/// ┌───────────────────────────────────────────────┐
/// │      Cost Structure    │    Revenue Streams   │
/// └───────────────────────────────────────────────┘
///
/// Sections:
/// - Key Partners (KP) - kiri atas
/// - Key Activities (KA) - tengah atas
/// - Value Propositions (VP) - center
/// - Customer Relationships (CR) - kanan atas
/// - Customer Segments (CS) - far right
/// - Key Resources (KR) - bawah KA
/// - Channels (C) - bawah CR
/// - Cost Structure (CS) - bawah kiri
/// - Revenue Streams (RS) - bawah kanan
class BMCCanvasWidget extends StatelessWidget {
  final Map<String, List<CanvasItem>> sectionItems;
  final OnItemUpdate onItemUpdate;
  final OnItemDelete onItemDelete;
  final OnAddItem onAddItem;
  final ScrollController? scrollController;
  final Map<String, GlobalKey> sectionKeys;

  const BMCCanvasWidget({
    super.key,
    required this.sectionItems,
    required this.onItemUpdate,
    required this.onItemDelete,
    required this.onAddItem,
    this.scrollController,
    required this.sectionKeys,
  });

  static const _bmcLinks = {
    'channels': ['customer-segments', 'value-propositions'],
    'customer-relationships': ['customer-segments'],
    'revenue-streams': ['customer-segments', 'value-propositions'],
    'key-activities': ['value-propositions', 'key-resources'],
    'key-resources': ['key-activities'],
    'key-partnerships': ['key-activities', 'key-resources'],
    'cost-structure': ['key-activities', 'key-resources'],
    'customer-segments': ['value-propositions'],
    'value-propositions': ['customer-segments'],
  };

  List<({String label, VoidCallback onTap})> _getLinkedSections(
    String sectionId,
  ) {
    final linkedIds = _bmcLinks[sectionId] ?? [];
    return linkedIds
        .map((linkedId) {
          final sectionKey = sectionKeys[linkedId];
          return (
            label: _getSectionTitle(linkedId),
            onTap: sectionKey != null
                ? () => _scrollToSection(linkedId)
                : () {},
          );
        })
        .toList();
  }

  void _scrollToSection(String sectionId) {
    final key = sectionKeys[sectionId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  String _getSectionTitle(String sectionId) {
    const titles = {
      'customer-segments': 'Customer Segments',
      'value-propositions': 'Value Propositions',
      'channels': 'Channels',
      'customer-relationships': 'Customer Relationships',
      'revenue-streams': 'Revenue Streams',
      'key-resources': 'Key Resources',
      'key-activities': 'Key Activities',
      'key-partnerships': 'Key Partnerships',
      'cost-structure': 'Cost Structure',
    };
    return titles[sectionId] ?? sectionId;
  }

  Color _getSectionColor(String sectionId) {
    const colors = {
      'customer-segments': Color(0xFF10B759),
      'value-propositions': Color(0xFFFF6F00),
      'channels': Color(0xFF0168FA),
      'customer-relationships': Color(0xFF9C27B0),
      'revenue-streams': Color(0xFF00BCD4),
      'key-resources': Color(0xFFFF5722),
      'key-activities': Color(0xFF673AB7),
      'key-partnerships': Color(0xFFFFC107),
      'cost-structure': Color(0xFFE91E63),
    };
    return colors[sectionId] ?? AppColors.primary;
  }

  Widget _buildSection(
    String sectionId,
    BuildContext context,
  ) {
    final items = sectionItems[sectionId] ?? [];
    final color = _getSectionColor(sectionId);
    final linkedSections = _getLinkedSections(sectionId);

    return Container(
      key: sectionKeys[sectionId],
      child: CanvasSectionWidget(
        sectionId: sectionId,
        title: _getSectionTitle(sectionId),
        color: color,
        items: items,
        linkedSections: linkedSections,
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
      return _buildMobileLayout(context);
    }

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          // Header
          _buildCanvasHeader(),
          const SizedBox(height: AppDimensions.spacingL),

          // Top row: KP, KA, VP, CR, CS
          Container(
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Partnerships (left)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.divider,
                            width: 2,
                          ),
                        ),
                      ),
                      child: _buildSection('key-partnerships', context),
                    ),
                  ),

                  // Key Activities + Key Resources (center-left)
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.divider,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                                AppDimensions.spacingM),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.divider,
                                  width: 2,
                                ),
                              ),
                            ),
                            child:
                                _buildSection('key-activities', context),
                          ),
                          Container(
                            padding: const EdgeInsets.all(
                                AppDimensions.spacingM),
                            child: _buildSection('key-resources', context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Value Propositions (center) — highlight
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6F00).withValues(alpha: 0.03),
                        border: Border(
                          right: BorderSide(
                            color: AppColors.divider,
                            width: 2,
                          ),
                        ),
                      ),
                      child: _buildSection('value-propositions', context),
                    ),
                  ),

                  // Customer Relationships + Channels (center-right)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.divider,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                                AppDimensions.spacingM),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.divider,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: _buildSection(
                                'customer-relationships', context),
                          ),
                          Container(
                            padding: const EdgeInsets.all(
                                AppDimensions.spacingM),
                            child: _buildSection('channels', context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Customer Segments (right)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      color: AppColors.surface,
                      child: _buildSection('customer-segments', context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // Bottom row: Cost Structure, Revenue Streams
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimensions.radiusM),
                      topLeft: Radius.circular(AppDimensions.radiusM),
                    ),
                    border: Border.all(color: AppColors.divider, width: 2),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSection('cost-structure', context),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(AppDimensions.radiusM),
                      topRight: Radius.circular(AppDimensions.radiusM),
                    ),
                    border: Border.all(color: AppColors.divider, width: 2),
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSection('revenue-streams', context),
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
            const Color(0xFFFF6F00).withValues(alpha: 0.1),
            const Color(0xFFFF6F00).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: const Color(0xFFFF6F00).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Model Canvas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '9 building blocks untuk merancang model bisnis yang sustainable',
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

  Widget _buildMobileLayout(BuildContext context) {
    final sectionIds = [
      'customer-segments',
      'value-propositions',
      'channels',
      'customer-relationships',
      'revenue-streams',
      'key-resources',
      'key-activities',
      'key-partnerships',
      'cost-structure',
    ];

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          ...sectionIds.map((sectionId) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: _buildSection(sectionId, context),
            );
          }),
        ],
      ),
    );
  }
}
