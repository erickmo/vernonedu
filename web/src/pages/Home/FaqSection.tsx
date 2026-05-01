import { useState } from 'react'
import { FAQS } from '../../data/faqs'

export function FaqSection() {
  const [open, setOpen] = useState<string | null>(null)

  return (
    <section className="py-24 px-12 bg-slate-50">
      <div className="max-w-[720px] mx-auto">
        <h2 className="text-[2.25rem] font-black tracking-[-1.5px] text-brand-900 leading-[1.1] mb-10">
          Pertanyaan<br />yang sering ditanya.
        </h2>
        {FAQS.map(faq => (
          <div key={faq.id} className="border-t border-brand-100 py-5">
            <button
              className="w-full flex justify-between items-center text-[1rem] font-bold text-brand-900 text-left"
              onClick={() => setOpen(open === faq.id ? null : faq.id)}
            >
              {faq.question}
              <span className="text-brand-500 text-xl font-light ml-4 shrink-0">
                {open === faq.id ? '−' : '+'}
              </span>
            </button>
            {open === faq.id && (
              <p className="text-sm text-slate-400 leading-[1.75] mt-3.5">{faq.answer}</p>
            )}
          </div>
        ))}
      </div>
    </section>
  )
}
