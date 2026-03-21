import 'package:equatable/equatable.dart';
import 'block_type.dart';

/// Parameter default untuk setiap BlockType.
Map<String, String> defaultParamsFor(BlockType type) {
  switch (type) {
    case BlockType.printBlock:
      return {'text': 'Hello, World!'};
    case BlockType.askBlock:
      return {'question': 'Masukkan angka:', 'variable': 'input'};
    case BlockType.setVarBlock:
      return {'name': 'x', 'value': '0'};
    case BlockType.changeVarBlock:
      return {'name': 'x', 'delta': '1'};
    case BlockType.repeatBlock:
      return {'count': '3'};
    case BlockType.whileBlock:
      return {'condition': 'x < 10'};
    case BlockType.ifBlock:
      return {'condition': 'x > 0'};
    case BlockType.ifElseBlock:
      return {'condition': 'x > 0'};
    case BlockType.mathAddBlock:
      return {'a': 'x', 'b': '1', 'result': 'hasil'};
    case BlockType.mathSubBlock:
      return {'a': 'x', 'b': '1', 'result': 'hasil'};
    case BlockType.mathMulBlock:
      return {'a': 'x', 'b': '2', 'result': 'hasil'};
    case BlockType.mathDivBlock:
      return {'a': 'x', 'b': '2', 'result': 'hasil'};
    case BlockType.compareBlock:
      return {'a': 'x', 'op': '>', 'b': '0', 'result': 'cek'};
    case BlockType.andBlock:
      return {'a': 'cek1', 'b': 'cek2', 'result': 'hasil'};
    case BlockType.orBlock:
      return {'a': 'cek1', 'b': 'cek2', 'result': 'hasil'};
    case BlockType.notBlock:
      return {'a': 'cek', 'result': 'hasil'};
    default:
      return {};
  }
}

/// Entitas block tunggal pada canvas.
///
/// Block membentuk tree — [innerBlocks] adalah body utama (untuk if/loop),
/// [elseBlocks] adalah body else (untuk if-else).
class Block extends Equatable {
  final String id;
  final BlockType type;
  final Map<String, String> params;
  final List<Block> innerBlocks;
  final List<Block> elseBlocks;

  const Block({
    required this.id,
    required this.type,
    this.params = const {},
    this.innerBlocks = const [],
    this.elseBlocks = const [],
  });

  /// Salin block dengan field yang diubah.
  Block copyWith({
    String? id,
    BlockType? type,
    Map<String, String>? params,
    List<Block>? innerBlocks,
    List<Block>? elseBlocks,
  }) {
    return Block(
      id: id ?? this.id,
      type: type ?? this.type,
      params: params ?? this.params,
      innerBlocks: innerBlocks ?? this.innerBlocks,
      elseBlocks: elseBlocks ?? this.elseBlocks,
    );
  }

  /// Update satu parameter.
  Block withParam(String key, String value) {
    return copyWith(params: {...params, key: value});
  }

  /// Tambah block anak di body utama.
  Block addInnerBlock(Block block) {
    return copyWith(innerBlocks: [...innerBlocks, block]);
  }

  /// Tambah block anak di body else.
  Block addElseBlock(Block block) {
    return copyWith(elseBlocks: [...elseBlocks, block]);
  }

  /// Hapus block anak dari body utama.
  Block removeInnerBlock(String blockId) {
    return copyWith(
      innerBlocks: innerBlocks.where((b) => b.id != blockId).toList(),
    );
  }

  @override
  List<Object?> get props => [id, type, params, innerBlocks, elseBlocks];
}
