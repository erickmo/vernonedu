import 'package:equatable/equatable.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block_type.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/execution_result.dart';
import 'package:vernonedu_blockcoding/features/home/domain/entities/challenge.dart';

/// Status eksekusi program.
enum RunStatus { idle, running, success, error }

/// State untuk [BlockEditorCubit].
class BlockEditorState extends Equatable {
  final Challenge? challenge;
  final List<Block> blocks;
  final String generatedCode;
  final RunStatus runStatus;
  final ExecutionResult? executionResult;
  final bool showCodePanel;
  final String? selectedBlockId;
  final bool isChallengeCompleted;

  const BlockEditorState({
    this.challenge,
    this.blocks = const [],
    this.generatedCode = '',
    this.runStatus = RunStatus.idle,
    this.executionResult,
    this.showCodePanel = false,
    this.selectedBlockId,
    this.isChallengeCompleted = false,
  });

  BlockEditorState copyWith({
    Challenge? challenge,
    List<Block>? blocks,
    String? generatedCode,
    RunStatus? runStatus,
    ExecutionResult? executionResult,
    bool? showCodePanel,
    String? selectedBlockId,
    bool? isChallengeCompleted,
    bool clearSelectedBlock = false,
    bool clearExecutionResult = false,
  }) {
    return BlockEditorState(
      challenge: challenge ?? this.challenge,
      blocks: blocks ?? this.blocks,
      generatedCode: generatedCode ?? this.generatedCode,
      runStatus: runStatus ?? this.runStatus,
      executionResult:
          clearExecutionResult ? null : (executionResult ?? this.executionResult),
      showCodePanel: showCodePanel ?? this.showCodePanel,
      selectedBlockId:
          clearSelectedBlock ? null : (selectedBlockId ?? this.selectedBlockId),
      isChallengeCompleted:
          isChallengeCompleted ?? this.isChallengeCompleted,
    );
  }

  bool get hasStartBlock => blocks.any((b) => b.type == BlockType.start);

  bool get hasEndBlock => blocks.any((b) => b.type == BlockType.end);

  bool get canRun => blocks.isNotEmpty;

  @override
  List<Object?> get props => [
        challenge?.id,
        blocks,
        generatedCode,
        runStatus,
        executionResult,
        showCodePanel,
        selectedBlockId,
        isChallengeCompleted,
      ];
}
