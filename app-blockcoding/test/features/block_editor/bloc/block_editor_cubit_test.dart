import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block_type.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_cubit.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/bloc/block_editor_state.dart';
import 'package:vernonedu_blockcoding/features/home/domain/entities/challenge.dart';

void main() {
  late BlockEditorCubit cubit;

  setUp(() {
    cubit = BlockEditorCubit(uuid: const Uuid());
  });

  tearDown(() => cubit.close());

  group('BlockEditorCubit — Initial State', () {
    test('initial state is empty', () {
      expect(cubit.state.blocks, isEmpty);
      expect(cubit.state.runStatus, RunStatus.idle);
      expect(cubit.state.generatedCode, '');
    });
  });

  group('BlockEditorCubit — Free Mode', () {
    blocTest<BlockEditorCubit, BlockEditorState>(
      'loadFreeMode emits empty state',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) => c.loadFreeMode(),
      expect: () => [
        isA<BlockEditorState>().having((s) => s.blocks, 'blocks', isEmpty),
      ],
    );
  });

  group('BlockEditorCubit — Block Manipulation', () {
    blocTest<BlockEditorCubit, BlockEditorState>(
      'addBlock adds block to canvas',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) => c.addBlock(BlockType.printBlock),
      expect: () => [
        isA<BlockEditorState>()
            .having((s) => s.blocks.length, 'block count', 1)
            .having(
              (s) => s.blocks.first.type,
              'block type',
              BlockType.printBlock,
            ),
      ],
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'addBlock multiple blocks maintains order',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) {
        c.addBlock(BlockType.start);
        c.addBlock(BlockType.printBlock);
        c.addBlock(BlockType.end);
      },
      expect: () => [
        isA<BlockEditorState>()
            .having((s) => s.blocks.length, 'length', 1),
        isA<BlockEditorState>()
            .having((s) => s.blocks.length, 'length', 2),
        isA<BlockEditorState>()
            .having((s) => s.blocks.length, 'length', 3)
            .having(
              (s) => s.blocks.map((b) => b.type).toList(),
              'order',
              [BlockType.start, BlockType.printBlock, BlockType.end],
            ),
      ],
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'removeBlock removes correct block',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) async {
        c.addBlock(BlockType.start);
        c.addBlock(BlockType.printBlock);
        // Remove the print block (index 1)
        final blockId = c.state.blocks[1].id;
        c.removeBlock(blockId);
      },
      verify: (c) {
        expect(c.state.blocks.length, 1);
        expect(c.state.blocks.first.type, BlockType.start);
      },
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'updateBlockParam updates parameter correctly',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) async {
        c.addBlock(BlockType.printBlock);
        final blockId = c.state.blocks.first.id;
        c.updateBlockParam(blockId, 'text', 'Hello, Test!');
      },
      verify: (c) {
        expect(c.state.blocks.first.params['text'], 'Hello, Test!');
      },
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'clearCanvas removes all blocks',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) {
        c.addBlock(BlockType.start);
        c.addBlock(BlockType.printBlock);
        c.addBlock(BlockType.end);
        c.clearCanvas();
      },
      verify: (c) {
        expect(c.state.blocks, isEmpty);
        expect(c.state.runStatus, RunStatus.idle);
      },
    );
  });

  group('BlockEditorCubit — Code Generation', () {
    blocTest<BlockEditorCubit, BlockEditorState>(
      'adding printBlock generates pseudocode',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) => c.addBlock(BlockType.printBlock),
      verify: (c) {
        expect(c.state.generatedCode, contains('cetak'));
      },
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'updating text param updates generated code',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) async {
        c.addBlock(BlockType.printBlock);
        final id = c.state.blocks.first.id;
        c.updateBlockParam(id, 'text', 'Halo Dunia');
      },
      verify: (c) {
        expect(c.state.generatedCode, contains('Halo Dunia'));
      },
    );
  });

  group('BlockEditorCubit — Execution', () {
    blocTest<BlockEditorCubit, BlockEditorState>(
      'runProgram with print block produces output',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) async {
        c.addBlock(BlockType.start);
        c.addBlock(BlockType.printBlock);
        c.addBlock(BlockType.end);
        // Update default text
        final printId = c.state.blocks
            .firstWhere((b) => b.type == BlockType.printBlock)
            .id;
        c.updateBlockParam(printId, 'text', 'Hello, World!');
        await c.runProgram();
      },
      verify: (c) {
        expect(c.state.runStatus, RunStatus.success);
        expect(
          c.state.executionResult?.outputLines,
          contains('Hello, World!'),
        );
      },
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'runProgram with empty canvas does not run',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) => c.runProgram(),
      expect: () => [],
    );
  });

  group('BlockEditorCubit — Challenge Mode', () {
    const testChallenge = Challenge(
      id: 'test_ch',
      title: 'Test Challenge',
      description: 'Test',
      hint: 'Test hint',
      level: ChallengeLevel.beginner,
      categoryId: 'test_cat',
      expectedOutput: ['Hello, World!'],
      starterBlocks: [BlockType.start, BlockType.end],
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'loadChallenge sets challenge and starter blocks',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) => c.loadChallenge(testChallenge),
      verify: (c) {
        expect(c.state.challenge, testChallenge);
        expect(c.state.blocks.length, 2);
        expect(c.state.blocks.first.type, BlockType.start);
        expect(c.state.blocks.last.type, BlockType.end);
      },
    );

    blocTest<BlockEditorCubit, BlockEditorState>(
      'challenge is completed when output matches expected',
      build: () => BlockEditorCubit(uuid: const Uuid()),
      act: (c) async {
        c.loadChallenge(testChallenge);
        // Add print block with correct output
        c.addBlock(BlockType.printBlock);
        final printId = c.state.blocks
            .firstWhere((b) => b.type == BlockType.printBlock)
            .id;
        c.updateBlockParam(printId, 'text', 'Hello, World!');
        await c.runProgram();
      },
      verify: (c) {
        expect(c.state.isChallengeCompleted, isTrue);
      },
    );
  });
}
