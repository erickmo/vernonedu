export interface FaqItem {
  id: string
  question: string
  answer: string
}

export const FAQS: FaqItem[] = [
  {
    id: 'batch',
    question: 'Apa itu Kelas Batch?',
    answer: 'Kelas Batch adalah kelas terjadwal yang dibuka dalam periode tertentu. Peserta mendaftar sebelum batch dimulai, lalu belajar bersama dalam grup kecil dengan jadwal tetap.',
  },
  {
    id: 'talent-pool',
    question: 'Apa itu Talent Pool VernonEdu?',
    answer: 'Alumni VernonEdu yang telah menyelesaikan kursus dan mendapatkan sertifikat akan masuk ke database talent pool kami. Perusahaan mitra dapat mengakses pool ini untuk menemukan kandidat yang sudah terverifikasi kompetensinya.',
  },
  {
    id: 'certification',
    question: 'Sertifikasi apa yang dikeluarkan VernonEdu?',
    answer: 'VernonEdu mengeluarkan sertifikat berbasis SKKNI (Standar Kompetensi Kerja Nasional Indonesia) dan terakreditasi BNSP (Badan Nasional Sertifikasi Profesi). Semua sertifikat dapat diverifikasi secara digital.',
  },
  {
    id: 'online',
    question: 'Apakah kelas tersedia secara online?',
    answer: 'Ya, banyak kursus dan kelas batch tersedia online. Ketersediaan tergantung kursus — cek detail di halaman masing-masing program.',
  },
  {
    id: 'b2b',
    question: 'Bagaimana cara institusi mendaftar sebagai mitra?',
    answer: 'Isi form di halaman Mitra atau hubungi langsung tim partnership kami. Kami akan mengatur pertemuan untuk membahas kebutuhan institusi Anda.',
  },
]
