class AppStrings {
  AppStrings._();

  // Common
  static const String loading = 'Memuat...';
  static const String retry = 'Coba Lagi';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String delete = 'Hapus';
  static const String edit = 'Edit';
  static const String add = 'Tambah';
  static const String search = 'Cari...';
  static const String filter = 'Filter';
  static const String export = 'Export';
  static const String confirm = 'Konfirmasi';
  static const String back = 'Kembali';
  static const String next = 'Lanjut';
  static const String submit = 'Simpan';
  static const String close = 'Tutup';
  static const String view = 'Lihat';
  static const String active = 'Aktif';
  static const String inactive = 'Tidak Aktif';
  static const String all = 'Semua';

  // Auth
  static const String login = 'Masuk';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String loginTitle = 'Selamat Datang';
  static const String loginSubtitle = 'VernonEdu Management Dashboard';

  // Navigation / Menu
  static const String navDashboard = 'Dashboard';
  static const String navCourse = 'Course';
  static const String navCourseBatch = 'Batch Course';
  static const String navEnrollment = 'Enrollment';
  static const String navEvaluation = 'Evaluasi';
  static const String navStudent = 'Siswa';
  static const String navCertificate = 'Sertifikat';
  static const String navPayment = 'Pembayaran';
  static const String navDepartment = 'Departemen';
  static const String navAccounting = 'Akuntansi';
  static const String navHrm = 'SDM';
  static const String navProject = 'Proyek';
  static const String navCrm = 'CRM';
  static const String navSettings = 'Pengaturan';
  static const String navPartners = 'Partner & MOU';
  static const String navLeads = 'Leads';
  static const String navLocations = 'Lokasi & Ruangan';
  static const String navBusinessDev = 'Business Dev';
  static const String navNotifications = 'Notifikasi';
  static const String navApprovals = 'Persetujuan';

  // Errors
  static const String errorGeneral = 'Terjadi kesalahan. Silakan coba lagi.';
  static const String errorNetwork = 'Tidak ada koneksi internet.';
  static const String errorServer = 'Server sedang bermasalah. Coba lagi nanti.';
  static const String errorUnauthorized = 'Sesi Anda telah berakhir. Silakan login kembali.';
  static const String errorNotFound = 'Data tidak ditemukan.';
  static const String errorTimeout = 'Koneksi timeout. Coba lagi.';
  static const String errorForbidden = 'Anda tidak memiliki akses ke halaman ini.';

  // Empty States
  static const String emptyData = 'Belum ada data.';
  static const String emptySearch = 'Hasil pencarian tidak ditemukan.';

  // SDM / HRM — List Page
  static const String sdmPageTitle = 'Manajemen SDM';
  static const String sdmPageSubtitle =
      'Kelola tenaga pengajar dan fasilitator VernonEdu';
  static const String sdmSearchHint = 'Cari nama atau email SDM...';
  static const String sdmFilterRole = 'Peran';
  static const String sdmFilterStatus = 'Status';
  static const String sdmSummaryTotal = 'Total SDM';
  static const String sdmSummaryActive = 'SDM Aktif';
  static const String sdmSummaryCreators = 'Course Creator';
  static const String sdmSummaryMentors = 'Fasilitator';

  // SDM — Status
  static const String sdmStatusActive = 'Aktif';
  static const String sdmStatusInactive = 'Tidak Aktif';
  static const String sdmStatusOnLeave = 'Cuti';

  // SDM — Stats
  static const String sdmStatStudents = 'Siswa';
  static const String sdmStatPrograms = 'Program';
  static const String sdmStatRating = 'Rating';
  static const String sdmStatCompletion = 'Completion';
  static const String sdmStatYearsActive = 'Tahun Aktif';

  // SDM — Detail Page
  static const String sdmDetail = 'Detail SDM';
  static const String sdmDetailLoading = 'Memuat profil...';

  // SDM — Program Tab
  static const String sdmProgramStatusActive = 'Aktif';
  static const String sdmProgramStatusUpcoming = 'Akan Datang';
  static const String sdmProgramStatusCompleted = 'Selesai';
  static const String sdmNoProgramData = 'Belum ada data program.';

  // SDM — CV Tab
  static const String sdmCvSummary = 'Tentang';
  static const String sdmCvEducation = 'Pendidikan';
  static const String sdmCvWorkExperience = 'Pengalaman Kerja';
  static const String sdmCvSkills = 'Keahlian';
  static const String sdmCvCertifications = 'Sertifikasi';
  static const String sdmCvLanguages = 'Bahasa';
  static const String sdmCvNoData = 'Belum ada data.';

  // SDM — Class History Tab
  static const String sdmClassStudents = 'Siswa';
  static const String sdmClassCompletion = 'Selesai';
  static const String sdmClassRating = 'Rating';
  static const String sdmNoClassData = 'Belum ada riwayat kelas.';

  // SDM — Payment Tab
  static const String sdmPaymentTotal = 'Total Pembayaran Diterima';
  static const String sdmPaymentDescription = 'Keterangan';
  static const String sdmPaymentType = 'Jenis';
  static const String sdmPaymentAmount = 'Jumlah';
  static const String sdmPaymentStatus = 'Status';
  static const String sdmNoPaymentData = 'Belum ada riwayat pembayaran.';

  // SDM — Evaluation Tab
  static const String sdmEvalAvgScore = 'Rata-rata';
  static const String sdmNoEvaluationData = 'Belum ada catatan evaluasi.';

  // SDM — Schedule Tab
  static const String sdmScheduleLegend = 'Keterangan Warna';
  static const String sdmScheduleUpcoming = 'Mendatang';
  static const String sdmSchedulePast = 'Selesai';
  static const String sdmNoScheduleData = 'Belum ada jadwal.';

  // SDM — Documents Tab
  static const String sdmDocDownload = 'Unduh';
  static const String sdmNoDocumentData = 'Belum ada dokumen.';
}
