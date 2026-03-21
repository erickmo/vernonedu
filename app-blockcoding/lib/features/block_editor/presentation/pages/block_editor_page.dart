import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_dimensions.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';
import 'package:vernonedu_blockcoding/core/di/injection.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_blockcoding/features/home/data/datasources/challenge_local_datasource.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_state.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/widgets/block_canvas.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/widgets/block_palette_panel.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/widgets/code_preview_panel.dart';
import 'package:vernonedu_blockcoding/features/home/domain/entities/challenge.dart';

/// Halaman utama block editor.
///
/// Menerima [challengeId] opsional. Jika null, mode bebas (free coding).
class BlockEditorPage extends StatelessWidget {
  final String? challengeId;

  const BlockEditorPage({super.key, this.challengeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<BlockEditorCubit>();
        if (challengeId != null) {
          final challenge = getIt<ChallengeLocalDatasource>()
              .getChallengeById(challengeId!);
          if (challenge != null) {
            cubit.loadChallenge(challenge);
          } else {
            cubit.loadFreeMode();
          }
        } else {
          cubit.loadFreeMode();
        }
        return cubit;
      },
      child: const _BlockEditorView(),
    );
  }
}

class _BlockEditorView extends StatelessWidget {
  const _BlockEditorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      title: BlocBuilder<BlockEditorCubit, BlockEditorState>(
        buildWhen: (p, c) => p.challenge != c.challenge,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.challenge?.title ?? AppStrings.editorTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.challenge != null)
                Text(
                  _levelLabel(state.challenge!.level),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        // — Code preview toggle
        BlocBuilder<BlockEditorCubit, BlockEditorState>(
          buildWhen: (p, c) => p.showCodePanel != c.showCodePanel,
          builder: (context, state) {
            return IconButton(
              onPressed: () =>
                  context.read<BlockEditorCubit>().toggleCodePanel(),
              icon: Icon(
                Icons.code_rounded,
                color: state.showCodePanel
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              tooltip: state.showCodePanel
                  ? AppStrings.editorHideCode
                  : AppStrings.editorShowCode,
            );
          },
        ),

        // — Clear canvas
        IconButton(
          onPressed: () => _confirmClear(context),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.textSecondary,
          ),
          tooltip: AppStrings.editorClearCanvas,
        ),

        // — Run button
        _buildRunButton(context),

        const SizedBox(width: AppDimensions.spacingXs),
      ],
    );
  }

  Widget _buildRunButton(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      buildWhen: (p, c) => p.runStatus != c.runStatus,
      builder: (context, state) {
        final isRunning = state.runStatus == RunStatus.running;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
          child: ElevatedButton.icon(
            onPressed: isRunning
                ? null
                : () => context.read<BlockEditorCubit>().runProgram(),
            icon: isRunning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              isRunning ? AppStrings.editorRunning : AppStrings.editorRun,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning ? AppColors.surfaceVariant : AppColors.success,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocListener<BlockEditorCubit, BlockEditorState>(
      listenWhen: (p, c) => c.isChallengeCompleted && !p.isChallengeCompleted,
      listener: (context, state) => _showCompletionDialog(context),
      child: Column(
        children: [
          // — Canvas (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: const [
                  BlockCanvas(),
                ],
              ),
            ),
          ),

          // — Code preview panel
          const CodePreviewPanel(),

          // — Output panel
          const ExecutionOutputPanel(),

          // — Bottom: Add block button + hint
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      buildWhen: (p, c) => p.challenge != c.challenge,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // — Challenge hint
              if (state.challenge != null)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showHint(context, state.challenge!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.warning,
                          size: AppDimensions.iconS,
                        ),
                        const SizedBox(width: AppDimensions.spacingXs),
                        Text(
                          AppStrings.challengeHint,
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),

              // — Add block FAB
              FloatingActionButton.extended(
                onPressed: () => BlockPaletteBottomSheet.show(
                  context,
                  context.read<BlockEditorCubit>(),
                  allowedBlocks: state.challenge?.allowedBlocks,
                ),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                elevation: 4,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Tambah Blok',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _levelLabel(ChallengeLevel level) {
    switch (level) {
      case ChallengeLevel.beginner:
        return '🟢 Pemula';
      case ChallengeLevel.intermediate:
        return '🟡 Menengah';
      case ChallengeLevel.advanced:
        return '🔴 Lanjut';
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: const Text(
          AppStrings.editorClearCanvas,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Semua blok akan dihapus. Yakin?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BlockEditorCubit>().clearCanvas();
            },
            child: const Text(
              AppStrings.editorClearCanvas,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showHint(BuildContext context, Challenge challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: AppColors.warning),
                SizedBox(width: AppDimensions.spacingS),
                Text(
                  AppStrings.challengeHint,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              challenge.hint,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            if (challenge.expectedOutput.isNotEmpty) ...[
              const Text(
                AppStrings.challengeExpected,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.codeBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  challenge.expectedOutput.join('\n'),
                  style: const TextStyle(
                    color: AppColors.codeString,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingM),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            const Text(
              AppStrings.challengeCompleted,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            const Text(
              'Output kamu sesuai! Kamu berhasil menyelesaikan tantangan ini. 🎉',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              AppStrings.challengeBack,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: const Text(
              AppStrings.challengeBack,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

