import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:vernonedu_entrepreneurship_app/core/utils/block_code_generator.dart';
import 'package:vernonedu_entrepreneurship_app/core/utils/block_executor.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block_type.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/presentation/bloc/block_editor_state.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/challenge.dart';

const String _kCompletedKey = 'bc_completed_challenges';

/// Mengelola state block editor — canvas, eksekusi, dan kode.
class BlockEditorCubit extends Cubit<BlockEditorState> {
  final Uuid _uuid;

  BlockEditorCubit({Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const BlockEditorState());

  // ───────────────────────────────── Init ──────────────────────────────────

  /// Inisialisasi editor dengan [challenge] tertentu.
  void loadChallenge(Challenge challenge) {
    final starterBlocks = challenge.starterBlocks
        .map(
          (type) => Block(
            id: _uuid.v4(),
            type: type,
            params: defaultParamsFor(type),
          ),
        )
        .toList();

    emit(BlockEditorState(
      challenge: challenge,
      blocks: starterBlocks,
      generatedCode: BlockCodeGenerator.generate(starterBlocks),
    ));
  }

  /// Inisialisasi editor tanpa challenge (mode bebas).
  void loadFreeMode() {
    emit(const BlockEditorState());
  }

  // ──────────────────────────── Block Manipulation ─────────────────────────

  /// Tambahkan blok baru di akhir canvas.
  void addBlock(BlockType type) {
    final block = Block(
      id: _uuid.v4(),
      type: type,
      params: defaultParamsFor(type),
    );
    final newBlocks = [...state.blocks, block];
    _emitWithCode(newBlocks);
  }

  /// Tambahkan blok pada posisi tertentu.
  void insertBlock(BlockType type, int index) {
    final block = Block(
      id: _uuid.v4(),
      type: type,
      params: defaultParamsFor(type),
    );
    final newBlocks = [...state.blocks];
    final clampedIndex = index.clamp(0, newBlocks.length);
    newBlocks.insert(clampedIndex, block);
    _emitWithCode(newBlocks);
  }

  /// Hapus blok dari canvas (top-level).
  void removeBlock(String blockId) {
    final newBlocks = state.blocks.where((b) => b.id != blockId).toList();
    _emitWithCode(newBlocks, clearSelectedBlock: true);
  }

  /// Reorder blok di canvas.
  void reorderBlocks(int oldIndex, int newIndex) {
    final newBlocks = [...state.blocks];
    final block = newBlocks.removeAt(oldIndex);
    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    newBlocks.insert(adjustedIndex, block);
    _emitWithCode(newBlocks);
  }

  /// Update parameter satu blok.
  void updateBlockParam(String blockId, String key, String value) {
    final newBlocks = _updateBlockInList(state.blocks, blockId, (b) {
      return b.withParam(key, value);
    });
    _emitWithCode(newBlocks);
  }

  /// Tambah blok anak di body utama blok parent.
  void addInnerBlock(String parentId, BlockType type) {
    final childBlock = Block(
      id: _uuid.v4(),
      type: type,
      params: defaultParamsFor(type),
    );
    final newBlocks = _updateBlockInList(state.blocks, parentId, (b) {
      return b.addInnerBlock(childBlock);
    });
    _emitWithCode(newBlocks);
  }

  /// Tambah blok anak di body else blok parent.
  void addElseBlock(String parentId, BlockType type) {
    final childBlock = Block(
      id: _uuid.v4(),
      type: type,
      params: defaultParamsFor(type),
    );
    final newBlocks = _updateBlockInList(state.blocks, parentId, (b) {
      return b.addElseBlock(childBlock);
    });
    _emitWithCode(newBlocks);
  }

  /// Hapus blok anak dari body utama blok parent.
  void removeInnerBlock(String parentId, String childId) {
    final newBlocks = _updateBlockInList(state.blocks, parentId, (b) {
      return b.removeInnerBlock(childId);
    });
    _emitWithCode(newBlocks);
  }

  /// Pilih blok (untuk edit parameter).
  void selectBlock(String blockId) {
    emit(state.copyWith(selectedBlockId: blockId));
  }

  /// Deselect blok.
  void deselectBlock() {
    emit(state.copyWith(clearSelectedBlock: true));
  }

  /// Bersihkan semua blok di canvas.
  void clearCanvas() {
    emit(state.copyWith(
      blocks: [],
      generatedCode: '',
      clearExecutionResult: true,
      clearSelectedBlock: true,
      runStatus: RunStatus.idle,
      isChallengeCompleted: false,
    ));
  }

  // ─────────────────────────────── Code Panel ──────────────────────────────

  void toggleCodePanel() {
    emit(state.copyWith(showCodePanel: !state.showCodePanel));
  }

  // ─────────────────────────────── Execution ───────────────────────────────

  /// Jalankan program dari blok-blok yang ada di canvas.
  Future<void> runProgram() async {
    if (!state.canRun) return;

    emit(state.copyWith(
      runStatus: RunStatus.running,
      clearExecutionResult: true,
      isChallengeCompleted: false,
    ));

    // Sedikit delay agar animasi running terasa nyata
    await Future.delayed(const Duration(milliseconds: 600));

    final executor = BlockExecutor(
      simulatedInputs: state.challenge?.simulatedInputs ?? [],
    );

    final result = executor.execute(state.blocks);

    final isCompleted = _checkChallengeCompletion(result);

    if (isCompleted && state.challenge != null) {
      _saveCompletedChallenge(state.challenge!.id);
    }

    emit(state.copyWith(
      runStatus: result.isSuccess ? RunStatus.success : RunStatus.error,
      executionResult: result,
      isChallengeCompleted: isCompleted,
    ));
  }

  Future<void> _saveCompletedChallenge(String challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = (prefs.getStringList(_kCompletedKey) ?? []).toSet();
    completed.add(challengeId);
    await prefs.setStringList(_kCompletedKey, completed.toList());
  }

  /// Reset status run ke idle.
  void resetRunStatus() {
    emit(state.copyWith(
      runStatus: RunStatus.idle,
      clearExecutionResult: true,
      isChallengeCompleted: false,
    ));
  }

  // ─────────────────────────────── Helpers ─────────────────────────────────

  void _emitWithCode(
    List<Block> blocks, {
    bool clearSelectedBlock = false,
  }) {
    emit(state.copyWith(
      blocks: blocks,
      generatedCode: BlockCodeGenerator.generate(blocks),
      runStatus: RunStatus.idle,
      clearExecutionResult: true,
      clearSelectedBlock: clearSelectedBlock,
      isChallengeCompleted: false,
    ));
  }

  /// Update blok dengan [blockId] di dalam list (recursive).
  List<Block> _updateBlockInList(
    List<Block> blocks,
    String blockId,
    Block Function(Block) updater,
  ) {
    return blocks.map((b) {
      if (b.id == blockId) return updater(b);
      // Recursive update di innerBlocks dan elseBlocks
      return b.copyWith(
        innerBlocks: _updateBlockInList(b.innerBlocks, blockId, updater),
        elseBlocks: _updateBlockInList(b.elseBlocks, blockId, updater),
      );
    }).toList();
  }

  bool _checkChallengeCompletion(executionResult) {
    final challenge = state.challenge;
    if (challenge == null || !executionResult.isSuccess) return false;
    if (challenge.expectedOutput.isEmpty) return true;

    final output = executionResult.outputLines as List<String>;
    if (output.length != challenge.expectedOutput.length) return false;

    for (int i = 0; i < challenge.expectedOutput.length; i++) {
      if (output[i].trim() != challenge.expectedOutput[i].trim()) return false;
    }
    return true;
  }
}
