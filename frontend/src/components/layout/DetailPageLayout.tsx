import { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'
import { cn } from '@/lib/utils/cn'

export interface BreadcrumbItem {
  label: string
  to?: string
}

export interface DetailTab {
  value: string
  label: string
  badge?: number
}

interface DetailPageLayoutProps {
  breadcrumbs: BreadcrumbItem[]
  icon: ReactNode
  title: string
  subtitle?: string
  status?: ReactNode
  actions?: ReactNode
  tabs: DetailTab[]
  activeTab: string
  onTabChange: (value: string) => void
  children: ReactNode
}

export default function DetailPageLayout({
  breadcrumbs,
  icon,
  title,
  subtitle,
  status,
  actions,
  tabs,
  activeTab,
  onTabChange,
  children,
}: DetailPageLayoutProps) {
  return (
    <div className="-mx-6 md:-mx-8 lg:-mx-12 -mt-6">
      {/* Page header card */}
      <div className="bg-white border-b border-neutral-100 px-6 md:px-8 lg:px-12 pt-4 pb-0">
        {/* Breadcrumb */}
        <nav className="flex items-center gap-1 text-xs text-neutral-400 mb-3">
          {breadcrumbs.map((crumb, idx) => (
            <span key={idx} className="flex items-center gap-1">
              {idx > 0 && <ChevronRight className="w-3 h-3" />}
              {crumb.to ? (
                <Link to={crumb.to} className="hover:text-neutral-600 transition-colors">
                  {crumb.label}
                </Link>
              ) : (
                <span className="text-neutral-600 font-medium">{crumb.label}</span>
              )}
            </span>
          ))}
        </nav>

        {/* Header row */}
        <div className="flex items-start gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-brand-50 border border-brand-100 flex items-center justify-center shrink-0">
            {icon}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-lg font-bold text-neutral-900 leading-tight">{title}</h1>
              {status}
            </div>
            {subtitle && (
              <p className="text-sm text-neutral-500 mt-0.5">{subtitle}</p>
            )}
          </div>
          {actions && (
            <div className="flex items-center gap-2 shrink-0">{actions}</div>
          )}
        </div>

        {/* Tab strip */}
        <div className="flex gap-0 -mb-px overflow-x-auto scrollbar-none">
          {tabs.map(tab => (
            <button
              key={tab.value}
              onClick={() => onTabChange(tab.value)}
              className={cn(
                'shrink-0 flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors whitespace-nowrap',
                activeTab === tab.value
                  ? 'text-brand-600 border-brand-600'
                  : 'text-neutral-500 border-transparent hover:text-neutral-700 hover:border-neutral-200',
              )}
            >
              {tab.label}
              {tab.badge !== undefined && (
                <span className={cn(
                  'text-xs px-1.5 py-0.5 rounded-full font-medium',
                  activeTab === tab.value ? 'bg-brand-100 text-brand-700' : 'bg-neutral-100 text-neutral-500',
                )}>
                  {tab.badge}
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Tab content */}
      <div className="px-6 md:px-8 lg:px-12 py-6">
        {children}
      </div>
    </div>
  )
}
