import { COURSE_TICKER_ITEMS } from '../../data/partners'

export function CourseTicker() {
  const items = [...COURSE_TICKER_ITEMS, ...COURSE_TICKER_ITEMS]

  return (
    <div className="bg-brand-50 py-3.5 overflow-hidden whitespace-nowrap border-y border-brand-100">
      <div className="ticker-track gap-0 text-[0.7rem] font-black tracking-[2px] text-slate-400 uppercase">
        {items.map((item, i) => (
          <span key={i} className="inline-flex items-center">
            {item}
            <span className="text-brand-200 mx-6">✦</span>
          </span>
        ))}
      </div>
    </div>
  )
}
