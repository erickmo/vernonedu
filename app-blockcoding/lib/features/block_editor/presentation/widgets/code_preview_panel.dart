import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_dimensions.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_state.dart';

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
          height: AppDimensions.codePanelHeight,
          decoration: const BoxDecoration(
            color: AppColors.codeBg,
            border: Border(top: BorderSide(color: AppColors.border)),
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
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.code_rounded,
            color: AppColors.accent,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          const Text(
            AppStrings.editorCodePreview,
            style: TextStyle(
              color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          // Close button
          GestureDetector(
            onTap: () => context.read<BlockEditorCubit>().toggleCodePanel(),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
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
          style: TextStyle(color: AppColors.textHint, fontSize: 12),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: SelectableText(
        state.generatedCode,
        style: const TextStyle(
          color: AppColors.codeString,
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
        backgroundColor: AppColors.success,
      ),
    );
  }
}
