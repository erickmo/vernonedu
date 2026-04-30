const B2B_CARDS = [
  { title: 'Kursus Standar',     desc: 'Katalog kursus existing langsung tersedia untuk siswa/mahasiswa mitra Anda.' },
  { title: 'Program Custom',     desc: 'Kurikulum yang dirancang khusus sesuai kebutuhan spesifik institusi Anda.' },
  { title: 'Seminar & Workshop', desc: 'Acara satu kali atau reguler dengan pembicara dan instruktur pilihan.' },
  { title: 'Akses Talent Pool',  desc: 'Perusahaan mitra dapat mengakses database alumni VernonEdu untuk kebutuhan rekrutmen.' },
]

export function B2BSection() {
  return (
    <section className="py-24 px-12 bg-brand-50">
      <div className="max-w-[1200px] mx-auto grid grid-cols-1 md:grid-cols-2 gap-10 md:gap-20 items-start">
        <div>
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-5">
            Kemitraan B2B
          </p>
          <h2 className="text-[clamp(2rem,4vw,3rem)] font-black leading-[1.05] tracking-[-1.5px] text-brand-900 mb-4">
            Tingkatkan Kualitas<br />
            <em className="italic text-brand-500">Siswa Anda</em><br />
            Bersama Kami.
          </h2>
          <p className="text-base text-slate-400 leading-[1.8] mb-7">
            Kami bekerja sama dengan sekolah dan universitas untuk menghadirkan kursus, seminar, dan workshop berkualitas langsung ke institusi Anda.
          </p>
          <a
            href="mailto:partnership@vernonedu.id"
            className="inline-flex items-center gap-2 bg-brand-900 text-white text-base font-bold px-8 py-3.5 rounded-full hover:bg-brand-800 transition-colors"
          >
            Hubungi Tim Partnership →
          </a>
        </div>

        <div className="flex flex-col gap-3.5">
          {B2B_CARDS.map(card => (
            <div key={card.title} className="bg-white border border-brand-100 rounded-2xl px-6 py-5">
              <p className="text-base font-black text-brand-900 mb-1.5">{card.title}</p>
              <p className="text-sm text-slate-400 leading-relaxed">{card.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
