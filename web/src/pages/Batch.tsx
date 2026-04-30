import { useState } from 'react'
import { BATCHES, DeliveryMode } from '../data/batches'
import { BatchCard } from '../components/shared/BatchCard'

const ALL_CATEGORIES = ['Semua', ...Array.from(new Set(BATCHES.map(b => b.category)))]
const ALL_MODES: (DeliveryMode | 'semua')[] = ['semua', 'online', 'offline']

export function Batch() {
  const [category, setCategory] = useState('Semua')
  const [mode, setMode] = useState<DeliveryMode | 'semua'>('semua')

  const filtered = BATCHES.filter(b => {
    const catOk  = category === 'Semua' || b.category === category
    const modeOk = mode === 'semua' || b.mode === mode
    return catOk && modeOk
  })

  return (
    <div className="pt-24 min-h-screen bg-white">
      {/* header */}
      <div className="bg-brand-900 px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">
            Jadwal Kelas
          </p>
          <h1 className="text-[2.5rem] font-black tracking-[-2px] text-white leading-tight">
            Semua Kelas Batch
          </h1>
          <p className="text-[0.9rem] text-white/45 mt-3 max-w-[480px] leading-relaxed">
            Kelas terjadwal dengan angkatan bersama. Daftar sebelum batch mulai.
          </p>
        </div>
      </div>

      {/* filters */}
      <div className="border-b border-brand-100 px-12 py-4 bg-white sticky top-16 z-10">
        <div className="max-w-[1200px] mx-auto flex gap-3 flex-wrap items-center">
          <span className="text-[0.72rem] font-bold text-slate-400 mr-2">Kategori:</span>
          {ALL_CATEGORIES.map(cat => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`text-[0.78rem] font-bold px-4 py-1.5 rounded-full transition-colors ${
                category === cat
                  ? 'bg-brand-500 text-white'
                  : 'bg-brand-50 text-brand-500 hover:bg-brand-100'
              }`}
            >
              {cat}
            </button>
          ))}
          <span className="text-[0.72rem] font-bold text-slate-400 ml-4 mr-2">Mode:</span>
          {ALL_MODES.map(m => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`text-[0.78rem] font-bold px-4 py-1.5 rounded-full capitalize transition-colors ${
                mode === m
                  ? 'bg-brand-500 text-white'
                  : 'bg-brand-50 text-brand-500 hover:bg-brand-100'
              }`}
            >
              {m}
            </button>
          ))}
        </div>
      </div>

      {/* grid */}
      <div className="px-12 py-16">
        <div className="max-w-[1200px] mx-auto">
          {filtered.length === 0 ? (
            <p className="text-slate-400 text-center py-16">Tidak ada batch yang sesuai filter.</p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {filtered.map(batch => <BatchCard key={batch.id} batch={batch} />)}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
