export interface BlogPost {
  id: string
  slug: string
  category: string
  title: string
  excerpt: string
  date: string
  readMinutes: number
  emoji: string
  colorVariant: 'a' | 'b' | 'c'
  featured: boolean
  content: string
}

export const BLOG_POSTS: BlogPost[] = [
  {
    id: 'bp1',
    slug: '5-skill-paling-dicari-2025',
    category: 'Tips Karier',
    title: '5 Skill yang Paling Dicari Perusahaan di 2025 — dan Cara Menguasainya',
    excerpt: 'Data terbaru dari LinkedIn dan Jobstreet menunjukkan pergeseran signifikan di dunia kerja. Skill teknis saja tidak cukup...',
    date: '12 April 2025',
    readMinutes: 5,
    emoji: '✍️',
    colorVariant: 'a',
    featured: true,
    content: 'Artikel lengkap tentang 5 skill yang paling dicari di 2025...',
  },
  {
    id: 'bp2',
    slug: 'kenapa-kelas-batch-lebih-efektif',
    category: 'Kelas Batch',
    title: 'Kenapa Kelas Batch Lebih Efektif dari Kursus Mandiri?',
    excerpt: 'Belajar bersama angkatan membuat progres lebih terstruktur dan konsisten...',
    date: '8 April 2025',
    readMinutes: 3,
    emoji: '🎓',
    colorVariant: 'b',
    featured: false,
    content: 'Artikel tentang keefektifan kelas batch...',
  },
  {
    id: 'bp3',
    slug: 'apa-itu-skkni',
    category: 'Sertifikasi',
    title: 'Apa Itu SKKNI dan Mengapa Penting untuk Karier Anda?',
    excerpt: 'Standar Kompetensi Kerja Nasional Indonesia menjadi acuan rekrutmen di banyak industri...',
    date: '2 April 2025',
    readMinutes: 4,
    emoji: '📊',
    colorVariant: 'c',
    featured: false,
    content: 'Artikel tentang SKKNI dan BNSP...',
  },
]
