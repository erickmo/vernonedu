import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block.dart';
import 'package:vernonedu_blockcoding/features/block_editor/domain/entities/block_type.dart';

/// Generator kode pseudocode dari daftar [Block].
///
/// Menghasilkan kode yang menyerupai Python untuk keperluan edukasi.
class BlockCodeGenerator {
  static const String _indent = '    ';

  /// Generate kode dari daftar block utama.
  static String generate(List<Block> blocks) {
    final buffer = StringBuffer();
    _writeSequence(buffer, blocks, 0);
    return buffer.toString().trim();
  }

  static void _writeSequence(
    StringBuffer buffer,
    List<Block> blocks,
    int depth,
  ) {
    for (final block in blocks) {
      _writeBlock(buffer, block, depth);
    }
  }

  static void _writeBlock(StringBuffer buffer, Block block, int depth) {
    final indent = _indent * depth;

    switch (block.type) {
      case BlockType.start:
        buffer.writeln('${indent}# Program Mulai');

      case BlockType.end:
        buffer.writeln('${indent}# Program Selesai');

      case BlockType.printBlock:
        final text = block.params['text'] ?? '';
        buffer.writeln('${indent}cetak("$text")');

      case BlockType.askBlock:
        final question = block.params['question'] ?? '';
        final variable = block.params['variable'] ?? 'input';
        buffer.writeln('${indent}$variable = minta_input("$question")');

      case BlockType.setVarBlock:
        final name = block.params['name'] ?? 'x';
        final value = block.params['value'] ?? '0';
        buffer.writeln('${indent}$name = $value');

      case BlockType.changeVarBlock:
        final name = block.params['name'] ?? 'x';
        final delta = block.params['delta'] ?? '1';
        final sign = delta.startsWith('-') ? '' : '+';
        buffer.writeln('${indent}$name = $name $sign $delta');

      case BlockType.repeatBlock:
        final count = block.params['count'] ?? '1';
        buffer.writeln('${indent}ulangi $count kali:');
        if (block.innerBlocks.isEmpty) {
          buffer.writeln('$indent${_indent}pass');
        } else {
          _writeSequence(buffer, block.innerBlocks, depth + 1);
        }

      case BlockType.whileBlock:
        final condition = block.params['condition'] ?? 'benar';
        buffer.writeln('${indent}selama ($condition):');
        if (block.innerBlocks.isEmpty) {
          buffer.writeln('$indent${_indent}pass');
        } else {
          _writeSequence(buffer, block.innerBlocks, depth + 1);
        }

      case BlockType.ifBlock:
        final condition = block.params['condition'] ?? 'benar';
        buffer.writeln('${indent}jika ($condition):');
        if (block.innerBlocks.isEmpty) {
          buffer.writeln('$indent${_indent}pass');
        } else {
          _writeSequence(buffer, block.innerBlocks, depth + 1);
        }

      case BlockType.ifElseBlock:
        final condition = block.params['condition'] ?? 'benar';
        buffer.writeln('${indent}jika ($condition):');
        if (block.innerBlocks.isEmpty) {
          buffer.writeln('$indent${_indent}pass');
        } else {
          _writeSequence(buffer, block.innerBlocks, depth + 1);
        }
        buffer.writeln('${indent}lainnya:');
        if (block.elseBlocks.isEmpty) {
          buffer.writeln('$indent${_indent}pass');
        } else {
          _writeSequence(buffer, block.elseBlocks, depth + 1);
        }

      case BlockType.mathAddBlock:
        final a = block.params['a'] ?? '0';
        final b = block.params['b'] ?? '0';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = $a + $b');

      case BlockType.mathSubBlock:
        final a = block.params['a'] ?? '0';
        final b = block.params['b'] ?? '0';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = $a - $b');

      case BlockType.mathMulBlock:
        final a = block.params['a'] ?? '0';
        final b = block.params['b'] ?? '0';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = $a × $b');

      case BlockType.mathDivBlock:
        final a = block.params['a'] ?? '0';
        final b = block.params['b'] ?? '0';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = $a ÷ $b');

      case BlockType.compareBlock:
        final a = block.params['a'] ?? '0';
        final op = block.params['op'] ?? '>';
        final b = block.params['b'] ?? '0';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = ($a $op $b)');

      case BlockType.andBlock:
        final a = block.params['a'] ?? 'cek1';
        final b = block.params['b'] ?? 'cek2';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = $a DAN $b');

      case BlockType.orBlock:
        final a = block.params['a'] ?? 'cek1';
        final b = block.params['b'] ?? 'cek2';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = $a ATAU $b');

      case BlockType.notBlock:
        final a = block.params['a'] ?? 'cek';
        final result = block.params['result'] ?? 'hasil';
        buffer.writeln('${indent}$result = BUKAN $a');
    }
  }
}
