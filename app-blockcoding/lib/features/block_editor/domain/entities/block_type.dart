import 'package:flutter/material.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';

/// Kategori blok.
enum BlockCategory {
  control,
  io,
  variable,
  math,
  logic,
}

/// Semua jenis blok yang tersedia.
enum BlockType {
  // — Control
  start,
  end,
  ifBlock,
  ifElseBlock,
  repeatBlock,
  whileBlock,

  // — I/O
  printBlock,
  askBlock,

  // — Variables
  setVarBlock,
  changeVarBlock,

  // — Math
  mathAddBlock,
  mathSubBlock,
  mathMulBlock,
  mathDivBlock,

  // — Logic / Comparison
  compareBlock,
  andBlock,
  orBlock,
  notBlock,
}

/// Extension untuk metadata tiap BlockType.
extension BlockTypeX on BlockType {
  String get label {
    switch (this) {
      case BlockType.start:
        return AppStrings.blockStart;
      case BlockType.end:
        return AppStrings.blockEnd;
      case BlockType.ifBlock:
        return AppStrings.blockIf;
      case BlockType.ifElseBlock:
        return AppStrings.blockIfElse;
      case BlockType.repeatBlock:
        return AppStrings.blockRepeat;
      case BlockType.whileBlock:
        return AppStrings.blockWhile;
      case BlockType.printBlock:
        return AppStrings.blockPrint;
      case BlockType.askBlock:
        return AppStrings.blockAsk;
      case BlockType.setVarBlock:
        return AppStrings.blockSetVar;
      case BlockType.changeVarBlock:
        return AppStrings.blockChangeVar;
      case BlockType.mathAddBlock:
        return AppStrings.blockMathAdd;
      case BlockType.mathSubBlock:
        return AppStrings.blockMathSub;
      case BlockType.mathMulBlock:
        return AppStrings.blockMathMul;
      case BlockType.mathDivBlock:
        return AppStrings.blockMathDiv;
      case BlockType.compareBlock:
        return AppStrings.blockCompare;
      case BlockType.andBlock:
        return AppStrings.blockAnd;
      case BlockType.orBlock:
        return AppStrings.blockOr;
      case BlockType.notBlock:
        return AppStrings.blockNot;
    }
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
      case BlockCategory.control:
        return AppColors.blockControl;
      case BlockCategory.io:
        return AppColors.blockIO;
      case BlockCategory.variable:
        return AppColors.blockVariable;
      case BlockCategory.math:
        return AppColors.blockMath;
      case BlockCategory.logic:
        return AppColors.blockLogic;
    }
  }

  Color get darkColor {
    switch (category) {
      case BlockCategory.control:
        return AppColors.blockControlDark;
      case BlockCategory.io:
        return AppColors.blockIODark;
      case BlockCategory.variable:
        return AppColors.blockVariableDark;
      case BlockCategory.math:
        return AppColors.blockMathDark;
      case BlockCategory.logic:
        return AppColors.blockLogicDark;
    }
  }

  IconData get icon {
    switch (this) {
      case BlockType.start:
        return Icons.play_circle_filled_rounded;
      case BlockType.end:
        return Icons.stop_circle_rounded;
      case BlockType.ifBlock:
        return Icons.call_split_rounded;
      case BlockType.ifElseBlock:
        return Icons.device_hub_rounded;
      case BlockType.repeatBlock:
        return Icons.repeat_rounded;
      case BlockType.whileBlock:
        return Icons.loop_rounded;
      case BlockType.printBlock:
        return Icons.terminal_rounded;
      case BlockType.askBlock:
        return Icons.input_rounded;
      case BlockType.setVarBlock:
        return Icons.data_object_rounded;
      case BlockType.changeVarBlock:
        return Icons.edit_rounded;
      case BlockType.mathAddBlock:
        return Icons.add_circle_outline_rounded;
      case BlockType.mathSubBlock:
        return Icons.remove_circle_outline_rounded;
      case BlockType.mathMulBlock:
        return Icons.close_rounded;
      case BlockType.mathDivBlock:
        return Icons.percent_rounded;
      case BlockType.compareBlock:
        return Icons.compare_arrows_rounded;
      case BlockType.andBlock:
        return Icons.join_inner_rounded;
      case BlockType.orBlock:
        return Icons.join_full_rounded;
      case BlockType.notBlock:
        return Icons.not_interested_rounded;
    }
  }

  /// True jika blok ini bisa memiliki blok anak (body blok).
  bool get hasBody {
    switch (this) {
      case BlockType.ifBlock:
      case BlockType.ifElseBlock:
      case BlockType.repeatBlock:
      case BlockType.whileBlock:
        return true;
      default:
        return false;
    }
  }

  /// True jika blok ini hanya satu dalam program (start/end).
  bool get isSingleton {
    return this == BlockType.start || this == BlockType.end;
  }
}

/// Extension untuk BlockCategory.
extension BlockCategoryX on BlockCategory {
  String get label {
    switch (this) {
      case BlockCategory.control:
        return AppStrings.catControl;
      case BlockCategory.io:
        return AppStrings.catIO;
      case BlockCategory.variable:
        return AppStrings.catVariable;
      case BlockCategory.math:
        return AppStrings.catMath;
      case BlockCategory.logic:
        return AppStrings.catLogic;
    }
  }

  Color get color {
    switch (this) {
      case BlockCategory.control:
        return AppColors.blockControl;
      case BlockCategory.io:
        return AppColors.blockIO;
      case BlockCategory.variable:
        return AppColors.blockVariable;
      case BlockCategory.math:
        return AppColors.blockMath;
      case BlockCategory.logic:
        return AppColors.blockLogic;
    }
  }

  List<BlockType> get blocks {
    return BlockType.values.where((t) => t.category == this).toList();
  }
}
