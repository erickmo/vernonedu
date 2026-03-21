import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/bc_theme.dart';


import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_state.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/widgets/canvas_block_widget.dart';

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
            minHeight: BcDimensions.canvasMinHeight,
          ),
          decoration: const BoxDecoration(
            color: BcColors.canvasBackground,
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
            padding: const EdgeInsets.all(BcDimensions.spacingXl),
            decoration: BoxDecoration(
              color: BcColors.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.widgets_outlined,
              color: BcColors.textHint,
              size: BcDimensions.iconXl,
            ),
          ),
          const SizedBox(height: BcDimensions.spacingL),
          const Text(
            BcStrings.editorDragHint,
            style: TextStyle(
              color: BcColors.textHint,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BcDimensions.spacingS),
          const Text(
            'Ketuk tombol + untuk mulai',
            style: TextStyle(
              color: BcColors.textDisabled,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockList(BuildContext context, BlockEditorState state) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(BcDimensions.spacingM),
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
            color: BcColors.codeBg,
            border: Border(top: BorderSide(color: BcColors.border)),
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
        headerColor = BcColors.warning;
        headerIcon = Icons.play_circle_outline_rounded;
        headerText = BcStrings.editorRunning;
      case RunStatus.success:
        headerColor = state.isChallengeCompleted
            ? BcColors.success
            : BcColors.info;
        headerIcon = state.isChallengeCompleted
            ? Icons.check_circle_rounded
            : Icons.terminal_rounded;
        headerText = state.isChallengeCompleted
            ? BcStrings.challengeCorrect
            : BcStrings.editorSuccess;
      case RunStatus.error:
        headerColor = BcColors.error;
        headerIcon = Icons.error_outline_rounded;
        headerText = BcStrings.errorExecution;
      case RunStatus.idle:
        headerColor = BcColors.textSecondary;
        headerIcon = Icons.terminal_rounded;
        headerText = BcStrings.editorOutput;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BcDimensions.spacingM,
        vertical: BcDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: headerColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: headerColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(headerIcon, color: headerColor, size: BcDimensions.iconS),
          const SizedBox(width: BcDimensions.spacingS),
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
                color: BcColors.textHint,
                size: BcDimensions.iconS,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRunningIndicator() {
    return const Padding(
      padding: EdgeInsets.all(BcDimensions.spacingM),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: BcColors.warning,
            ),
          ),
          SizedBox(width: BcDimensions.spacingS),
          Text(
            BcStrings.editorRunning,
            style: TextStyle(color: BcColors.warning, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputContent(BlockEditorState state) {
    final result = state.executionResult!;

    return SizedBox(
      height: BcDimensions.outputPanelHeight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BcDimensions.spacingM),
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
                style: TextStyle(color: BcColors.textHint, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputLine(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BcDimensions.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '> ',
            style: TextStyle(
              color: BcColors.success,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                color: BcColors.textPrimary,
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
          style: TextStyle(color: BcColors.error, fontSize: 13),
        ),
        Expanded(
          child: Text(
            error,
            style: const TextStyle(
              color: BcColors.error,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
