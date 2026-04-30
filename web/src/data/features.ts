export interface Feature {
  id: string
  icon: string
  title: string
  description: string
}

export const FEATURES: Feature[] = [
  {
    id: 'curriculum',
    icon: '📋',
    title: 'Kurikulum Relevan Industri',
    description: 'Dirancang bersama praktisi, diperbarui secara berkala sesuai kebutuhan pasar kerja.',
  },
  {
    id: 'delivery',
    icon: '🌐',
    title: 'Online & Offline',
    description: 'Fleksibel belajar dari mana saja atau hadir langsung di cabang terdekat.',
  },
  {
    id: 'certification',
    icon: '🏆',
    title: 'Sertifikasi BNSP & SKKNI',
    description: 'Sertifikat terverifikasi digital berbasis standar nasional, diakui oleh industri dan mitra kami.',
  },
  {
    id: 'format',
    icon: '👤',
    title: 'Regular & Private Class',
    description: 'Pilih belajar dalam grup atau sesi 1-on-1 intensif sesuai kebutuhan Anda.',
  },
  {
    id: 'talent-pool',
    icon: '🎯',
    title: 'Talent Pool Alumni',
    description: 'Alumni VernonEdu masuk ke database talent pool kami — terhubung langsung dengan perusahaan mitra yang aktif mencari kandidat berkompeten.',
  },
]
