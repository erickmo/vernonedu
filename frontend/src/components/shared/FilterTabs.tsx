import { cn } from '@/lib/utils/cn'

interface Tab {
  label: string
  value: string
}

interface FilterTabsProps {
  tabs: Tab[]
  active: string
  onChange: (value: string) => void
}

export default function FilterTabs({ tabs, active, onChange }: FilterTabsProps) {
  return (
    <div className="flex items-center gap-1 bg-white border border-neutral-200 rounded-lg p-1 shrink-0">
      {tabs.map((tab) => (
        <button
          key={tab.value}
          type="button"
          onClick={() => onChange(tab.value)}
          className={cn(
            'px-3 py-1 text-sm font-medium rounded-md transition-colors',
            active === tab.value
              ? 'bg-brand-600 text-white shadow-sm'
              : 'text-neutral-600 hover:bg-neutral-50'
          )}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}
