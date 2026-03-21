import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/bc_theme.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/data/challenge_local_datasource.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/challenge.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_state.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/widgets/block_canvas.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/widgets/block_palette_panel.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/widgets/code_preview_panel.dart';

/// Block editor page — dapat menerima [challengeId] opsional.
class BlockEditorPage extends StatelessWidget {
  final String? challengeId;

  const BlockEditorPage({super.key, this.challengeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = BlockEditorCubit();
        if (challengeId != null) {
          final challenge =
              ChallengeLocalDatasource().getChallengeById(challengeId!);
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
      child: Theme(
        // Paksa dark theme di dalam editor
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: BcColors.canvasBackground,
          colorScheme: const ColorScheme.dark(
            primary: BcColors.primary,
            surface: BcColors.surface,
          ),
        ),
        child: const _BlockEditorView(),
      ),
    );
  }
}

class _BlockEditorView extends StatelessWidget {
  const _BlockEditorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BcColors.canvasBackground,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: BcColors.surface,
      foregroundColor: BcColors.textPrimary,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/block-coding'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: BlocBuilder<BlockEditorCubit, BlockEditorState>(
        buildWhen: (p, c) => p.challenge != c.challenge,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.challenge?.title ?? BcStrings.editorTitle,
              style: const TextStyle(
                color: BcColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.challenge != null)
              Text(
                _levelLabel(state.challenge!.level),
                style: const TextStyle(
                  color: BcColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Code toggle
        BlocBuilder<BlockEditorCubit, BlockEditorState>(
          buildWhen: (p, c) => p.showCodePanel != c.showCodePanel,
          builder: (context, state) => IconButton(
            onPressed: () =>
                context.read<BlockEditorCubit>().toggleCodePanel(),
            icon: Icon(
              Icons.code_rounded,
              color: state.showCodePanel
                  ? BcColors.accent
                  : BcColors.textSecondary,
            ),
          ),
        ),
        // Clear
        IconButton(
          onPressed: () => _confirmClear(context),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: BcColors.textSecondary,
          ),
        ),
        // Run
        _buildRunButton(context),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildRunButton(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      buildWhen: (p, c) => p.runStatus != c.runStatus,
      builder: (context, state) {
        final isRunning = state.runStatus == RunStatus.running;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ElevatedButton.icon(
            onPressed:
                isRunning ? null : () => context.read<BlockEditorCubit>().runProgram(),
            icon: isRunning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BcColors.textPrimary,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              isRunning ? BcStrings.editorRunning : BcStrings.editorRun,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isRunning ? BcColors.surfaceVariant : BcColors.success,
              foregroundColor: BcColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BcDimensions.radiusM),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocListener<BlockEditorCubit, BlockEditorState>(
      listenWhen: (p, c) =>
          c.isChallengeCompleted && !p.isChallengeCompleted,
      listener: (context, state) => _showCompletionDialog(context),
      child: Column(
        children: [
          // Canvas (scrollable)
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [BlockCanvas()],
              ),
            ),
          ),
          // Code preview
          const CodePreviewPanel(),
          // Output
          const ExecutionOutputPanel(),
          // Bottom bar
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BlocBuilder<BlockEditorCubit, BlockEditorState>(
      buildWhen: (p, c) => p.challenge != c.challenge,
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BcDimensions.spacingM,
          vertical: BcDimensions.spacingS,
        ),
        decoration: const BoxDecoration(
          color: BcColors.surface,
          border: Border(top: BorderSide(color: BcColors.border)),
        ),
        child: Row(
          children: [
            if (state.challenge != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _showHint(context, state.challenge!),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: BcColors.warning,
                        size: BcDimensions.iconS,
                      ),
                      SizedBox(width: BcDimensions.spacingXs),
                      Text(
                        BcStrings.challengeHint,
                        style: TextStyle(
                          color: BcColors.warning,
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
            FloatingActionButton.extended(
              onPressed: () => BlockPaletteBottomSheet.show(
                context,
                context.read<BlockEditorCubit>(),
                allowedBlocks: state.challenge?.allowedBlocks,
              ),
              backgroundColor: BcColors.primary,
              foregroundColor: BcColors.textPrimary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Blok',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _levelLabel(ChallengeLevel level) => switch (level) {
        ChallengeLevel.beginner => '🟢 Pemula',
        ChallengeLevel.intermediate => '🟡 Menengah',
        ChallengeLevel.advanced => '🔴 Lanjut',
      };

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BcDimensions.radiusL),
        ),
        title: const Text(
          BcStrings.editorClearCanvas,
          style: TextStyle(color: BcColors.textPrimary),
        ),
        content: const Text(
          'Semua blok akan dihapus. Yakin?',
          style: TextStyle(color: BcColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(BcStrings.cancel,
                style: TextStyle(color: BcColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BlockEditorCubit>().clearCanvas();
            },
            child: const Text(BcStrings.editorClearCanvas,
                style: TextStyle(color: BcColors.error)),
          ),
        ],
      ),
    );
  }

  void _showHint(BuildContext context, Challenge challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(BcDimensions.radiusL)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(BcDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: BcColors.warning),
                SizedBox(width: BcDimensions.spacingS),
                Text(
                  BcStrings.challengeHint,
                  style: TextStyle(
                    color: BcColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BcDimensions.spacingM),
            Text(
              challenge.hint,
              style: const TextStyle(
                color: BcColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (challenge.expectedOutput.isNotEmpty) ...[
              const SizedBox(height: BcDimensions.spacingL),
              const Text(
                BcStrings.challengeExpected,
                style: TextStyle(
                  color: BcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: BcDimensions.spacingS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BcDimensions.spacingM),
                decoration: BoxDecoration(
                  color: BcColors.codeBg,
                  borderRadius:
                      BorderRadius.circular(BcDimensions.radiusM),
                ),
                child: Text(
                  challenge.expectedOutput.join('\n'),
                  style: const TextStyle(
                    color: BcColors.codeString,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: BcDimensions.spacingM),
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
        backgroundColor: BcColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BcDimensions.spacingXl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: BcDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(BcDimensions.spacingXl),
              decoration: BoxDecoration(
                color: BcColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: BcColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: BcDimensions.spacingL),
            const Text(
              BcStrings.challengeCompleted,
              style: TextStyle(
                color: BcColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BcDimensions.spacingS),
            const Text(
              'Output kamu sesuai! Kamu berhasil.',
              style: TextStyle(
                color: BcColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/block-coding');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BcColors.success,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(BcDimensions.radiusM),
              ),
            ),
            child: const Text(
              BcStrings.challengeBack,
              style: TextStyle(
                color: BcColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
