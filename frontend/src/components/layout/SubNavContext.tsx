import { createContext, useContext, useEffect, useRef, useState, ReactNode } from 'react'
import { cn } from '@/lib/utils/cn'

export interface SubNavItem {
  label: string
  value: string
}

interface SubNavState {
  items: SubNavItem[]
  active: string
  onChange: (value: string) => void
}

interface SubNavContextValue {
  state: SubNavState | null
  setState: (s: SubNavState | null) => void
}

const SubNavContext = createContext<SubNavContextValue>({
  state: null,
  setState: () => {},
})

export function SubNavProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<SubNavState | null>(null)
  return (
    <SubNavContext.Provider value={{ state, setState }}>
      {children}
    </SubNavContext.Provider>
  )
}

/**
 * Called by pages to register their sub-nav tabs.
 * `items` must be a stable reference (module-level constant or useMemo).
 * `onChange` from useState is always stable.
 */
export function useSubNav(
  items: SubNavItem[],
  active: string,
  onChange: (value: string) => void,
) {
  const { setState } = useContext(SubNavContext)
  const onChangeRef = useRef(onChange)
  onChangeRef.current = onChange

  useEffect(() => {
    setState({ items, active, onChange: (v) => onChangeRef.current(v) })
    return () => setState(null)
  }, [active, setState, items])
}

export function useSubNavState(): SubNavState | null {
  return useContext(SubNavContext).state
}

/** Rendered by portal layouts between Nav1 and main content. */
export function SubNavBar() {
  const state = useSubNavState()
  if (!state || state.items.length === 0) return null

  return (
    <div className="sticky top-14 z-40 h-11 bg-neutral-50 border-b border-neutral-100 flex items-center px-6 md:px-8 gap-0.5 overflow-x-auto scrollbar-none">
      {state.items.map((item) => (
        <button
          key={item.value}
          onClick={() => state.onChange(item.value)}
          className={cn(
            'shrink-0 px-3 h-11 text-sm font-medium transition-colors relative whitespace-nowrap',
            state.active === item.value
              ? 'text-brand-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-brand-600 after:rounded-t-full'
              : 'text-neutral-500 hover:text-neutral-700 hover:bg-neutral-100/60',
          )}
        >
          {item.label}
        </button>
      ))}
    </div>
  )
}
