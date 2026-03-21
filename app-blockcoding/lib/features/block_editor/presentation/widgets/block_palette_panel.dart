import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_dimensions.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block_type.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_cubit.dart';

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
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // — Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),

          // — Tab Bar (kategori blok)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textHint,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: _categories.map((cat) {
              return Tab(
                height: AppDimensions.paletteCategoryTabHeight,
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
                    const SizedBox(width: AppDimensions.spacingXs),
                    Text(cat.label),
                  ],
                ),
              );
            }).toList(),
          ),

          const Divider(height: 1, color: AppColors.border),

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
          style: TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingS),
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
        margin: const EdgeInsets.only(bottom: AppDimensions.paletteItemSpacing),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS + 2,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [type.color, type.darkColor],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.blockBorderRadius),
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
            Icon(type.icon, color: AppColors.textPrimary, size: AppDimensions.iconS),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                type.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.add_rounded,
              color: AppColors.textPrimary,
              size: AppDimensions.iconXs,
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
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: SizedBox(
          height: AppDimensions.paletteBottomSheetHeight,
          child: BlockPalettePanel(allowedBlocks: allowedBlocks),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.paletteBottomSheetHeight,
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
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingXs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? category.color : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? category.color : AppColors.border,
          ),
        ),
        child: Text(
          category.label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
    padding: EdgeInsets.all(AppDimensions.spacingM),
    child: Row(
      children: [
        Icon(Icons.widgets_rounded, color: AppColors.primary, size: AppDimensions.iconS),
        SizedBox(width: AppDimensions.spacingS),
        Text(
          AppStrings.editorPalette,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
