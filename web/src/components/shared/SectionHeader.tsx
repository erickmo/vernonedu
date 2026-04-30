import { ReactNode } from 'react'
import { Link } from 'react-router-dom'

interface SectionHeaderProps {
  eyebrow: string
  title: ReactNode
  seeAll?: { label: string; href: string }
}

export function SectionHeader({ eyebrow, title, seeAll }: SectionHeaderProps) {
  return (
    <div className="flex justify-between items-end mb-12">
      <div>
        <p className="text-xs font-bold tracking-[3px] uppercase text-brand-500 mb-2.5">
          {eyebrow}
        </p>
        <h2 className="text-4xl font-black tracking-tight text-brand-900 leading-tight">
          {title}
        </h2>
      </div>
      {seeAll && (
        <Link
          to={seeAll.href}
          className="text-sm font-semibold text-brand-500 flex items-center gap-1 hover:text-brand-700 whitespace-nowrap"
        >
          {seeAll.label} →
        </Link>
      )}
    </div>
  )
}
