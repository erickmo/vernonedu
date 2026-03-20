import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'canvas_sticky_note_widget.dart';

typedef OnItemUpdate = Function(CanvasItem updatedItem);
typedef OnItemDelete = Function(String itemId);
typedef OnAddItem = Function(String sectionId);

/// Section widget untuk canvas layout.
///
/// Menampilkan:
/// - Title dan linked section chips
/// - Wrap of sticky notes
/// - Tombol + untuk tambah item
class CanvasSectionWidget extends StatefulWidget {
  final String title;
  final String sectionId;
  final Color color;
  final List<CanvasItem> items;
  final List<({String label, VoidCallback onTap})> linkedSections;
  final OnItemUpdate onItemUpdate;
  final OnItemDelete onItemDelete;
  final OnAddItem onAddItem;
  final bool isCompact;

  const CanvasSectionWidget({
    super.key,
    required this.title,
    required this.sectionId,
    required this.color,
    required this.items,
    required this.linkedSections,
    required this.onItemUpdate,
    required this.onItemDelete,
    required this.onAddItem,
    this.isCompact = false,
  });

  @override
  State<CanvasSectionWidget> createState() => _CanvasSectionWidgetState();
}

class _CanvasSectionWidgetState extends State<CanvasSectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title dengan indikator warna
        if (!widget.isCompact)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Linked sections chips (jika ada)
        if (widget.linkedSections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Wrap(
              spacing: AppDimensions.spacingS,
              children: [
                Text(
                  '🔗',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                ...widget.linkedSections.map((linked) {
                  return GestureDetector(
                    onTap: linked.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.3),
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            linked.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: widget.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 10,
                            color: widget.color,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

        // Items wrap
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            ...widget.items.map((item) {
              return CanvasStickyNoteWidget(
                item: item,
                backgroundColor: widget.color.withValues(alpha: 0.08),
                borderColor: widget.color.withValues(alpha: 0.3),
                onTextChanged: (newText) {
                  widget.onItemUpdate(item.copyWith(text: newText));
                },
                onNoteChanged: (newNote) {
                  widget.onItemUpdate(item.copyWith(note: newNote));
                },
                onDelete: () => widget.onItemDelete(item.id),
                onExpandToggle: () {
                  widget.onItemUpdate(
                    item.copyWith(isExpanded: !item.isExpanded),
                  );
                },
              );
            }),

            // Add button
            GestureDetector(
              onTap: () => widget.onAddItem(widget.sectionId),
              child: Container(
                width: 160,
                height: 120,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onAddItem(widget.sectionId),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: widget.color,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tambah Item',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: widget.color,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
