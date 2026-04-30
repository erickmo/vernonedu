import { Link } from 'react-router-dom'
import { LINKS } from '../tokens'
import { CtaBand } from './Home/CtaBand'

const CLASS_FORMATS = [
  {
    icon: '👥',
    title: 'Kelas Regular',
    desc: 'Belajar dalam grup kecil bersama peserta lain. Harga lebih terjangkau, jadwal tetap setiap minggu.',
    badge: 'Populer',
  },
  {
    icon: '👤',
    title: 'Kelas Private',
    desc: 'Sesi 1-on-1 atau kelompok sangat kecil bersama instruktur pilihan. Jadwal fleksibel sesuai kebutuhan Anda.',
    badge: 'Premium',
  },
  {
    icon: '📅',
    title: 'Kelas Batch',
    desc: 'Kelas terjadwal dengan angkatan bersama. Mulai pada tanggal tertentu, belajar bersama selama beberapa minggu.',
    badge: 'Terstruktur',
  },
]

const DELIVERY_MODES = [
  { icon: '🌐', title: 'Online',  desc: 'Belajar dari mana saja melalui platform VernonEdu. Rekaman tersedia.' },
  { icon: '📍', title: 'Offline', desc: 'Hadir langsung di cabang VernonEdu terdekat di kota Anda.' },
]

export function Students() {
  return (
    <div className="min-h-screen bg-white">
      {/* header */}
      <div className="bg-brand-900 px-12 pt-24 pb-20">
        <div className="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <div>
            <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">Untuk Individu</p>
            <h1 className="text-[clamp(2.25rem,5vw,3.5rem)] font-black tracking-[-2px] text-white leading-tight mb-4">
              Kursus untuk Anda.<br />
              <em className="italic text-brand-200">Sesuai Kebutuhan.</em>
            </h1>
            <p className="text-[1rem] text-white/45 leading-relaxed max-w-[420px]">
              Pilih format kelas, mode belajar, dan jadwal yang paling sesuai dengan gaya hidup Anda.
            </p>
          </div>
          <div className="flex gap-4 flex-wrap">
            <a
              href={LINKS.register}
              className="inline-flex items-center gap-2 bg-brand-500 text-white text-[0.875rem] font-black px-7 py-3.5 rounded-full hover:bg-brand-400 transition-colors"
            >
              Daftar Sekarang
            </a>
            <Link
              to="/batch"
              className="inline-flex items-center border border-white/20 text-white/60 text-[0.875rem] font-semibold px-6 py-3.5 rounded-full hover:border-white/40 transition-colors"
            >
              Lihat Kelas Batch
            </Link>
          </div>
        </div>
      </div>

      {/* format cards */}
      <div className="px-12 py-20 bg-white">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Format Belajar</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-10">Pilih cara belajar Anda.</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {CLASS_FORMATS.map(f => (
              <div key={f.title} className="border border-brand-100 rounded-2xl p-6 hover:shadow-md transition-shadow">
                <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl mb-4">{f.icon}</div>
                <div className="flex items-center gap-2 mb-2">
                  <h3 className="text-base font-black text-brand-900">{f.title}</h3>
                  <span className="text-[0.65rem] font-bold px-2 py-0.5 rounded-full bg-brand-50 text-brand-500">{f.badge}</span>
                </div>
                <p className="text-sm text-slate-400 leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* delivery mode */}
      <div id="private" className="px-12 py-16 bg-brand-50">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Mode Belajar</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-8">Online atau offline — pilihan Anda.</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {DELIVERY_MODES.map(m => (
              <div key={m.title} className="bg-white border border-brand-100 rounded-2xl p-6 flex gap-4">
                <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl shrink-0">{m.icon}</div>
                <div>
                  <h3 className="text-base font-black text-brand-900 mb-1.5">{m.title}</h3>
                  <p className="text-sm text-slate-400 leading-relaxed">{m.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <CtaBand />
    </div>
  )
}
