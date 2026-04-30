import { TESTIMONIALS } from '../../data/testimonials'

export function TestimonialSection() {
  const featured = TESTIMONIALS.find(t => t.featured)!
  const compact  = TESTIMONIALS.filter(t => !t.featured)

  return (
    <section className="py-24 px-12 bg-white">
      <div className="max-w-[1200px] mx-auto">
        <div className="flex justify-between items-end mb-12">
          <div>
            <p className="text-[0.65rem] font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">Testimoni</p>
            <h2 className="text-4xl font-black tracking-tight text-brand-900 leading-tight">
              Apa kata <em className="italic text-brand-500">mereka?</em>
            </h2>
          </div>
          <a href="#" className="text-[0.8rem] font-semibold text-brand-500 hover:text-brand-700">
            Lihat semua →
          </a>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-[2fr_1fr_1fr] gap-5 items-start">
          {/* featured */}
          <div className="bg-brand-900 rounded-2xl p-8">
            <p className="text-[0.7rem] text-brand-500 tracking-[2px] mb-4">★ ★ ★ ★ ★</p>
            <p className="text-base text-white/80 leading-[1.75] italic mb-6">{`"${featured.quote}"`}</p>
            <p className="text-[0.85rem] font-black text-brand-200">{featured.name}</p>
            <p className="text-[0.72rem] text-white/35 mt-0.5">{featured.role}</p>
          </div>

          {/* compact */}
          {compact.map(t => (
            <div key={t.id} className="bg-slate-50 border border-brand-100 rounded-2xl p-8">
              <p className="text-[0.7rem] text-brand-500 tracking-[2px] mb-4">★ ★ ★ ★ ★</p>
              <p className="text-[0.875rem] text-brand-800 leading-[1.75] italic mb-6">{`"${t.quote}"`}</p>
              <p className="text-[0.85rem] font-black text-brand-600">{t.name}</p>
              <p className="text-[0.72rem] text-slate-400 mt-0.5">{t.role}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
