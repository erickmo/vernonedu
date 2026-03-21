import 'package:flutter/material.dart';

/// Warna khusus untuk block coding (independen dari AppColors utama).
abstract class _BlockColors {
  static const Color control = Color(0xFFFF9F43);
  static const Color controlDark = Color(0xFFE8872B);
  static const Color io = Color(0xFF54A0FF);
  static const Color ioDark = Color(0xFF3880D4);
  static const Color variable = Color(0xFFFF6B6B);
  static const Color variableDark = Color(0xFFE05252);
  static const Color math = Color(0xFFA29BFE);
  static const Color mathDark = Color(0xFF8578E0);
  static const Color logic = Color(0xFF1DD1A1);
  static const Color logicDark = Color(0xFF0BB88A);
}

/// Kategori blok.
enum BlockCategory { control, io, variable, math, logic }

/// Semua jenis blok yang tersedia.
enum BlockType {
  // — Control
  start, end, ifBlock, ifElseBlock, repeatBlock, whileBlock,
  // — I/O
  printBlock, askBlock,
  // — Variables
  setVarBlock, changeVarBlock,
  // — Math
  mathAddBlock, mathSubBlock, mathMulBlock, mathDivBlock,
  // — Logic
  compareBlock, andBlock, orBlock, notBlock,
}

extension BlockTypeX on BlockType {
  String get label {
    const labels = {
      BlockType.start: 'Mulai',
      BlockType.end: 'Selesai',
      BlockType.ifBlock: 'Jika',
      BlockType.ifElseBlock: 'Jika / Lainnya',
      BlockType.repeatBlock: 'Ulangi',
      BlockType.whileBlock: 'Selama',
      BlockType.printBlock: 'Tampilkan',
      BlockType.askBlock: 'Minta Input',
      BlockType.setVarBlock: 'Set Variabel',
      BlockType.changeVarBlock: 'Ubah Variabel',
      BlockType.mathAddBlock: 'Tambah',
      BlockType.mathSubBlock: 'Kurang',
      BlockType.mathMulBlock: 'Kali',
      BlockType.mathDivBlock: 'Bagi',
      BlockType.compareBlock: 'Bandingkan',
      BlockType.andBlock: 'DAN',
      BlockType.orBlock: 'ATAU',
      BlockType.notBlock: 'BUKAN',
    };
    return labels[this] ?? name;
  }

  BlockCategory get category {
    switch (this) {
      case BlockType.start:
      case BlockType.end:
      case BlockType.ifBlock:
      case BlockType.ifElseBlock:
      case BlockType.repeatBlock:
      case BlockType.whileBlock:
        return BlockCategory.control;
      case BlockType.printBlock:
      case BlockType.askBlock:
        return BlockCategory.io;
      case BlockType.setVarBlock:
      case BlockType.changeVarBlock:
        return BlockCategory.variable;
      case BlockType.mathAddBlock:
      case BlockType.mathSubBlock:
      case BlockType.mathMulBlock:
      case BlockType.mathDivBlock:
        return BlockCategory.math;
      case BlockType.compareBlock:
      case BlockType.andBlock:
      case BlockType.orBlock:
      case BlockType.notBlock:
        return BlockCategory.logic;
    }
  }

  Color get color {
    switch (category) {
      case BlockCategory.control: return _BlockColors.control;
      case BlockCategory.io: return _BlockColors.io;
      case BlockCategory.variable: return _BlockColors.variable;
      case BlockCategory.math: return _BlockColors.math;
      case BlockCategory.logic: return _BlockColors.logic;
    }
  }

  Color get darkColor {
    switch (category) {
      case BlockCategory.control: return _BlockColors.controlDark;
      case BlockCategory.io: return _BlockColors.ioDark;
      case BlockCategory.variable: return _BlockColors.variableDark;
      case BlockCategory.math: return _BlockColors.mathDark;
      case BlockCategory.logic: return _BlockColors.logicDark;
    }
  }

  IconData get icon {
    switch (this) {
      case BlockType.start: return Icons.play_circle_filled_rounded;
      case BlockType.end: return Icons.stop_circle_rounded;
      case BlockType.ifBlock: return Icons.call_split_rounded;
      case BlockType.ifElseBlock: return Icons.device_hub_rounded;
      case BlockType.repeatBlock: return Icons.repeat_rounded;
      case BlockType.whileBlock: return Icons.loop_rounded;
      case BlockType.printBlock: return Icons.terminal_rounded;
      case BlockType.askBlock: return Icons.input_rounded;
      case BlockType.setVarBlock: return Icons.data_object_rounded;
      case BlockType.changeVarBlock: return Icons.edit_rounded;
      case BlockType.mathAddBlock: return Icons.add_circle_outline_rounded;
      case BlockType.mathSubBlock: return Icons.remove_circle_outline_rounded;
      case BlockType.mathMulBlock: return Icons.close_rounded;
      case BlockType.mathDivBlock: return Icons.percent_rounded;
      case BlockType.compareBlock: return Icons.compare_arrows_rounded;
      case BlockType.andBlock: return Icons.join_inner_rounded;
      case BlockType.orBlock: return Icons.join_full_rounded;
      case BlockType.notBlock: return Icons.not_interested_rounded;
    }
  }

  bool get hasBody =>
      this == BlockType.ifBlock ||
      this == BlockType.ifElseBlock ||
      this == BlockType.repeatBlock ||
      this == BlockType.whileBlock;

  bool get isSingleton =>
      this == BlockType.start || this == BlockType.end;
}

extension BlockCategoryX on BlockCategory {
  String get label {
    const labels = {
      BlockCategory.control: 'Kontrol',
      BlockCategory.io: 'Input/Output',
      BlockCategory.variable: 'Variabel',
      BlockCategory.math: 'Matematika',
      BlockCategory.logic: 'Logika',
    };
    return labels[this] ?? name;
  }

  Color get color {
    switch (this) {
      case BlockCategory.control: return _BlockColors.control;
      case BlockCategory.io: return _BlockColors.io;
      case BlockCategory.variable: return _BlockColors.variable;
      case BlockCategory.math: return _BlockColors.math;
      case BlockCategory.logic: return _BlockColors.logic;
    }
  }

  List<BlockType> get blocks =>
      BlockType.values.where((t) => t.category == this).toList();
}
