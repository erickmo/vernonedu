import { cn } from '@/lib/utils/cn'

export interface Tab {
  key: string
  label: string
  disabled?: boolean
  disabledReason?: string
}

interface Props {
  tabs: Tab[]
  activeKey: string
  onChange: (key: string) => void
}

export default function TabNav({ tabs, activeKey, onChange }: Props) {
  return (
    <div className="border-b border-border" role="tablist">
      <div className="flex gap-1">
        {tabs.map((tab) => {
          const active = tab.key === activeKey
          return (
            <button
              key={tab.key}
              type="button"
              role="tab"
              aria-selected={active}
              disabled={tab.disabled}
              title={tab.disabled ? tab.disabledReason : undefined}
              onClick={() => !tab.disabled && onChange(tab.key)}
              className={cn(
                'px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
                active
                  ? 'border-primary text-primary'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900',
                tab.disabled && 'opacity-40 cursor-not-allowed hover:text-neutral-600',
              )}
            >
              {tab.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
