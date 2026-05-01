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
      <div className="flex-1 max-w-[1200px] w-full mx-auto px-12 flex items-start py-12">
        {/* left */}
        <div style={{ maxWidth: '600px' }}>
          <div className="inline-flex items-center gap-2 rounded-full px-5 py-3.5 text-xs font-bold uppercase mb-7 backdrop-blur-lg" style={{ backgroundColor: 'rgba(255,255,255,0.12)', color: 'rgba(255,255,255,0.85)', letterSpacing: '1.5px' }}>
            <span className="text-[0.55rem]">●</span>
            Lembaga Pendidikan Informal
          </div>

          <h1 className="text-[3.5rem] font-black leading-[1.05] tracking-tight text-white mb-6">
            Belajar Lebih.<br />
            <em className="italic text-[#e0b7ff] font-bold">Raih Lebih.</em>
          </h1>

          <p className="text-lg leading-relaxed max-w-[500px] mb-8" style={{ color: 'rgba(255,255,255,0.80)', fontWeight: '400' }}>
            Kursus berkualitas, kelas batch terjadwal, dan program kemitraan untuk individu dan institusi di seluruh Indonesia.
          </p>

          <div className="flex items-center gap-5 flex-wrap">
            <a href={LINKS.register}
              className="bg-white text-brand-500 text-base font-bold px-8 py-4 rounded-full hover:bg-gray-100 transition-all hover:shadow-lg"
            >
              Mulai Belajar
            </a>
            <Link
              to="/batch"
              className="text-white text-base font-semibold px-8 py-4 rounded-full transition-all"
              style={{ border: '2px solid rgba(255,255,255,0.3)', backgroundColor: 'transparent' }}
            >
              Lihat Kelas Batch ↗
            </Link>
          </div>
        </div>
      </div>
    </section>
  )
}
