import { Link } from 'react-router-dom'
import { LINKS } from '../../tokens'

const STATS = [
  { value: '12K+', label: 'Siswa Aktif' },
  { value: '500+', label: 'Kursus Tersedia' },
  { value: '80+',  label: 'Mitra Institusi' },
  { value: '15+',  label: 'Kota di Indonesia' },
]

const CHOOSER_ITEMS = [
  {
    icon: '🎓',
    name: 'Siswa / Pelajar',
    sub: 'Daftar kursus regular, private, atau kelas batch',
    to: '/students',
  },
  {
    icon: '🏫',
    name: 'Mitra Institusi',
    sub: 'Sekolah, kampus, atau perusahaan',
    to: '/partners',
  },
]

export function Hero() {
  return (
    <section className="min-h-screen pt-28 flex flex-col relative overflow-hidden bg-white">
      {/* blobs */}
      <div className="absolute -top-32 -right-32 w-[600px] h-[600px] rounded-full bg-gradient-to-br from-brand-200/35 to-transparent pointer-events-none" />
      <div className="absolute bottom-32 -left-24 w-[400px] h-[400px] rounded-full bg-gradient-to-br from-brand-500/12 to-transparent pointer-events-none" />

      {/* main content */}
      <div className="flex-1 max-w-[1200px] w-full mx-auto px-12 grid grid-cols-1 md:grid-cols-2 gap-8 md:gap-16 items-center py-12">
        {/* left */}
        <div>
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

        {/* right — audience chooser */}
        <div className="bg-brand-50 border border-brand-100 rounded-3xl p-8">
          <p className="text-[0.65rem] font-bold tracking-[2.5px] uppercase text-brand-500 mb-5">
            Saya adalah...
          </p>
          {CHOOSER_ITEMS.map(item => (
            <Link
              key={item.to}
              to={item.to}
              className="flex items-center gap-4 p-4 bg-white rounded-2xl border border-brand-100 mb-3 last:mb-0 hover:border-brand-300 hover:shadow-md hover:translate-x-1 transition-all group"
            >
              <div className="w-11 h-11 rounded-xl bg-brand-50 flex items-center justify-center text-xl shrink-0">
                {item.icon}
              </div>
              <div className="flex-1">
                <p className="text-[0.9rem] font-black text-brand-900">{item.name}</p>
                <p className="text-[0.72rem] text-slate-400 mt-0.5">{item.sub}</p>
              </div>
              <span className="text-brand-500 group-hover:translate-x-0.5 transition-transform">→</span>
            </Link>
          ))}
        </div>
      </div>

      {/* stats strip */}
      <div className="max-w-[1200px] w-full mx-auto border-t border-brand-100">
        <div className="grid grid-cols-2 md:grid-cols-4 divide-x divide-brand-100">
          {STATS.map(stat => (
            <div key={stat.label} className="px-6 py-7 flex flex-col gap-1">
              <span className="text-[1.75rem] font-black text-brand-500 tracking-tight">{stat.value}</span>
              <span className="text-[0.72rem] text-slate-400 font-medium">{stat.label}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
