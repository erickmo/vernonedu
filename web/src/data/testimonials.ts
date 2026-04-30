export interface Testimonial {
  id: string
  quote: string
  name: string
  role: string
  featured: boolean
}

export const TESTIMONIALS: Testimonial[] = [
  {
    id: 't1',
    quote: 'Program-nya sangat relevan dengan industri. Saya dapat kerja di agency desain dua minggu setelah lulus — langsung lewat talent pool VernonEdu.',
    name: 'Rina Kusuma',
    role: 'Alumni Desain Grafis · Jakarta',
    featured: true,
  },
  {
    id: 't2',
    quote: 'Kerjasama B2B sangat fleksibel. Kurikulum disesuaikan dengan kebutuhan mahasiswa kami.',
    name: 'Dr. Hendra Wijaya',
    role: 'Dekan, Universitas Nusantara',
    featured: false,
  },
  {
    id: 't3',
    quote: 'Kelas batch English-nya sangat worth it. Langsung praktek dari sesi pertama.',
    name: 'Ayu Permata',
    role: 'Peserta Batch English · Bandung',
    featured: false,
  },
]
