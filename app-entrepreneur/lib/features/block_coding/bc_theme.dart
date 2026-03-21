import 'package:flutter/material.dart';

/// Konstanta warna khusus block coding editor (dark theme).
abstract class BcColors {
  static const Color background = Color(0xFF0F0E17);
  static const Color surface = Color(0xFF1A1927);
  static const Color surfaceVariant = Color(0xFF252438);
  static const Color canvasBackground = Color(0xFF0A0914);
  static const Color canvasGrid = Color(0xFF18172A);
  static const Color border = Color(0xFF2D2C3F);
  static const Color borderLight = Color(0xFF3D3C50);

  static const Color primary = Color(0xFF6C5CE7);
  static const Color accent = Color(0xFF00CEFF);

  static const Color textPrimary = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFB2BEC3);
  static const Color textHint = Color(0xFF636E72);
  static const Color textDisabled = Color(0xFF4A4A5A);

  static const Color success = Color(0xFF1DD1A1);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFECA57);
  static const Color info = Color(0xFF54A0FF);

  static const Color codeBg = Color(0xFF0D1117);
  static const Color codeString = Color(0xFFA5D6FF);

  static const Color overlay = Color(0x80000000);

  // Block-specific colors
  static const Color blockControl = Color(0xFFFF9F43);
  static const Color blockControlDark = Color(0xFFE08826);
}

/// Konstanta teks khusus block coding.
abstract class BcStrings {
  static const String editorTitle = 'Block Editor';
  static const String editorPalette = 'Blok';
  static const String editorRun = 'Jalankan';
  static const String editorRunning = 'Menjalankan...';
  static const String editorReset = 'Reset';
  static const String editorOutput = 'Output';
  static const String blockOr = 'lainnya';
  static const String editorClearCanvas = 'Bersihkan Canvas';
  static const String editorDragHint = 'Ketuk + untuk mulai menambah blok';
  static const String editorSuccess = 'Program selesai!';
  static const String editorShowCode = 'Lihat Kode';
  static const String editorHideCode = 'Sembunyikan Kode';
  static const String editorCodePreview = 'Pratinjau Kode';

  static const String challengeHint = 'Petunjuk';
  static const String challengeCompleted = 'Tantangan Selesai! 🎉';
  static const String challengeExpected = 'Output yang diharapkan:';
  static const String challengeCorrect = 'Benar! Output kamu sesuai!';
  static const String challengeBack = 'Kembali';

  static const String errorExecution = 'Program error saat dijalankan';
  static const String errorMaxIterations = 'Program berhenti: terlalu banyak pengulangan';

  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String delete = 'Hapus';
}

/// Konstanta dimensi khusus block coding.
abstract class BcDimensions {
  static const double blockHeight = 56.0;
  static const double blockBorderRadius = 10.0;
  static const double blockConnectorSize = 12.0;
  static const double blockIndent = 24.0;
  static const double blockShadowBlur = 8.0;
  static const double blockPaletteItemHeight = 48.0;
  static const double canvasBlockSpacing = 4.0;
  static const double canvasMinHeight = 400.0;
  static const double paletteCategoryTabHeight = 40.0;
  static const double paletteBottomSheetHeight = 300.0;
  static const double paletteItemSpacing = 6.0;
  static const double codePanelHeight = 240.0;
  static const double outputPanelHeight = 200.0;

  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double radiusXs = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusFull = 100.0;

  static const double iconXs = 14.0;
  static const double iconS = 18.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXl = 48.0;
}
