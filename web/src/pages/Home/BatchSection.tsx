import { SectionHeader } from '../../components/shared/SectionHeader'
import { BatchCard } from '../../components/shared/BatchCard'
import { BATCHES } from '../../data/batches'

export function BatchSection() {
  const preview = BATCHES.slice(0, 3)

  return (
    <section className="py-24 px-12 bg-white">
      <div className="max-w-[1200px] mx-auto">
        <SectionHeader
          eyebrow="Kelas Batch"
          title={<>Kelas <em className="italic text-brand-500">Terjadwal</em><br />Mulai Segera</>}
          seeAll={{ label: 'Lihat Semua Batch', to: '/batch' }}
        />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
          {preview.map(batch => <BatchCard key={batch.id} batch={batch} />)}
        </div>
      </div>
    </section>
  )
}
