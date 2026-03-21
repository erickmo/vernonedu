import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/bc_theme.dart';


import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block_type.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_state.dart';

/// Widget untuk menampilkan satu blok di canvas, termasuk blok anak.
class CanvasBlockWidget extends StatelessWidget {
  final Block block;
  final bool isSelected;
  final bool isExecuting;
  final int depth;

  const CanvasBlockWidget({
    super.key,
    required this.block,
    this.isSelected = false,
    this.isExecuting = false,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainBlock(context),
        if (block.type.hasBody) _buildBodySection(context),
      ],
    );
  }

  Widget _buildMainBlock(BuildContext context) {
    final color = block.type.color;
    final darkColor = block.type.darkColor;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(
          left: depth * BcDimensions.blockIndent,
          bottom: BcDimensions.canvasBlockSpacing,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, darkColor],
          ),
          borderRadius: BorderRadius.circular(BcDimensions.blockBorderRadius),
          border: isSelected
              ? Border.all(color: BcColors.textPrimary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isExecuting ? 0.8 : 0.3),
              blurRadius: isExecuting ? 16 : BcDimensions.blockShadowBlur,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BcDimensions.spacingM,
            vertical: BcDimensions.spacingS,
          ),
          child: _buildBlockContent(context),
        ),
      ),
    );
  }

  Widget _buildBlockContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // — Notch kiri (puzzle piece effect)
        _buildNotch(),
        const SizedBox(width: BcDimensions.spacingS),

        // — Icon
        Icon(
          block.type.icon,
          color: BcColors.textPrimary,
          size: BcDimensions.iconS,
        ),
        const SizedBox(width: BcDimensions.spacingS),

        // — Label dan params
        Flexible(child: _buildLabel(context)),
        const SizedBox(width: BcDimensions.spacingS),

        // — Delete button
        _buildDeleteButton(context),
      ],
    );
  }

  Widget _buildNotch() {
    return Container(
      width: BcDimensions.blockConnectorSize,
      height: BcDimensions.blockConnectorSize,
      decoration: BoxDecoration(
        color: BcColors.textPrimary.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final params = block.params;
    String label = block.type.label;

    // Tambah ringkasan parameter ke label
    if (params.isNotEmpty) {
      switch (block.type) {
        case BlockType.printBlock:
          label = '${block.type.label}: "${params['text']}"';
        case BlockType.askBlock:
          label = '${block.type.label}: "${params['question']}"';
        case BlockType.setVarBlock:
          label = '${params['name']} = ${params['value']}';
        case BlockType.changeVarBlock:
          label = '${params['name']} += ${params['delta']}';
        case BlockType.repeatBlock:
          label = '${block.type.label} ${params['count']}×';
        case BlockType.whileBlock:
          label = '${block.type.label} (${params['condition']})';
        case BlockType.ifBlock:
        case BlockType.ifElseBlock:
          label = '${block.type.label} (${params['condition']})';
        case BlockType.mathAddBlock:
          label = '${params['result']} = ${params['a']} + ${params['b']}';
        case BlockType.mathSubBlock:
          label = '${params['result']} = ${params['a']} - ${params['b']}';
        case BlockType.mathMulBlock:
          label = '${params['result']} = ${params['a']} × ${params['b']}';
        case BlockType.mathDivBlock:
          label = '${params['result']} = ${params['a']} ÷ ${params['b']}';
        case BlockType.compareBlock:
          label =
              '${params['result']} = (${params['a']} ${params['op']} ${params['b']})';
        default:
          break;
      }
    }

    return Text(
      label,
      style: const TextStyle(
        color: BcColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    if (block.type.isSingleton) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _onDelete(context),
      child: Container(
        padding: const EdgeInsets.all(BcDimensions.spacingXs),
        decoration: BoxDecoration(
          color: BcColors.textPrimary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: BcColors.textPrimary,
          size: BcDimensions.iconXs,
        ),
      ),
    );
  }

  Widget _buildBodySection(BuildContext context) {
    final isIfElse = block.type == BlockType.ifElseBlock;

    return Padding(
      padding: EdgeInsets.only(left: depth * BcDimensions.blockIndent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Garis vertikal kiri
          Container(
            width: 3,
            margin: const EdgeInsets.only(left: BcDimensions.spacingM),
            color: block.type.darkColor.withOpacity(0.6),
          ),
          const SizedBox(width: BcDimensions.spacingS),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // — Body utama
                _buildInnerDropZone(
                  context,
                  blocks: block.innerBlocks,
                  parentId: block.id,
                  isElse: false,
                  label: isIfElse ? 'Jika Benar:' : null,
                ),

                // — Body else (hanya untuk if-else)
                if (isIfElse) ...[
                  _buildElseDivider(),
                  _buildInnerDropZone(
                    context,
                    blocks: block.elseBlocks,
                    parentId: block.id,
                    isElse: true,
                    label: 'Lainnya:',
                  ),
                ],

                const SizedBox(height: BcDimensions.spacingS),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnerDropZone(
    BuildContext context, {
    required List<Block> blocks,
    required String parentId,
    required bool isElse,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: BcDimensions.spacingXs,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: block.type.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),

        // Blok anak
        ...blocks.map(
          (child) => CanvasBlockWidget(
            key: ValueKey(child.id),
            block: child,
            depth: 0,
          ),
        ),

        // Drop target untuk tambah blok anak
        _buildAddInnerBlockButton(context, parentId: parentId, isElse: isElse),
      ],
    );
  }

  Widget _buildAddInnerBlockButton(
    BuildContext context, {
    required String parentId,
    required bool isElse,
  }) {
    return GestureDetector(
      onTap: () => _showAddBlockDialog(context, parentId: parentId, isElse: isElse),
      child: Container(
        margin: const EdgeInsets.only(top: BcDimensions.spacingXs),
        padding: const EdgeInsets.symmetric(
          horizontal: BcDimensions.spacingM,
          vertical: BcDimensions.spacingXs,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: block.type.color.withOpacity(0.4),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(BcDimensions.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              color: block.type.color.withOpacity(0.7),
              size: BcDimensions.iconXs,
            ),
            const SizedBox(width: BcDimensions.spacingXs),
            Text(
              'Tambah blok',
              style: TextStyle(
                color: block.type.color.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElseDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BcDimensions.spacingXs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BcDimensions.spacingS,
          vertical: BcDimensions.spacingXs,
        ),
        decoration: BoxDecoration(
          color: BcColors.blockControlDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(BcDimensions.radiusXs),
        ),
        child: const Text(
          BcStrings.blockOr,
          style: TextStyle(
            color: BcColors.blockControl,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final cubit = context.read<BlockEditorCubit>();
    if (isSelected) {
      cubit.deselectBlock();
    } else {
      cubit.selectBlock(block.id);
      _showParamEditor(context);
    }
  }

  void _onDelete(BuildContext context) {
    context.read<BlockEditorCubit>().removeBlock(block.id);
  }

  void _showParamEditor(BuildContext context) {
    if (block.params.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: BcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BcDimensions.radiusL),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BlockEditorCubit>(),
        child: _BlockParamEditor(block: block),
      ),
    );
  }

  void _showAddBlockDialog(
    BuildContext context, {
    required String parentId,
    required bool isElse,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BcDimensions.radiusL),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BlockEditorCubit>(),
        child: _AddInnerBlockSheet(
          parentId: parentId,
          isElse: isElse,
          allowedBlocks: context.read<BlockEditorCubit>().state.challenge?.allowedBlocks,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Block Param Editor
// ─────────────────────────────────────────────────────────────────────────────

class _BlockParamEditor extends StatefulWidget {
  final Block block;
  const _BlockParamEditor({required this.block});

  @override
  State<_BlockParamEditor> createState() => _BlockParamEditorState();
}

class _BlockParamEditorState extends State<_BlockParamEditor> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    widget.block.params.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: BcDimensions.spacingM,
        right: BcDimensions.spacingM,
        top: BcDimensions.spacingM,
        bottom: MediaQuery.of(context).viewInsets.bottom + BcDimensions.spacingL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BcColors.border,
                borderRadius: BorderRadius.circular(BcDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: BcDimensions.spacingM),

          // Title
          Row(
            children: [
              Icon(widget.block.type.icon, color: widget.block.type.color),
              const SizedBox(width: BcDimensions.spacingS),
              Text(
                widget.block.type.label,
                style: const TextStyle(
                  color: BcColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: BcDimensions.spacingM),

          // Param fields
          ..._controllers.entries.map(
            (entry) => _buildParamField(entry.key, entry.value),
          ),

          const SizedBox(height: BcDimensions.spacingM),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.block.type.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BcDimensions.radiusM),
                ),
              ),
              child: const Text(
                BcStrings.save,
                style: TextStyle(color: BcColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamField(String key, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BcDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _labelForParam(key),
            style: const TextStyle(
              color: BcColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: BcDimensions.spacingXs),
          TextField(
            controller: controller,
            style: const TextStyle(color: BcColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: BcColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BcDimensions.radiusS),
                borderSide: const BorderSide(color: BcColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BcDimensions.radiusS),
                borderSide: const BorderSide(color: BcColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BcDimensions.radiusS),
                borderSide: BorderSide(color: widget.block.type.color),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BcDimensions.spacingM,
                vertical: BcDimensions.spacingS,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelForParam(String key) {
    const labels = {
      'text': 'Teks',
      'question': 'Pertanyaan',
      'variable': 'Simpan ke variabel',
      'name': 'Nama variabel',
      'value': 'Nilai',
      'delta': 'Ubah sebesar',
      'count': 'Jumlah pengulangan',
      'condition': 'Kondisi',
      'a': 'Nilai A',
      'b': 'Nilai B',
      'op': 'Operator (>, <, >=, <=, ==, !=)',
      'result': 'Simpan ke variabel',
    };
    return labels[key] ?? key;
  }

  void _save() {
    final cubit = context.read<BlockEditorCubit>();
    _controllers.forEach((key, controller) {
      cubit.updateBlockParam(widget.block.id, key, controller.text);
    });
    Navigator.pop(context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Inner Block Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddInnerBlockSheet extends StatelessWidget {
  final String parentId;
  final bool isElse;
  final List<BlockType>? allowedBlocks;

  const _AddInnerBlockSheet({
    required this.parentId,
    required this.isElse,
    this.allowedBlocks,
  });

  @override
  Widget build(BuildContext context) {
    final available = allowedBlocks ?? BlockType.values.toList();
    final nonSingleton = available.where((t) => !t.isSingleton).toList();

    return Padding(
      padding: const EdgeInsets.all(BcDimensions.spacingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: BcColors.border,
                borderRadius: BorderRadius.circular(BcDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: BcDimensions.spacingM),
          const Text(
            'Pilih blok untuk ditambahkan',
            style: TextStyle(
              color: BcColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BcDimensions.spacingM),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: nonSingleton.length,
              itemBuilder: (context, i) {
                final type = nonSingleton[i];
                return ListTile(
                  leading: Icon(type.icon, color: type.color),
                  title: Text(
                    type.label,
                    style: const TextStyle(color: BcColors.textPrimary),
                  ),
                  onTap: () {
                    final cubit = context.read<BlockEditorCubit>();
                    if (isElse) {
                      cubit.addElseBlock(parentId, type);
                    } else {
                      cubit.addInnerBlock(parentId, type);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
