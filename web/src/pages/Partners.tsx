import { CtaBand } from './Home/CtaBand'

const PROGRAMS = [
  { icon: '📚', title: 'Kursus Standar',     desc: 'Katalog kursus existing langsung tersedia untuk siswa atau mahasiswa institusi Anda.' },
  { icon: '✏️', title: 'Program Custom',     desc: 'Kurikulum yang kami rancang khusus berdasarkan kebutuhan dan tujuan spesifik institusi Anda.' },
  { icon: '🎤', title: 'Seminar & Workshop', desc: 'Acara satu kali atau reguler dengan pembicara dan instruktur pilihan dari jaringan VernonEdu.' },
  { icon: '🎯', title: 'Akses Talent Pool',  desc: 'Perusahaan dan institusi mitra dapat mengakses database alumni terverifikasi untuk kebutuhan rekrutmen.' },
]

const PAYMENT_MODELS = [
  { model: 'Per Kunjungan', desc: 'Bayar per sesi atau kunjungan yang terlaksana.' },
  { model: 'Per Kursus',    desc: 'Biaya tetap per kursus yang diselenggarakan.' },
  { model: 'Per Siswa',     desc: 'Tarif bulk berdasarkan jumlah siswa yang terdaftar.' },
]

export function Partners() {
  return (
    <div className="min-h-screen bg-white">
      <div className="bg-brand-900 px-12 pt-24 pb-20">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.7rem] font-bold tracking-[3px] uppercase text-brand-300 mb-3">Untuk Institusi</p>
          <h1 className="text-[clamp(2.25rem,5vw,3.5rem)] font-black tracking-[-2px] text-white leading-tight mb-4">
            Program Kemitraan<br />
            <em className="italic text-brand-200">yang Fleksibel.</em>
          </h1>
          <p className="text-[1rem] text-white/45 leading-relaxed max-w-[520px]">
            Kami bekerja sama dengan sekolah, universitas, dan perusahaan untuk menghadirkan pendidikan berkualitas langsung ke lingkungan Anda.
          </p>
        </div>
      </div>

      <div className="px-12 py-20 bg-white">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Program</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-10">Apa yang kami tawarkan.</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {PROGRAMS.map(p => (
              <div key={p.title} className="border border-brand-100 rounded-2xl p-6 flex gap-4">
                <div className="w-12 h-12 rounded-xl bg-brand-50 flex items-center justify-center text-2xl shrink-0">{p.icon}</div>
                <div>
                  <h3 className="text-base font-black text-brand-900 mb-1.5">{p.title}</h3>
                  <p className="text-sm text-slate-400 leading-relaxed">{p.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="px-12 py-16 bg-brand-50">
        <div className="max-w-[1200px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Model Pembayaran</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-8">Disesuaikan dengan kesepakatan Anda.</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {PAYMENT_MODELS.map(m => (
              <div key={m.model} className="bg-white border border-brand-100 rounded-2xl p-6">
                <h3 className="text-base font-black text-brand-900 mb-2">{m.model}</h3>
                <p className="text-sm text-slate-400 leading-relaxed">{m.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div id="contact" className="px-12 py-20 bg-white">
        <div className="max-w-[600px] mx-auto text-center">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-3">Kontak</p>
          <h2 className="text-3xl font-black tracking-tight text-brand-900 mb-4">
            Hubungi Kami
          </h2>
          <p className="text-[1rem] text-slate-400 leading-relaxed mb-8">
            Tim partnership kami siap berdiskusi tentang kebutuhan spesifik institusi Anda dan merancang program yang tepat.
          </p>
          <a
            href="mailto:partnership@vernonedu.id"
            className="inline-flex items-center gap-2 bg-brand-900 text-white text-[0.875rem] font-black px-8 py-3.5 rounded-full hover:bg-brand-800 transition-colors"
          >
            partnership@vernonedu.id
          </a>
        </div>
      </div>

      <CtaBand />
    </div>
  )
}
