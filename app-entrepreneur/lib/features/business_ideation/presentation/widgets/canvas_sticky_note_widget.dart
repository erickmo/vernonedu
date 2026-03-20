import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Model untuk item di canvas.
class CanvasItem {
  final String id;
  String text;
  String note;
  bool isExpanded;

  CanvasItem({
    required this.id,
    required this.text,
    this.note = '',
    this.isExpanded = false,
  });

  CanvasItem copyWith({
    String? id,
    String? text,
    String? note,
    bool? isExpanded,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      text: text ?? this.text,
      note: note ?? this.note,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

/// Sticky note widget untuk item di canvas.
///
/// Menampilkan teks utama dengan expandable note section.
/// Tombol X di pojok kanan atas untuk delete.
class CanvasStickyNoteWidget extends StatefulWidget {
  final CanvasItem item;
  final Color backgroundColor;
  final Color borderColor;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onDelete;
  final VoidCallback onExpandToggle;

  const CanvasStickyNoteWidget({
    super.key,
    required this.item,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTextChanged,
    required this.onNoteChanged,
    required this.onDelete,
    required this.onExpandToggle,
  });

  @override
  State<CanvasStickyNoteWidget> createState() => _CanvasStickyNoteWidgetState();
}

class _CanvasStickyNoteWidgetState extends State<CanvasStickyNoteWidget> {
  late final TextEditingController _textController;
  late final TextEditingController _noteController;
  late FocusNode _textFocus;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
    _noteController = TextEditingController(text: widget.item.note);
    _textFocus = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _noteController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: widget.borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan text dan delete button
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _textFocus,
                    onChanged: widget.onTextChanged,
                    maxLines: null,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          if (widget.item.note.isNotEmpty || widget.item.isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS),
              child: Divider(
                height: 8,
                thickness: 0.5,
                color: widget.borderColor,
              ),
            ),

          // Note section
          if (widget.item.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingS,
                0,
                AppDimensions.spacingS,
                AppDimensions.spacingS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _noteController,
                    onChanged: widget.onNoteChanged,
                    maxLines: null,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textLabel,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tambah catatan...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  GestureDetector(
                    onTap: widget.onExpandToggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.expand_less_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Tutup',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (widget.item.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingS,
                0,
                AppDimensions.spacingS,
                AppDimensions.spacingS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.textLabel,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  GestureDetector(
                    onTap: widget.onExpandToggle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.expand_more_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Lihat',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingS,
                0,
                AppDimensions.spacingS,
                AppDimensions.spacingS,
              ),
              child: GestureDetector(
                onTap: widget.onExpandToggle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.note_add_rounded,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Catatan',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
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
