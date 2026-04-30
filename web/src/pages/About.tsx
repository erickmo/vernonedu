export function About() {
  return (
    <div className="min-h-screen bg-white">
      <div className="bg-brand-900 px-12 pt-24 pb-20">
        <div className="max-w-[1200px] mx-auto">
          <h1 className="text-[clamp(2.25rem,5vw,3.5rem)] font-black tracking-[-2px] text-white leading-tight mb-4">
            Tentang VernonEdu
          </h1>
          <p className="text-[1rem] text-white/45 leading-relaxed max-w-[520px]">
            Lembaga pendidikan informal yang hadir untuk membuka peluang melalui kursus berkualitas, kemitraan institusi, dan program tersertifikasi.
          </p>
        </div>
      </div>

      <div className="px-12 py-20">
        <div className="max-w-[800px] mx-auto">
          <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-3">Misi</p>
          <h2 className="text-2xl font-black tracking-tight text-brand-900 mb-5">
            Pendidikan yang Relevan, Fleksibel, dan Berdampak
          </h2>
          <p className="text-[1.05rem] text-slate-500 leading-[1.85] mb-10">
            VernonEdu berdiri dengan satu keyakinan: belajar tidak harus terbatas oleh ruang kelas atau jadwal kaku. Kami hadir dengan kurikulum yang dirancang bersama praktisi, tersedia online dan offline, untuk semua kalangan — dari siswa individu hingga mitra institusi pendidikan.
          </p>

          <div id="contact" className="border-t border-brand-100 pt-12">
            <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-3">Kontak</p>
            <h2 className="text-2xl font-black tracking-tight text-brand-900 mb-6">Hubungi Kami</h2>
            <div className="flex flex-col gap-3 text-[1rem] text-slate-500">
              <p>Email umum: <a href="mailto:hello@vernonedu.id" className="text-brand-500 font-semibold">hello@vernonedu.id</a></p>
              <p>Partnership: <a href="mailto:partnership@vernonedu.id" className="text-brand-500 font-semibold">partnership@vernonedu.id</a></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
