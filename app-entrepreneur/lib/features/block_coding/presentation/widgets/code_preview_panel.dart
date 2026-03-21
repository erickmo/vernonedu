import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/bc_theme.dart';


import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_state.dart';

/// Panel yang menampilkan kode pseudocode yang di-generate dari blok.
class CodePreviewPanel extends StatelessWidget {
  const CodePreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      buildWhen: (prev, curr) =>
          prev.generatedCode != curr.generatedCode ||
          prev.showCodePanel != curr.showCodePanel,
      builder: (context, state) {
        if (!state.showCodePanel) return const SizedBox.shrink();

        return Container(
          height: BcDimensions.codePanelHeight,
          decoration: const BoxDecoration(
            color: BcColors.codeBg,
            border: Border(top: BorderSide(color: BcColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, state),
              Expanded(child: _buildCodeContent(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BlockEditorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BcDimensions.spacingM,
        vertical: BcDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: BcColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: BcColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.code_rounded,
            color: BcColors.accent,
            size: BcDimensions.iconS,
          ),
          const SizedBox(width: BcDimensions.spacingS),
          const Text(
            BcStrings.editorCodePreview,
            style: TextStyle(
              color: BcColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          // Copy button
          GestureDetector(
            onTap: () => _copyCode(context, state.generatedCode),
            child: const Icon(
              Icons.copy_rounded,
              color: BcColors.textSecondary,
              size: BcDimensions.iconS,
            ),
          ),
          const SizedBox(width: BcDimensions.spacingM),
          // Close button
          GestureDetector(
            onTap: () => context.read<BlockEditorCubit>().toggleCodePanel(),
            child: const Icon(
              Icons.close_rounded,
              color: BcColors.textSecondary,
              size: BcDimensions.iconS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeContent(BlockEditorState state) {
    if (state.generatedCode.isEmpty) {
      return const Center(
        child: Text(
          'Tambahkan blok untuk melihat kode',
          style: TextStyle(color: BcColors.textHint, fontSize: 12),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(BcDimensions.spacingM),
      child: SelectableText(
        state.generatedCode,
        style: const TextStyle(
          color: BcColors.codeString,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.6,
        ),
      ),
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode disalin!'),
        duration: Duration(seconds: 1),
        backgroundColor: BcColors.success,
      ),
    );
  }
}
