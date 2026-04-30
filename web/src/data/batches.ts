export type DeliveryMode = 'online' | 'offline'

export interface BatchItem {
  id: string
  name: string
  batchNumber: number
  category: string
  mode: DeliveryMode
  emoji: string
  colorVariant: 'purple' | 'lavender' | 'rose'
  description: string
  startDate: string
  seatsLeft: number | null
}

export const BATCHES: BatchItem[] = [
  {
    id: 'english-batch-12',
    name: 'English for Professionals',
    batchNumber: 12,
    category: 'Bahasa',
    mode: 'online',
    emoji: '🗣️',
    colorVariant: 'purple',
    description: 'Komunikasi bisnis, presentasi, dan negosiasi dalam bahasa Inggris. 8 sesi intensif.',
    startDate: '15 Mei 2025',
    seatsLeft: 12,
  },
  {
    id: 'uiux-batch-7',
    name: 'UI/UX Design Fundamentals',
    batchNumber: 7,
    category: 'Desain',
    mode: 'offline',
    emoji: '🎨',
    colorVariant: 'lavender',
    description: 'Figma, user research, wireframing, dan prototyping dari nol. Cocok untuk pemula.',
    startDate: '20 Mei 2025',
    seatsLeft: 5,
  },
  {
    id: 'python-batch-5',
    name: 'Python for Data Analysis',
    batchNumber: 5,
    category: 'Teknologi',
    mode: 'online',
    emoji: '💻',
    colorVariant: 'rose',
    description: 'Pandas, NumPy, visualisasi data, dan studi kasus nyata dari industri.',
    startDate: '1 Juni 2025',
    seatsLeft: null,
  },
]
