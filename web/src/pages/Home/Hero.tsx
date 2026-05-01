import { Link } from 'react-router-dom'
import { LINKS } from '../../tokens'

export function Hero() {
  return (
    <section
      className="min-h-screen pt-28 flex flex-col relative overflow-hidden"
      style={{
        backgroundImage: `linear-gradient(135deg, rgba(46, 26, 55, 0.82) 0%, rgba(149, 97, 171, 0.70) 100%), url('https://images.unsplash.com/photo-1427504494785-cdafb85e1ef0?ixlib=rb-4.0.3&auto=format&fit=crop&w=2070&q=80')`,
        backgroundSize: 'cover',
        backgroundPosition: 'center',
      }}
    >
      {/* main content */}
      <div className="flex-1 max-w-[1200px] w-full mx-auto px-12 flex items-center py-12">
        {/* left */}
        <div style={{ maxWidth: '600px' }}>
          <div className="inline-flex items-center gap-2 bg-brand-50 border border-brand-100 rounded-full px-4 py-1.5 text-[0.7rem] font-bold text-brand-500 tracking-[1.5px] uppercase mb-6">
            <span className="text-[0.55rem]">●</span>
            Lembaga Pendidikan Informal
          </div>

          <h1 className="text-[clamp(2.75rem,5.5vw,4.25rem)] font-black leading-[1.0] tracking-[-2.5px] text-brand-900 mb-5">
            Belajar Lebih.<br />
            Raih <em className="italic text-brand-500 font-bold">Lebih.</em>
          </h1>

          <p className="text-base text-slate-400 leading-[1.75] max-w-[420px] mb-8">
            Kursus berkualitas, kelas batch terjadwal, dan program kemitraan untuk individu dan institusi di seluruh Indonesia.
          </p>

          <div className="flex items-center gap-4">
            <a
              href={LINKS.register}
              className="bg-brand-500 text-white text-sm font-bold px-7 py-3 rounded-full hover:bg-brand-600 transition-colors"
            >
              Mulai Belajar
            </a>
            <Link
              to="/batch"
              className="border-[1.5px] border-brand-100 text-brand-600 text-sm font-semibold px-6 py-[0.75rem] rounded-full hover:border-brand-300 transition-colors"
            >
              Lihat Kelas Batch ↗
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
