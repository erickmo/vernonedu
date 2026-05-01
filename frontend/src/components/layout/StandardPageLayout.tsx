import { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'

export interface BreadcrumbItem {
  label: string
  to?: string
}

export interface DetailTab {
  value: string
  label: string
  badge?: number
}

interface StandardPageLayoutProps {
  header?: ReactNode
  breadcrumbs?: BreadcrumbItem[]
  title?: string
  subtitle?: string
  actions?: ReactNode
  tabs?: DetailTab[]
  activeTab?: string
  onTabChange?: (value: string) => void
  children: ReactNode
}

export function StandardPageLayout({
  header,
  breadcrumbs = [],
  title,
  subtitle,
  actions,
  tabs = [],
  activeTab,
  onTabChange,
  children,
}: StandardPageLayoutProps) {
  return (
    <div className="min-h-screen bg-gray-50">
      {header && <div className="bg-white border-b">{header}</div>}

      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4">
          {breadcrumbs.length > 0 && (
            <nav className="flex items-center gap-1 text-sm text-gray-500 mb-3">
              {breadcrumbs.map((crumb, idx) => (
                <span key={idx} className="flex items-center gap-1">
                  {idx > 0 && <ChevronRight className="w-4 h-4" />}
                  {crumb.to ? (
                    <Link to={crumb.to} className="text-blue-600 hover:underline">
                      {crumb.label}
                    </Link>
                  ) : (
                    <span>{crumb.label}</span>
                  )}
                </span>
              ))}
            </nav>
          )}

          <div className="flex justify-between items-start gap-4">
            <div className="flex-1">
              {title && <h1 className="text-3xl font-bold text-gray-900">{title}</h1>}
              {subtitle && <p className="text-gray-600 mt-1">{subtitle}</p>}
            </div>
            {actions && <div className="flex gap-2">{actions}</div>}
          </div>
        </div>
      </div>

      {tabs.length > 0 && (
        <div className="bg-white border-b">
          <div className="max-w-7xl mx-auto px-4">
            <div className="flex gap-8">
              {tabs.map((tab) => (
                <button
                  key={tab.value}
                  onClick={() => onTabChange?.(tab.value)}
                  className={`py-3 px-1 border-b-2 font-medium text-sm transition ${
                    activeTab === tab.value
                      ? 'text-blue-600 border-blue-600'
                      : 'text-gray-600 border-transparent hover:text-gray-900'
                  }`}
                >
                  {tab.label}
                  {tab.badge !== undefined && (
                    <span className="ml-2 inline-flex items-center justify-center w-5 h-5 text-xs bg-gray-100 rounded-full">
                      {tab.badge}
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 py-8">
        {children}
      </div>
    </div>
  )
}
