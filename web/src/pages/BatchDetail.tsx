import { useParams, Link } from 'react-router-dom'
import { BATCHES } from '../data/batches'

const COLOR_MAP = {
  purple:   'from-brand-50 to-brand-100',
  lavender: 'from-violet-50 to-violet-100',
  rose:     'from-pink-50 to-pink-100',
} as const

const MODE_BADGE: Record<string, string> = {
  online:  'bg-emerald-100 text-emerald-800',
  offline: 'bg-amber-100 text-amber-800',
}

export function BatchDetail() {
  const { id } = useParams<{ id: string }>()
  const batch = BATCHES.find(b => b.id === id)

  if (!batch) {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="text-center">
          <p className="text-4xl font-black text-brand-200 mb-3">404</p>
          <p className="text-brand-500 font-semibold mb-6">Batch tidak ditemukan</p>
          <Link to="/batch" className="text-sm text-slate-400 hover:text-brand-500">
            ← Kembali ke Kelas Batch
          </Link>
        </div>
      </div>
    )
  }

  const seatsLabel = batch.seatsLeft !== null
    ? `${batch.seatsLeft} kursi tersisa`
    : 'Masih tersedia'

  return (
    <div className="min-h-screen bg-white">
      <div className={`pt-24 pb-20 px-12 bg-gradient-to-br ${COLOR_MAP[batch.colorVariant]}`}>
        <div className="max-w-[1200px] mx-auto">
          <Link to="/batch" className="text-[0.78rem] font-semibold text-brand-500 hover:text-brand-700 mb-8 inline-block">
            ← Semua Kelas Batch
          </Link>
          <div className="flex gap-3 mb-5 flex-wrap">
            <span className="text-xs font-bold px-3 py-1 rounded-full bg-white/70 text-brand-500">
              {batch.category}
            </span>
            <span className={`text-xs font-bold px-3 py-1 rounded-full ${MODE_BADGE[batch.mode]}`}>
              {batch.mode === 'online' ? 'Online' : 'Offline'}
            </span>
          </div>
          <div className="flex items-start gap-8">
            <div className="text-7xl">{batch.emoji}</div>
            <div>
              <h1 className="text-[2.25rem] font-black tracking-tight text-brand-900 leading-tight mb-2">
                {batch.name}
              </h1>
              <p className="text-brand-600 font-bold text-base mb-1">Batch {batch.batchNumber}</p>
              <p className="text-slate-600 text-[1rem] leading-relaxed max-w-[560px]">
                {batch.description}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="px-12 py-16">
        <div className="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="md:col-span-2 space-y-6">
            <div className="border border-brand-100 rounded-2xl p-8">
              <h2 className="text-lg font-black text-brand-900 mb-4">Tentang Kelas Ini</h2>
              <p className="text-slate-600 text-[1rem] leading-relaxed">{batch.description}</p>
            </div>
          </div>

          <div className="space-y-4">
            <div className="border border-brand-100 rounded-2xl p-6">
              <h3 className="text-sm font-black text-brand-900 mb-4 uppercase tracking-wide">Detail Batch</h3>
              <dl className="space-y-3">
                <div>
                  <dt className="text-xs font-bold text-slate-400 uppercase tracking-wide">Tanggal Mulai</dt>
                  <dd className="text-base font-bold text-brand-900 mt-0.5">{batch.startDate}</dd>
                </div>
                <div>
                  <dt className="text-xs font-bold text-slate-400 uppercase tracking-wide">Mode</dt>
                  <dd className="text-base font-bold text-brand-900 mt-0.5 capitalize">{batch.mode}</dd>
                </div>
                <div>
                  <dt className="text-xs font-bold text-slate-400 uppercase tracking-wide">Ketersediaan</dt>
                  <dd className="text-base font-bold text-brand-500 mt-0.5">{seatsLabel}</dd>
                </div>
              </dl>
              <Link
                to="/register"
                className="mt-6 block w-full py-3 bg-brand-500 text-white text-sm font-bold text-center rounded-xl hover:bg-brand-600 transition-colors"
              >
                Daftar Sekarang
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
