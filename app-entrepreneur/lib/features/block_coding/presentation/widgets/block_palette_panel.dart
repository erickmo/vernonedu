import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/bc_theme.dart';


import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block_type.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_cubit.dart';

/// Panel palette di sisi kiri/bawah berisi semua blok yang bisa ditambahkan.
class BlockPalettePanel extends StatefulWidget {
  /// Daftar blok yang diperbolehkan. Null = semua blok.
  final List<BlockType>? allowedBlocks;

  const BlockPalettePanel({super.key, this.allowedBlocks});

  @override
  State<BlockPalettePanel> createState() => _BlockPalettePanelState();
}

class _BlockPalettePanelState extends State<BlockPalettePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = BlockCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BcColors.surface,
        border: Border(
          top: BorderSide(color: BcColors.border),
        ),
      ),
      child: Column(
        children: [
          // — Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: BcDimensions.spacingS),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BcColors.border,
                borderRadius: BorderRadius.circular(BcDimensions.radiusFull),
              ),
            ),
          ),

          // — Tab Bar (kategori blok)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: BcColors.primary,
            labelColor: BcColors.textPrimary,
            unselectedLabelColor: BcColors.textHint,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: _categories.map((cat) {
              return Tab(
                height: BcDimensions.paletteCategoryTabHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: BcDimensions.spacingXs),
                    Text(cat.label),
                  ],
                ),
              );
            }).toList(),
          ),

          const Divider(height: 1, color: BcColors.border),

          // — Tab view (daftar blok per kategori)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories
                  .map((cat) => _buildCategoryBlocks(context, cat))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBlocks(BuildContext context, BlockCategory category) {
    final allBlocks = category.blocks;
    final allowed = widget.allowedBlocks;

    final blocks = allowed == null
        ? allBlocks
        : allBlocks.where((t) => allowed.contains(t)).toList();

    if (blocks.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada blok tersedia',
          style: TextStyle(color: BcColors.textHint, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(BcDimensions.spacingS),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        return _PaletteBlockItem(type: blocks[index]);
      },
    );
  }
}

/// Item blok di palette — bisa di-tap untuk menambah ke canvas.
class _PaletteBlockItem extends StatelessWidget {
  final BlockType type;

  const _PaletteBlockItem({required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BlockEditorCubit>().addBlock(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: BcDimensions.paletteItemSpacing),
        padding: const EdgeInsets.symmetric(
          horizontal: BcDimensions.spacingM,
          vertical: BcDimensions.spacingS + 2,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [type.color, type.darkColor],
          ),
          borderRadius: BorderRadius.circular(BcDimensions.blockBorderRadius),
          boxShadow: [
            BoxShadow(
              color: type.color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(type.icon, color: BcColors.textPrimary, size: BcDimensions.iconS),
            const SizedBox(width: BcDimensions.spacingS),
            Expanded(
              child: Text(
                type.label,
                style: const TextStyle(
                  color: BcColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.add_rounded,
              color: BcColors.textPrimary,
              size: BcDimensions.iconXs,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet wrapper untuk palette.
class BlockPaletteBottomSheet extends StatelessWidget {
  final List<BlockType>? allowedBlocks;

  const BlockPaletteBottomSheet({super.key, this.allowedBlocks});

  static Future<void> show(
    BuildContext context,
    BlockEditorCubit cubit, {
    List<BlockType>? allowedBlocks,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: BcColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BcDimensions.radiusL),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: SizedBox(
          height: BcDimensions.paletteBottomSheetHeight,
          child: BlockPalettePanel(allowedBlocks: allowedBlocks),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: BcDimensions.paletteBottomSheetHeight,
      child: BlockPalettePanel(allowedBlocks: allowedBlocks),
    );
  }
}

/// Chip kategori untuk palette header.
class CategoryFilterChip extends StatelessWidget {
  final BlockCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: BcDimensions.spacingM,
          vertical: BcDimensions.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? category.color : BcColors.surfaceVariant,
          borderRadius: BorderRadius.circular(BcDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? category.color : BcColors.border,
          ),
        ),
        child: Text(
          category.label,
          style: TextStyle(
            color: isSelected ? BcColors.textPrimary : BcColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Widget header untuk palette area.
Widget buildPaletteHeader() {
  return const Padding(
    padding: EdgeInsets.all(BcDimensions.spacingM),
    child: Row(
      children: [
        Icon(Icons.widgets_rounded, color: BcColors.primary, size: BcDimensions.iconS),
        SizedBox(width: BcDimensions.spacingS),
        Text(
          BcStrings.editorPalette,
          style: TextStyle(
            color: BcColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
