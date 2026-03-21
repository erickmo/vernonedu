import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_dimensions.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_state.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/widgets/canvas_block_widget.dart';

/// Area canvas tempat blok disusun.
///
/// Mendukung reorder via drag-and-drop dan menampilkan garis grid.
class BlockCanvas extends StatelessWidget {
  const BlockCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: AppDimensions.canvasMinHeight,
          ),
          decoration: const BoxDecoration(
            color: AppColors.canvasBackground,
          ),
          child: state.blocks.isEmpty
              ? _buildEmptyState()
              : _buildBlockList(context, state),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.widgets_outlined,
              color: AppColors.textHint,
              size: AppDimensions.iconXl,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          const Text(
            AppStrings.editorDragHint,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            'Ketuk tombol + untuk mulai',
            style: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockList(BuildContext context, BlockEditorState state) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        context.read<BlockEditorCubit>().reorderBlocks(oldIndex, newIndex);
      },
      itemCount: state.blocks.length,
      itemBuilder: (context, index) {
        final block = state.blocks[index];
        final isSelected = state.selectedBlockId == block.id;
        final isExecuting = state.runStatus == RunStatus.running;

        return ReorderableDragStartListener(
          key: ValueKey(block.id),
          index: index,
          child: CanvasBlockWidget(
            block: block,
            isSelected: isSelected,
            isExecuting: isExecuting,
          ),
        );
      },
    );
  }
}

/// Panel output eksekusi program.
class ExecutionOutputPanel extends StatelessWidget {
  const ExecutionOutputPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      builder: (context, state) {
        if (state.runStatus == RunStatus.idle &&
            state.executionResult == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.codeBg,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Header
              _buildOutputHeader(context, state),

              // — Content
              if (state.runStatus == RunStatus.running)
                _buildRunningIndicator()
              else if (state.executionResult != null)
                _buildOutputContent(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutputHeader(BuildContext context, BlockEditorState state) {
    Color headerColor;
    IconData headerIcon;
    String headerText;

    switch (state.runStatus) {
      case RunStatus.running:
        headerColor = AppColors.warning;
        headerIcon = Icons.play_circle_outline_rounded;
        headerText = AppStrings.editorRunning;
      case RunStatus.success:
        headerColor = state.isChallengeCompleted
            ? AppColors.success
            : AppColors.info;
        headerIcon = state.isChallengeCompleted
            ? Icons.check_circle_rounded
            : Icons.terminal_rounded;
        headerText = state.isChallengeCompleted
            ? AppStrings.challengeCorrect
            : AppStrings.editorSuccess;
      case RunStatus.error:
        headerColor = AppColors.error;
        headerIcon = Icons.error_outline_rounded;
        headerText = AppStrings.errorExecution;
      case RunStatus.idle:
        headerColor = AppColors.textSecondary;
        headerIcon = Icons.terminal_rounded;
        headerText = AppStrings.editorOutput;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: headerColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(headerIcon, color: headerColor, size: AppDimensions.iconS),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            headerText,
            style: TextStyle(
              color: headerColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (state.executionResult != null)
            GestureDetector(
              onTap: () => context.read<BlockEditorCubit>().resetRunStatus(),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textHint,
                size: AppDimensions.iconS,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRunningIndicator() {
    return const Padding(
      padding: EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.warning,
            ),
          ),
          SizedBox(width: AppDimensions.spacingS),
          Text(
            AppStrings.editorRunning,
            style: TextStyle(color: AppColors.warning, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputContent(BlockEditorState state) {
    final result = state.executionResult!;

    return SizedBox(
      height: AppDimensions.outputPanelHeight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!result.isSuccess && result.errorMessage != null)
              _buildErrorLine(result.errorMessage!)
            else
              ...result.outputLines.map(_buildOutputLine),

            if (result.isSuccess && result.outputLines.isEmpty)
              const Text(
                '(tidak ada output)',
                style: TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '> ',
            style: TextStyle(
              color: AppColors.success,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorLine(String error) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✗ ',
          style: TextStyle(color: AppColors.error, fontSize: 13),
        ),
        Expanded(
          child: Text(
            error,
            style: const TextStyle(
              color: AppColors.error,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
