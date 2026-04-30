import { LINKS } from '../../tokens'

export function CtaBand() {
  return (
    <section className="bg-brand-900 py-20 px-12 text-center">
      <div className="max-w-[600px] mx-auto">
        <h2 className="text-[2.5rem] font-black tracking-[-2px] text-white leading-[1.1] mb-4">
          Siap mulai<br />
          <em className="italic text-brand-200">perjalananmu?</em>
        </h2>
        <p className="text-[0.9rem] text-white/45 leading-[1.7] mb-8">
          Bergabung dengan 12.000+ siswa yang sudah belajar bersama VernonEdu.
        </p>
        <div className="flex gap-4 justify-center">
          <a
            href={LINKS.register}
            className="bg-white text-brand-900 text-[0.875rem] font-black px-8 py-3.5 rounded-full hover:bg-brand-50 transition-colors"
          >
            Daftar Gratis
          </a>
          <a
            href="mailto:hello@vernonedu.id"
            className="border-[1.5px] border-white/20 text-white/60 text-[0.875rem] font-semibold px-7 py-3.5 rounded-full hover:border-white/40 transition-colors"
          >
            Hubungi Kami
          </a>
        </div>
      </div>
    </section>
  )
}
