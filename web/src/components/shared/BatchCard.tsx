import { Link } from 'react-router-dom'
import { BatchItem } from '../../data/batches'

const COLOR_MAP = {
  purple:   'from-brand-50 to-brand-100',
  lavender: 'from-violet-50 to-violet-100',
  rose:     'from-pink-50 to-pink-100',
} as const

const MODE_BADGE: Record<string, string> = {
  online:  'bg-emerald-100 text-emerald-800',
  offline: 'bg-amber-100  text-amber-800',
}

interface BatchCardProps {
  batch: BatchItem
}

export function BatchCard({ batch }: BatchCardProps) {
  const seatsLabel = batch.seatsLeft !== null
    ? `${batch.seatsLeft} kursi tersisa`
    : 'Masih tersedia'

  return (
    <div className="border border-brand-100 rounded-2xl overflow-hidden bg-white hover:shadow-lg hover:-translate-y-1 transition-all duration-200">
      <Link to={`/batch/${batch.id}`} className="block">
        <div className={`h-40 flex items-center justify-center text-6xl bg-gradient-to-br ${COLOR_MAP[batch.colorVariant]}`}>
          {batch.emoji}
        </div>
        <div className="p-6 pb-3">
          <div className="flex gap-2 mb-3 flex-wrap">
            <span className="text-xs font-bold px-3 py-1 rounded-full bg-brand-50 text-brand-500">
              {batch.category}
            </span>
            <span className={`text-xs font-bold px-3 py-1 rounded-full ${MODE_BADGE[batch.mode]}`}>
              {batch.mode === 'online' ? 'Online' : 'Offline'}
            </span>
          </div>
          <h3 className="text-base font-black text-brand-900 mb-1 leading-tight">
            {batch.name} — Batch {batch.batchNumber}
          </h3>
          <p className="text-sm text-slate-500 leading-relaxed mb-4">{batch.description}</p>
          <div className="flex justify-between items-center">
            <p className="text-sm text-slate-400">
              Mulai <strong className="text-brand-900 font-bold">{batch.startDate}</strong>
            </p>
            <span className="text-xs font-bold text-brand-500 bg-brand-50 px-3 py-1 rounded-full">
              {seatsLabel}
            </span>
          </div>
        </div>
      </Link>
      <div className="px-6 pb-6 pt-3">
        <Link
          to="/register"
          className="block w-full py-2.5 bg-brand-500 text-white text-sm font-bold text-center rounded-xl hover:bg-brand-600 transition-colors"
        >
          Daftar Sekarang
        </Link>
      </div>
    </div>
  )
}
