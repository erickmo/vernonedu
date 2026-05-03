import { ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import { Link } from 'react-router-dom'

interface BreadcrumbItem {
  label: string
  to?: string
}

interface BreadcrumbProps {
  items: BreadcrumbItem[]
  className?: string
}

export default function Breadcrumb({ items, className }: BreadcrumbProps) {
  return (
    <nav className={cn('flex items-center gap-1.5 text-sm', className)}>
      {items.map((item, i) => (
        <span key={i} className="flex items-center gap-1.5">
          {i > 0 && <ChevronRight className="h-3.5 w-3.5 text-neutral-400" />}
          {item.to ? (
            <Link to={item.to} className="text-neutral-500 hover:text-neutral-700 transition-colors">{item.label}</Link>
          ) : (
            <span className="font-medium text-neutral-900">{item.label}</span>
          )}
        </span>
      ))}
    </nav>
  )
}
