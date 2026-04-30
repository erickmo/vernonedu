import { PARTNERS } from '../../data/partners'

export function PartnerList() {
  return (
    <section className="py-14 px-12 bg-slate-50 border-b border-brand-100">
      <div className="max-w-[1200px] mx-auto">
        <p className="text-[0.65rem] font-bold tracking-[2.5px] uppercase text-slate-400 text-center mb-8">
          Dipercaya oleh institusi terkemuka
        </p>
        <div className="flex flex-wrap justify-center gap-3">
          {PARTNERS.map(name => (
            <div
              key={name}
              className="flex items-center gap-2 px-5 py-2.5 bg-white border border-brand-100 rounded-full text-[0.82rem] font-bold text-brand-800"
            >
              <span className="w-2 h-2 rounded-full bg-brand-100" />
              {name}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
