/// Semua konstanta string aplikasi.
///
/// Jangan gunakan string literal di luar file ini.
abstract class AppStrings {
  // — App
  static const String appName = 'BlockCode';
  static const String appTagline = 'Belajar coding dengan cara yang menyenangkan';

  // — Onboarding
  static const String onboarding1Title = 'Apa itu Block Coding?';
  static const String onboarding1Desc =
      'Block coding adalah cara belajar pemrograman menggunakan blok-blok visual yang bisa disusun seperti puzzle.';
  static const String onboarding2Title = 'Susun Blok, Buat Program';
  static const String onboarding2Desc =
      'Pilih blok dari palette, letakkan di canvas, lalu susun sesuai logika yang kamu inginkan.';
  static const String onboarding3Title = 'Jalankan & Lihat Hasilnya';
  static const String onboarding3Desc =
      'Tekan tombol Run untuk menjalankan program dan lihat outputnya secara langsung!';
  static const String onboardingStart = 'Mulai Belajar';
  static const String onboardingSkip = 'Lewati';
  static const String onboardingNext = 'Selanjutnya';

  // — Home
  static const String homeGreeting = 'Halo, Pelajar! 👋';
  static const String homeSubtitle = 'Pilih tantangan untuk mulai coding';
  static const String homeChallenges = 'Tantangan';
  static const String homeProgress = 'Progres Belajar';
  static const String homeCompleted = 'Selesai';
  static const String homeContinue = 'Lanjut';
  static const String homeStart = 'Mulai';
  static const String homeAllCategories = 'Semua Kategori';

  // — Block Categories
  static const String catControl = 'Kontrol';
  static const String catIO = 'Input/Output';
  static const String catVariable = 'Variabel';
  static const String catMath = 'Matematika';
  static const String catLogic = 'Logika';

  // — Block Names
  static const String blockStart = 'Mulai';
  static const String blockEnd = 'Selesai';
  static const String blockIf = 'Jika';
  static const String blockIfElse = 'Jika / Lainnya';
  static const String blockRepeat = 'Ulangi';
  static const String blockWhile = 'Selama';
  static const String blockPrint = 'Tampilkan';
  static const String blockAsk = 'Minta Input';
  static const String blockSetVar = 'Set Variabel';
  static const String blockChangeVar = 'Ubah Variabel';
  static const String blockMathAdd = 'Tambah';
  static const String blockMathSub = 'Kurang';
  static const String blockMathMul = 'Kali';
  static const String blockMathDiv = 'Bagi';
  static const String blockCompare = 'Bandingkan';
  static const String blockAnd = 'DAN';
  static const String blockOr = 'ATAU';
  static const String blockNot = 'BUKAN';

  // — Block Editor
  static const String editorTitle = 'Block Editor';
  static const String editorPalette = 'Blok';
  static const String editorCanvas = 'Canvas';
  static const String editorCode = 'Kode';
  static const String editorRun = 'Jalankan';
  static const String editorReset = 'Reset';
  static const String editorOutput = 'Output';
  static const String editorClearCanvas = 'Bersihkan Canvas';
  static const String editorDragHint = 'Seret blok ke sini untuk mulai';
  static const String editorRunning = 'Menjalankan...';
  static const String editorSuccess = 'Program selesai!';
  static const String editorCodePreview = 'Pratinjau Kode';
  static const String editorShowCode = 'Lihat Kode';
  static const String editorHideCode = 'Sembunyikan Kode';

  // — Challenge
  static const String challengeTitle = 'Tantangan';
  static const String challengeCompleted = 'Tantangan Selesai!';
  static const String challengeLevel = 'Level';
  static const String challengeHint = 'Petunjuk';
  static const String challengeExpected = 'Output yang diharapkan:';
  static const String challengeYourOutput = 'Output kamu:';
  static const String challengeCorrect = 'Benar! Kamu berhasil!';
  static const String challengeWrong = 'Belum tepat. Coba lagi!';
  static const String challengeNext = 'Tantangan Berikutnya';
  static const String challengeBack = 'Kembali ke Daftar';

  // — Errors
  static const String errorGeneral = 'Terjadi kesalahan. Coba lagi.';
  static const String errorExecution = 'Program error saat dijalankan';
  static const String errorMaxIterations = 'Program berhenti: terlalu banyak pengulangan (kemungkinan infinite loop)';
  static const String errorDivByZero = 'Error: tidak bisa membagi dengan nol';
  static const String errorUndefinedVar = 'Error: variabel belum didefinisikan';
  static const String errorNoStartBlock = 'Tambahkan blok "Mulai" terlebih dahulu';
  static const String errorNoEndBlock = 'Tambahkan blok "Selesai" terlebih dahulu';

  // — Common
  static const String ok = 'OK';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String delete = 'Hapus';
  static const String back = 'Kembali';
  static const String loading = 'Memuat...';
  static const String empty = 'Belum ada data';
}
