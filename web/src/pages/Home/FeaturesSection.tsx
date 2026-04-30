import { FEATURES } from '../../data/features'
import { LINKS } from '../../tokens'

const B2B_CHECKLIST = [
  'Kursus standar dari katalog VernonEdu',
  'Program custom sesuai kebutuhan institusi',
  'Seminar & workshop on-site',
  'Model pembayaran fleksibel (per kunjungan / per siswa)',
  'Akses talent pool alumni untuk rekrutmen',
]

export function FeaturesSection() {
  return (
    <section className="py-24 px-12 bg-slate-50">
      <div className="max-w-[1200px] mx-auto grid grid-cols-1 lg:grid-cols-[5fr_4fr] gap-10 lg:gap-20 items-start">
        {/* left — feature list */}
        <div>
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">
            Mengapa VernonEdu
          </p>
          <h2 className="text-4xl font-black tracking-tight text-brand-900 leading-tight mb-8">
            Ekosistem belajar<br />
            yang <em className="italic text-brand-500">nyata.</em>
          </h2>
          <div className="flex flex-col gap-4">
            {FEATURES.map(feat => (
              <div
                key={feat.id}
                className="flex gap-5 items-start p-5 bg-white border border-brand-100 rounded-2xl"
              >
                <div className="w-11 h-11 rounded-xl bg-brand-50 shrink-0 flex items-center justify-center text-xl">
                  {feat.icon}
                </div>
                <div>
                  <p className="text-[0.9rem] font-black text-brand-900 mb-1">{feat.title}</p>
                  <p className="text-[0.78rem] text-slate-400 leading-relaxed">{feat.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* right — sticky B2B card */}
        <div className="bg-brand-500 text-white rounded-3xl p-10 sticky top-24">
          <p className="text-[0.65rem] font-bold tracking-[2px] uppercase text-white/50 mb-4">
            Program B2B
          </p>
          <h3 className="text-[1.75rem] font-black leading-tight tracking-tight mb-4">
            Untuk Sekolah &amp; Kampus
          </h3>
          <p className="text-[0.82rem] text-white/65 leading-[1.75] mb-7">
            Program kemitraan fleksibel untuk menghadirkan kursus VernonEdu langsung ke institusi Anda.
          </p>
          <ul className="flex flex-col gap-3 mb-8">
            {B2B_CHECKLIST.map(item => (
              <li key={item} className="flex gap-3 items-start text-[0.82rem] text-white/75">
                <span className="text-brand-200 font-black shrink-0 mt-0.5">✓</span>
                {item}
              </li>
            ))}
          </ul>
          <a
            href="mailto:partnership@vernonedu.id"
            className="block bg-white text-brand-500 text-[0.875rem] font-black py-3.5 rounded-xl text-center hover:bg-brand-50 transition-colors"
          >
            Hubungi Tim Partnership →
          </a>
        </div>
      </div>
    </section>
  )
}
