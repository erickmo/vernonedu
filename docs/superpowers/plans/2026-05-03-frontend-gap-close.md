# Frontend Gap Close & Design Elevation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close all gaps in the `frontend/` React app — complete the Shadcn UI component library, elevate the design system to support `frontend-design:frontend-design` skill, and redesign key pages with distinctive, production-grade aesthetics.

**Architecture:** Three-phase approach. Phase 1: Design tokens + theme system. Phase 2: Complete UI primitive library (20+ components). Phase 3: Redesign key pages using the new system + frontend-design skill. Each phase is independently testable.

**Tech Stack:** React 18, TypeScript, Vite, Tailwind CSS 3, Radix UI, CVA (class-variance-authority), Framer Motion (new), Lucide React, Recharts

---

## Gap Analysis Summary

| Area | Current | Target |
|------|---------|--------|
| UI Primitives | 5 (Button, Input, Label, Select, Textarea) | 25+ (full Shadcn set) |
| Design Tokens | CSS vars defined, mostly unused | Full token system with semantic aliases |
| Dark Mode | Variables exist, no toggle | Functional toggle + system preference detection |
| Animations | None | Framer Motion for page transitions, micro-interactions |
| Typography | Plus Jakarta Sans only | Paired: display + body, refined hierarchy |
| Charts | Recharts installed, unthemed | Themed charts matching brand |
| Page Design | Generic admin panel | Distinctive VernonEdu aesthetic per frontend-design skill |

---

## File Structure

### New Files (Phase 1 — Design System)
- `src/lib/utils/motion.ts` — Framer Motion animation presets
- `src/hooks/useTheme.ts` — Dark/light mode toggle + system preference
- `src/components/ui/ThemeProvider.tsx` — Theme context wrapper

### New Files (Phase 2 — UI Primitives)
- `src/components/ui/Dialog.tsx` — Modal dialog (Radix)
- `src/components/ui/Avatar.tsx` — User avatar (Radix)
- `src/components/ui/Badge.tsx` — Status/category badges
- `src/components/ui/Card.tsx` — Content card
- `src/components/ui/Skeleton.tsx` — Loading skeleton
- `src/components/ui/Tooltip.tsx` — Hover tooltip (Radix)
- `src/components/ui/Popover.tsx` — Floating popover (Radix)
- `src/components/ui/Sheet.tsx` — Side drawer (custom)
- `src/components/ui/Tabs.tsx` — Tab navigation (Radix)
- `src/components/ui/Separator.tsx` — Visual divider (Radix)
- `src/components/ui/Alert.tsx` — Inline alert/banner
- `src/components/ui/Checkbox.tsx` — Checkbox input
- `src/components/ui/Switch.tsx` — Toggle switch
- `src/components/ui/Textarea.tsx` — Override with CVA variants
- `src/components/ui/RadioGroup.tsx` — Radio button group
- `src/components/ui/ScrollArea.tsx` — Custom scrollbar (Radix)
- `src/components/ui/Progress.tsx` — Progress bar
- `src/components/ui/Breadcrumb.tsx` — Navigation breadcrumbs
- `src/components/ui/Calendar.tsx` — Date picker calendar
- `src/components/ui/DropdownMenu.tsx` — Dropdown menu (Radix)

### Modified Files (Phase 3 — Redesigns)
- `src/index.css` — Enhanced tokens, animation keyframes
- `src/tailwind.config.ts` — Extended theme, animation config
- `src/App.tsx` — ThemeProvider wrapper, page transitions
- `src/main.tsx` — Framer Motion AnimatePresence
- `src/components/shared/DataTable.tsx` — Enhanced with sorting, skeleton
- `src/components/shared/StatusBadge.tsx` — Themed via design tokens
- `src/components/shared/EmptyState.tsx` — Illustrated, animated
- `src/components/shared/LoadingSpinner.tsx` — Branded animation
- `src/components/shared/PageHeader.tsx` — Refined hierarchy
- `src/components/layout/TopNavBar.tsx` — Redesigned with theme toggle
- `src/components/layout/DetailPageLayout.tsx` — Enhanced transitions
- `src/components/layout/StandardPageLayout.tsx` — Enhanced transitions
- `src/pages/Login.tsx` — Redesigned per frontend-design skill
- `src/portals/internal/pages/Dashboard.tsx` — Redesigned per frontend-design skill

---

## Phase 1: Design System Foundation

### Task 1: Install Framer Motion

**Files:**
- Modify: `frontend/package.json`

- [ ] **Step 1: Install dependency**

```bash
cd frontend && npm install framer-motion
```

- [ ] **Step 2: Verify install**

```bash
cd frontend && npx tsc --noEmit
```

Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add frontend/package.json frontend/package-lock.json
git commit -m "chore: add framer-motion dependency"
```

---

### Task 2: Create Motion Presets

**Files:**
- Create: `src/lib/utils/motion.ts`

- [ ] **Step 1: Create motion presets file**

```typescript
// src/lib/utils/motion.ts
import type { Variants, Transition } from 'framer-motion'

const spring: Transition = {
  type: 'spring',
  stiffness: 300,
  damping: 30,
}

const smooth: Transition = {
  type: 'tween',
  ease: [0.25, 0.1, 0.25, 1],
  duration: 0.3,
}

export const fadeIn: Variants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: smooth },
  exit: { opacity: 0, transition: { duration: 0.15 } },
}

export const fadeInUp: Variants = {
  hidden: { opacity: 0, y: 12 },
  visible: { opacity: 1, y: 0, transition: smooth },
  exit: { opacity: 0, y: -6, transition: { duration: 0.15 } },
}

export const fadeInDown: Variants = {
  hidden: { opacity: 0, y: -12 },
  visible: { opacity: 1, y: 0, transition: smooth },
  exit: { opacity: 0, y: 6, transition: { duration: 0.15 } },
}

export const slideInRight: Variants = {
  hidden: { opacity: 0, x: 24 },
  visible: { opacity: 1, x: 0, transition: smooth },
  exit: { opacity: 0, x: 24, transition: { duration: 0.15 } },
}

export const scaleIn: Variants = {
  hidden: { opacity: 0, scale: 0.95 },
  visible: { opacity: 1, scale: 1, transition: spring },
  exit: { opacity: 0, scale: 0.95, transition: { duration: 0.15 } },
}

export const stagger: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.05 },
  },
}

export const staggerItem: Variants = {
  hidden: { opacity: 0, y: 8 },
  visible: { opacity: 1, y: 0, transition: smooth },
}

export const pageTransition: Variants = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0, transition: smooth },
  exit: { opacity: 0, y: -8, transition: { duration: 0.15 } },
}

export { spring, smooth }
```

- [ ] **Step 2: Verify no type errors**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/lib/utils/motion.ts
git commit -m "feat(ui): add framer-motion animation presets"
```

---

### Task 3: Enhanced Tailwind Config

**Files:**
- Modify: `src/tailwind.config.ts`

- [ ] **Step 1: Update tailwind.config.ts with animation tokens and extended theme**

Add to `theme.extend`:

```typescript
// tailwind.config.ts — add inside theme.extend
keyframes: {
  'fade-in': {
    '0%': { opacity: '0', transform: 'translateY(8px)' },
    '100%': { opacity: '1', transform: 'translateY(0)' },
  },
  'fade-out': {
    '0%': { opacity: '1', transform: 'translateY(0)' },
    '100%': { opacity: '0', transform: 'translateY(-8px)' },
  },
  'slide-in-right': {
    '0%': { transform: 'translateX(100%)' },
    '100%': { transform: 'translateX(0)' },
  },
  'slide-out-right': {
    '0%': { transform: 'translateX(0)' },
    '100%': { transform: 'translateX(100%)' },
  },
  'pulse-subtle': {
    '0%, 100%': { opacity: '1' },
    '50%': { opacity: '0.7' },
  },
  shimmer: {
    '0%': { backgroundPosition: '-200% 0' },
    '100%': { backgroundPosition: '200% 0' },
  },
},
animation: {
  'fade-in': 'fade-in 0.3s ease-out',
  'fade-out': 'fade-out 0.15s ease-in',
  'slide-in-right': 'slide-in-right 0.3s ease-out',
  'slide-out-right': 'slide-out-right 0.15s ease-in',
  'pulse-subtle': 'pulse-subtle 2s ease-in-out infinite',
  shimmer: 'shimmer 1.5s ease-in-out infinite',
},
boxShadow: {
  'card': '0 1px 3px rgba(0, 0, 0, 0.06), 0 1px 2px rgba(0, 0, 0, 0.04)',
  'card-hover': '0 4px 12px rgba(0, 0, 0, 0.08), 0 2px 4px rgba(0, 0, 0, 0.04)',
  'modal': '0 16px 48px rgba(0, 0, 0, 0.12), 0 4px 12px rgba(0, 0, 0, 0.06)',
  'dropdown': '0 4px 16px rgba(0, 0, 0, 0.1), 0 1px 4px rgba(0, 0, 0, 0.04)',
},
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npm run build
```

- [ ] **Step 3: Commit**

```bash
git add tailwind.config.ts
git commit -m "feat(ui): extend tailwind config with animation + shadow tokens"
```

---

### Task 4: Enhanced CSS Design Tokens

**Files:**
- Modify: `src/index.css`

- [ ] **Step 1: Add semantic token aliases and animation keyframes to index.css**

Add after the existing `@layer base` blocks:

```css
@layer base {
  :root {
    /* Existing tokens remain... */
    /* New semantic tokens */
    --success: 142 71% 45%;
    --success-foreground: 0 0% 100%;
    --warning: 38 92% 50%;
    --warning-foreground: 0 0% 100%;
    --info: 217 91% 60%;
    --info-foreground: 0 0% 100%;
    --surface: 0 0% 100%;
    --surface-elevated: 0 0% 98%;
    --sidebar: 284 15% 97%;
    --sidebar-foreground: 222.2 84% 4.9%;
    --chart-1: 284 30% 52%;
    --chart-2: 173 58% 39%;
    --chart-3: 43 74% 66%;
    --chart-4: 24 95% 53%;
    --chart-5: 197 71% 52%;
  }

  .dark {
    /* Existing dark tokens remain... */
    --success: 142 71% 45%;
    --success-foreground: 0 0% 100%;
    --warning: 38 92% 50%;
    --warning-foreground: 0 0% 100%;
    --info: 217 91% 60%;
    --info-foreground: 0 0% 100%;
    --surface: 222.2 84% 6%;
    --surface-elevated: 222.2 84% 9%;
    --sidebar: 222.2 84% 6%;
    --sidebar-foreground: 210 40% 98%;
    --chart-1: 284 35% 65%;
    --chart-2: 173 58% 55%;
    --chart-3: 43 74% 70%;
    --chart-4: 24 95% 60%;
    --chart-5: 197 71% 60%;
  }
}
```

- [ ] **Step 2: Verify dev server renders correctly**

```bash
cd frontend && npm run dev
```

- [ ] **Step 3: Commit**

```bash
git add src/index.css
git commit -m "feat(ui): add semantic design tokens for success/warning/info/charts"
```

---

### Task 5: Theme Provider (Dark Mode Toggle)

**Files:**
- Create: `src/hooks/useTheme.ts`
- Create: `src/components/ui/ThemeProvider.tsx`

- [ ] **Step 1: Create useTheme hook**

```typescript
// src/hooks/useTheme.ts
import { useSyncExternalStore, useCallback } from 'react'

type Theme = 'light' | 'dark' | 'system'

function getTheme(): Theme {
  return (localStorage.getItem('vernonedu_theme') as Theme) || 'system'
}

function applyTheme(theme: Theme) {
  const root = document.documentElement
  const resolved =
    theme === 'system'
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light'
      : theme
  root.classList.toggle('dark', resolved === 'dark')
}

const listeners = new Set<() => void>()
function subscribe(cb: () => void) {
  listeners.add(cb)
  return () => listeners.delete(cb)
}

export function useTheme() {
  const theme = useSyncExternalStore(subscribe, getTheme)

  const setTheme = useCallback((t: Theme) => {
    localStorage.setItem('vernonedu_theme', t)
    applyTheme(t)
    listeners.forEach((cb) => cb())
  }, [])

  const resolved =
    theme === 'system'
      ? window.matchMedia('(prefers-color-scheme: dark)').matches
        ? 'dark'
        : 'light'
      : theme

  return { theme, setTheme, resolved } as const
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}

// Call once on app load
export function initTheme() {
  applyTheme(getTheme())
  window
    .matchMedia('(prefers-color-scheme: dark)')
    .addEventListener('change', () => applyTheme(getTheme()))
}
```

- [ ] **Step 2: Wire initTheme into main.tsx**

Add at the top of main.tsx, before `createRoot`:

```typescript
import { initTheme } from '@/hooks/useTheme'
initTheme()
```

- [ ] **Step 3: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 4: Commit**

```bash
git add src/hooks/useTheme.ts src/main.tsx
git commit -m "feat(ui): add theme provider with dark mode + system preference"
```

---

## Phase 2: UI Component Library Completion

### Task 5.5: Install Missing Radix Dependencies

**Files:**
- Modify: `frontend/package.json`

- [ ] **Step 1: Install missing Radix UI packages**

```bash
cd frontend && npm install @radix-ui/react-tooltip @radix-ui/react-checkbox @radix-ui/react-switch @radix-ui/react-scroll-area
```

- [ ] **Step 2: Verify install**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add frontend/package.json frontend/package-lock.json
git commit -m "chore: add missing Radix UI dependencies (tooltip, checkbox, switch, scroll-area)"
```

---

### Task 6: Dialog Component

**Files:**
- Create: `src/components/ui/Dialog.tsx`

- [ ] **Step 1: Create Dialog wrapper around Radix**

```tsx
// src/components/ui/Dialog.tsx
import * as RadixDialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import { motion, AnimatePresence } from 'framer-motion'
import { scaleIn, fadeIn } from '@/lib/utils/motion'

export const Dialog = RadixDialog.Root
export const DialogTrigger = RadixDialog.Trigger

interface DialogContentProps {
  children: React.ReactNode
  className?: string
  size?: 'sm' | 'md' | 'lg'
}

const sizeMap = { sm: 'max-w-sm', md: 'max-w-lg', lg: 'max-w-2xl' }

export function DialogContent({ children, className, size = 'md' }: DialogContentProps) {
  return (
    <RadixDialog.Portal>
      <RadixDialog.Overlay asChild>
        <motion.div
          className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm"
          variants={fadeIn}
          initial="hidden"
          animate="visible"
          exit="exit"
        />
      </RadixDialog.Overlay>
      <RadixDialog.Content asChild>
        <motion.div
          className={cn(
            'fixed left-1/2 top-1/2 z-50 w-full -translate-x-1/2 -translate-y-1/2 rounded-2xl bg-white p-6 shadow-modal border border-border',
            sizeMap[size],
            className,
          )}
          variants={scaleIn}
          initial="hidden"
          animate="visible"
          exit="exit"
        >
          {children}
          <RadixDialog.Close className="absolute right-4 top-4 rounded-lg p-1 text-neutral-400 hover:text-neutral-600 hover:bg-neutral-100 transition-colors">
            <X className="h-4 w-4" />
          </RadixDialog.Close>
        </motion.div>
      </RadixDialog.Content>
    </RadixDialog.Portal>
  )
}

export const DialogHeader = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('space-y-1.5 mb-4', className)} {...props} />
)

export const DialogTitle = RadixDialog.Title

export const DialogDescription = ({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixDialog.Description>) => (
  <RadixDialog.Description className={cn('text-sm text-neutral-500', className)} {...props} />
)

export const DialogFooter = ({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
  <div className={cn('flex justify-end gap-2 mt-6 pt-4 border-t border-border', className)} {...props} />
)
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/Dialog.tsx
git commit -m "feat(ui): add Dialog component with Framer Motion animations"
```

---

### Task 7: Card Component

**Files:**
- Create: `src/components/ui/Card.tsx`

- [ ] **Step 1: Create Card primitives**

```tsx
// src/components/ui/Card.tsx
import { cn } from '@/lib/utils/cn'
import { forwardRef } from 'react'

const Card = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        'rounded-xl border border-border bg-card text-card-foreground shadow-card transition-shadow hover:shadow-card-hover',
        className,
      )}
      {...props}
    />
  ),
)
Card.displayName = 'Card'

const CardHeader = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('flex flex-col space-y-1.5 p-5 pb-3', className)} {...props} />
  ),
)
CardHeader.displayName = 'CardHeader'

const CardTitle = forwardRef<HTMLHeadingElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h3 ref={ref} className={cn('text-base font-semibold leading-none tracking-tight', className)} {...props} />
  ),
)
CardTitle.displayName = 'CardTitle'

const CardDescription = forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLParagraphElement>>(
  ({ className, ...props }, ref) => (
    <p ref={ref} className={cn('text-sm text-muted-foreground', className)} {...props} />
  ),
)
CardDescription.displayName = 'CardDescription'

const CardContent = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('p-5 pt-0', className)} {...props} />
  ),
)
CardContent.displayName = 'CardContent'

const CardFooter = forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn('flex items-center p-5 pt-0', className)} {...props} />
  ),
)
CardFooter.displayName = 'CardFooter'

export { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/Card.tsx
git commit -m "feat(ui): add Card component with header/content/footer sub-components"
```

---

### Task 8: Badge Component

**Files:**
- Create: `src/components/ui/Badge.tsx`

- [ ] **Step 1: Create Badge with CVA variants**

```tsx
// src/components/ui/Badge.tsx
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils/cn'

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-brand-100 text-brand-800',
        secondary: 'bg-neutral-100 text-neutral-700',
        success: 'bg-emerald-100 text-emerald-800',
        warning: 'bg-amber-100 text-amber-800',
        danger: 'bg-red-100 text-red-800',
        info: 'bg-blue-100 text-blue-800',
        outline: 'border border-border text-neutral-600',
      },
    },
    defaultVariants: { variant: 'default' },
  },
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

export default function Badge({ variant, className, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/Badge.tsx
git commit -m "feat(ui): add Badge component with semantic color variants"
```

---

### Task 9: Skeleton Component

**Files:**
- Create: `src/components/ui/Skeleton.tsx`

- [ ] **Step 1: Create Skeleton loading component**

```tsx
// src/components/ui/Skeleton.tsx
import { cn } from '@/lib/utils/cn'

interface SkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
  lines?: number
}

export default function Skeleton({ className, lines, ...props }: SkeletonProps) {
  if (lines) {
    return (
      <div className="space-y-2.5" {...props}>
        {Array.from({ length: lines }).map((_, i) => (
          <div
            key={i}
            className={cn(
              'h-4 rounded-md bg-neutral-100 animate-pulse',
              i === lines - 1 && 'w-3/4',
              className,
            )}
          />
        ))}
      </div>
    )
  }

  return (
    <div
      className={cn('animate-shimmer rounded-md bg-gradient-to-r from-neutral-100 via-neutral-50 to-neutral-100 bg-[length:200%_100%]', className)}
      {...props}
    />
  )
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/Skeleton.tsx
git commit -m "feat(ui): add Skeleton loading component with shimmer animation"
```

---

### Task 10: Tooltip Component

**Files:**
- Create: `src/components/ui/Tooltip.tsx`

- [ ] **Step 1: Create Tooltip wrapper**

```tsx
// src/components/ui/Tooltip.tsx
import * as RadixTooltip from '@radix-ui/react-tooltip'
import { cn } from '@/lib/utils/cn'

export const TooltipProvider = RadixTooltip.Provider
export const Tooltip = RadixTooltip.Root
export const TooltipTrigger = RadixTooltip.Trigger

interface TooltipContentProps extends React.ComponentPropsWithoutRef<typeof RadixTooltip.Content> {
  side?: 'top' | 'right' | 'bottom' | 'left'
}

export function TooltipContent({ className, side = 'top', children, ...props }: TooltipContentProps) {
  return (
    <RadixTooltip.Portal>
      <RadixTooltip.Content
        side={side}
        sideOffset={6}
        className={cn(
          'z-50 rounded-lg bg-neutral-900 px-3 py-1.5 text-xs text-white shadow-dropdown animate-fade-in',
          className,
        )}
        {...props}
      >
        {children}
      </RadixTooltip.Content>
    </RadixTooltip.Portal>
  )
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/Tooltip.tsx
git commit -m "feat(ui): add Tooltip component (Radix wrapper)"
```

---

### Task 11: Sheet (Side Drawer) Component

**Files:**
- Create: `src/components/ui/Sheet.tsx`

- [ ] **Step 1: Create Sheet component**

```tsx
// src/components/ui/Sheet.tsx
import * as RadixDialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import { motion, AnimatePresence } from 'framer-motion'
import { fadeIn } from '@/lib/utils/motion'

export const Sheet = RadixDialog.Root
export const SheetTrigger = RadixDialog.Trigger
export const SheetClose = RadixDialog.Close

type Side = 'left' | 'right'

interface SheetContentProps {
  children: React.ReactNode
  side?: Side
  className?: string
}

const slideVariants = {
  left: {
    hidden: { x: '-100%' },
    visible: { x: 0, transition: { type: 'tween', ease: [0.25, 0.1, 0.25, 1], duration: 0.3 } },
    exit: { x: '-100%', transition: { duration: 0.15 } },
  },
  right: {
    hidden: { x: '100%' },
    visible: { x: 0, transition: { type: 'tween', ease: [0.25, 0.1, 0.25, 1], duration: 0.3 } },
    exit: { x: '100%', transition: { duration: 0.15 } },
  },
}

export function SheetContent({ children, side = 'right', className }: SheetContentProps) {
  return (
    <RadixDialog.Portal>
      <RadixDialog.Overlay asChild>
        <motion.div
          className="fixed inset-0 z-50 bg-black/40 backdrop-blur-sm"
          variants={fadeIn}
          initial="hidden"
          animate="visible"
          exit="exit"
        />
      </RadixDialog.Overlay>
      <RadixDialog.Content asChild>
        <motion.div
          className={cn(
            'fixed inset-y-0 z-50 flex flex-col bg-white shadow-modal border-border',
            side === 'right' ? 'right-0 border-l' : 'left-0 border-r',
            'w-full max-w-md',
            className,
          )}
          variants={slideVariants[side]}
          initial="hidden"
          animate="visible"
          exit="exit"
        >
          <div className="flex items-center justify-between px-5 py-4 border-b border-border">
            <RadixDialog.Title className="text-base font-semibold text-neutral-900" />
            <RadixDialog.Close className="rounded-lg p-1.5 text-neutral-400 hover:text-neutral-600 hover:bg-neutral-100 transition-colors">
              <X className="h-4 w-4" />
            </RadixDialog.Close>
          </div>
          <div className="flex-1 overflow-y-auto p-5">{children}</div>
        </motion.div>
      </RadixDialog.Content>
    </RadixDialog.Portal>
  )
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/Sheet.tsx
git commit -m "feat(ui): add Sheet (side drawer) component with slide animation"
```

---

### Task 12: DropdownMenu Component

**Files:**
- Create: `src/components/ui/DropdownMenu.tsx`

- [ ] **Step 1: Create reusable DropdownMenu wrapper**

```tsx
// src/components/ui/DropdownMenu.tsx
import * as RadixDropdownMenu from '@radix-ui/react-dropdown-menu'
import { cn } from '@/lib/utils/cn'
import { Check, ChevronRight } from 'lucide-react'

export const DropdownMenu = RadixDropdownMenu.Root
export const DropdownMenuTrigger = RadixDropdownMenu.Trigger
export const DropdownMenuGroup = RadixDropdownMenu.Group
export const DropdownMenuSub = RadixDropdownMenu.Sub

export function DropdownMenuContent({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixDropdownMenu.Content>) {
  return (
    <RadixDropdownMenu.Portal>
      <RadixDropdownMenu.Content
        align="start"
        sideOffset={6}
        className={cn(
          'z-50 min-w-[180px] rounded-xl bg-white p-1.5 shadow-dropdown border border-border animate-fade-in',
          className,
        )}
        {...props}
      />
    </RadixDropdownMenu.Portal>
  )
}

export function DropdownMenuItem({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixDropdownMenu.Item>) {
  return (
    <RadixDropdownMenu.Item
      className={cn(
        'relative flex cursor-pointer select-none items-center gap-2 rounded-lg px-3 py-2 text-sm text-neutral-700 outline-none hover:bg-neutral-50 hover:text-neutral-900 transition-colors data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
        className,
      )}
      {...props}
    />
  )
}

export function DropdownMenuCheckboxItem({ className, children, ...props }: React.ComponentPropsWithoutRef<typeof RadixDropdownMenu.CheckboxItem>) {
  return (
    <RadixDropdownMenu.CheckboxItem
      className={cn(
        'relative flex cursor-pointer select-none items-center gap-2 rounded-lg py-2 pl-8 pr-3 text-sm text-neutral-700 outline-none hover:bg-neutral-50 transition-colors',
        className,
      )}
      {...props}
    >
      <span className="absolute left-2.5 flex h-4 w-4 items-center justify-center">
        <RadixDropdownMenu.ItemIndicator>
          <Check className="h-3.5 w-3.5" />
        </RadixDropdownMenu.ItemIndicator>
      </span>
      {children}
    </RadixDropdownMenu.CheckboxItem>
  )
}

export function DropdownMenuSeparator({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixDropdownMenu.Separator>) {
  return (
    <RadixDropdownMenu.Separator
      className={cn('my-1 -mx-1.5 border-t border-border', className)}
      {...props}
    />
  )
}

export function DropdownMenuLabel({ className, ...props }: React.ComponentPropsWithoutRef<typeof RadixDropdownMenu.Label>) {
  return (
    <RadixDropdownMenu.Label
      className={cn('px-3 py-1.5 text-xs font-medium text-neutral-400 uppercase tracking-wider', className)}
      {...props}
    />
  )
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/DropdownMenu.tsx
git commit -m "feat(ui): add DropdownMenu component (Radix wrapper)"
```

---

### Task 13: Remaining UI Primitives (Batch)

**Files:**
- Create: `src/components/ui/Avatar.tsx`
- Create: `src/components/ui/Tabs.tsx`
- Create: `src/components/ui/Separator.tsx`
- Create: `src/components/ui/Alert.tsx`
- Create: `src/components/ui/Checkbox.tsx`
- Create: `src/components/ui/Switch.tsx`
- Create: `src/components/ui/Progress.tsx`
- Create: `src/components/ui/Breadcrumb.tsx`
- Create: `src/components/ui/ScrollArea.tsx`

Each component follows the same pattern:
- Radix UI primitive wrapper (where applicable) or pure Tailwind
- CVA variants for size/color
- `cn()` for class merging
- `forwardRef` for ref forwarding
- Dark mode support via CSS variables

- [ ] **Step 1: Create all 9 components**

Each file follows the established pattern. Key implementations:

**Avatar.tsx** — Wraps `@radix-ui/react-avatar` with fallback initial, brand color support.

**Tabs.tsx** — Wraps `@radix-ui/react-tabs` with branded active indicator, animated underline.

**Separator.tsx** — Wraps `@radix-ui/react-separator` with horizontal/vertical variants.

**Alert.tsx** — Pure Tailwind, variants: default/success/warning/danger/info, with icon slot.

**Checkbox.tsx** — Styled checkbox with brand color, check mark animation.

**Switch.tsx** — Toggle switch with brand color, smooth slide animation.

**Progress.tsx** — Progress bar with brand gradient, optional percentage label.

**Breadcrumb.tsx** — Composable breadcrumb: BreadcrumbItem with separator, current page highlight.

**ScrollArea.tsx** — Custom scrollbar styling via Tailwind + overflow classes.

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/ui/
git commit -m "feat(ui): add Avatar, Tabs, Separator, Alert, Checkbox, Switch, Progress, Breadcrumb, ScrollArea"
```

---

### Task 14: Chart Theme Utility

**Files:**
- Create: `src/lib/utils/chart.ts`

- [ ] **Step 1: Create Recharts theme configuration**

```typescript
// src/lib/utils/chart.ts
export const chartColors = {
  brand: [
    'hsl(284, 30%, 52%)',
    'hsl(173, 58%, 39%)',
    'hsl(43, 74%, 66%)',
    'hsl(24, 95%, 53%)',
    'hsl(197, 71%, 52%)',
  ],
  brandFaded: [
    'hsl(284, 30%, 52%, 0.15)',
    'hsl(173, 58%, 39%, 0.15)',
    'hsl(43, 74%, 66%, 0.15)',
    'hsl(24, 95%, 53%, 0.15)',
    'hsl(197, 71%, 52%, 0.15)',
  ],
}

export const chartDefaults = {
  gridColor: 'hsl(0, 0%, 90%)',
  axisColor: 'hsl(0, 0%, 60%)',
  tooltipBg: '#fff',
  tooltipBorder: 'hsl(0, 0%, 90%)',
  tooltipShadow: '0 4px 12px rgba(0,0,0,0.08)',
}

export const barRadius = [4, 4, 0, 0] as [number, number, number, number]
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/lib/utils/chart.ts
git commit -m "feat(ui): add Recharts theme configuration utility"
```

---

## Phase 3: Shared Component Upgrades

### Task 15: Enhanced DataTable

**Files:**
- Modify: `src/components/shared/DataTable.tsx`

- [ ] **Step 1: Add sorting support, skeleton rows using new Skeleton component, and animated transitions**

Replace the existing DataTable with enhanced version that adds:
- Column sorting (click header to toggle asc/desc/none)
- Integrated Skeleton loading from `@/components/ui/Skeleton`
- Framer Motion `layout` animations for row reordering
- Row selection support
- "Showing X of Y" uses brand color

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/shared/DataTable.tsx
git commit -m "feat(ui): enhance DataTable with sorting, skeletons, and animations"
```

---

### Task 16: Enhanced EmptyState

**Files:**
- Modify: `src/components/shared/EmptyState.tsx`

- [ ] **Step 1: Add illustration support and Framer Motion entrance animation**

Enhance EmptyState to support:
- Custom icon prop (defaults to Inbox)
- Framer Motion fadeInUp entrance
- Optional illustration slot (SVG component)
- Consistent with brand palette

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/shared/EmptyState.tsx
git commit -m "feat(ui): enhance EmptyState with animations and illustration support"
```

---

### Task 17: Enhanced LoadingSpinner

**Files:**
- Modify: `src/components/shared/LoadingSpinner.tsx`

- [ ] **Step 1: Replace basic spinner with branded animation**

Replace the current spinner with a branded VernonEdu animation using brand-600 color and Framer Motion for smooth entrance/exit.

- [ ] **Step 2: Verify build**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/shared/LoadingSpinner.tsx
git commit -m "feat(ui): enhance LoadingSpinner with branded animation"
```

---

### Task 18: Enhanced StatusBadge

**Files:**
- Modify: `src/components/shared/StatusBadge.tsx`

- [ ] **Step 1: Refactor StatusBadge to use new Badge component**

Replace hard-coded Tailwind classes with Badge component variants:
- `confirmed`/`paid`/`active`/`open`/`approved` → `variant="success"`
- `pending`/`partial`/`sent`/`ongoing`/`unpaid` → `variant="warning"`
- `overdue`/`dropped`/`cancelled`/`rejected`/`terminated` → `variant="danger"`
- `draft`/`completed`/`full`/`inactive` → `variant="secondary"`

- [ ] **Step 2: Verify build + visual check**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add src/components/shared/StatusBadge.tsx
git commit -m "refactor(ui): StatusBadge uses new Badge component with semantic variants"
```

---

## Phase 4: Key Page Redesigns (frontend-design Skill)

### Task 19: Redesign Login Page

**Files:**
- Modify: `src/pages/Login.tsx`

**Aesthetic Direction:** "Refined Education" — warm, inviting, professional. Think premium ed-tech brand. NOT generic SaaS login.

Use `frontend-design:frontend-design` skill guidance:
- Subtle grain texture overlay on background
- Staggered entrance animation for form elements
- Branded gradient background with geometric pattern
- Refined micro-interactions on focus/hover states
- Password visibility toggle with smooth icon swap

- [ ] **Step 1: Redesign Login.tsx with distinctive VernonEdu aesthetic**
- [ ] **Step 2: Visual check in browser**
- [ ] **Step 3: Commit**

```bash
git add src/pages/Login.tsx
git commit -m "feat(design): redesign Login page with distinctive VernonEdu aesthetic"
```

---

### Task 20: Redesign Internal Dashboard

**Files:**
- Modify: `src/portals/internal/pages/Dashboard.tsx`

**Aesthetic Direction:** "Data-Rich Command Center" — dense but clear, sophisticated metrics display. NOT generic admin dashboard.

Use `frontend-design:frontend-design` skill guidance:
- KPI cards with subtle gradient backgrounds per metric type
- Staggered entrance animation for KPI grid
- Recent enrollments list with avatar + animated status transitions
- Use new Card, Badge, Skeleton components
- Recharts mini sparkline in KPI cards (trend indicator)
- Depth through layered card shadows

- [ ] **Step 1: Redesign Dashboard.tsx with rich data visualization aesthetic**
- [ ] **Step 2: Visual check in browser**
- [ ] **Step 3: Commit**

```bash
git add src/portals/internal/pages/Dashboard.tsx
git commit -m "feat(design): redesign Internal Dashboard with data-rich command center aesthetic"
```

---

### Task 21: Redesign TopNavBar

**Files:**
- Modify: `src/components/layout/TopNavBar.tsx`

**Aesthetic Direction:** "Clean Authority" — minimal but premium navigation.

Use new `DropdownMenu` component (replacing inline Radix usage). Add theme toggle button (sun/moon icon). Add smooth mobile menu animation.

- [ ] **Step 1: Refactor TopNavBar to use new UI components + add theme toggle**
- [ ] **Step 2: Visual check in browser**
- [ ] **Step 3: Commit**

```bash
git add src/components/layout/TopNavBar.tsx
git commit -m "feat(design): redesign TopNavBar with theme toggle and new UI components"
```

---

### Task 22: Add Page Transitions

**Files:**
- Modify: `src/App.tsx`

- [ ] **Step 1: Wrap route content in Framer Motion AnimatePresence for smooth page transitions**

Add `motion.div` wrapper with `pageTransition` variants around each portal's route outlet. This creates smooth fade+slide transitions between pages.

- [ ] **Step 2: Verify transitions in browser**
- [ ] **Step 3: Commit**

```bash
git add src/App.tsx
git commit -m "feat(ui): add Framer Motion page transitions between routes"
```

---

### Task 23: Final Integration Test

**Files:**
- All modified files

- [ ] **Step 1: Run full build**

```bash
cd frontend && npm run build
```

- [ ] **Step 2: Run type check**

```bash
cd frontend && npx tsc --noEmit
```

- [ ] **Step 3: Run existing tests**

```bash
cd frontend && npm test
```

- [ ] **Step 4: Visual regression check — manually verify each portal renders correctly**

Open browser to:
- `http://localhost:5173/login` — Login page redesign
- `http://localhost:5173/internal` — Dashboard redesign
- Toggle dark mode — verify theme switch

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "chore: frontend gap close — UI library, design system, key page redesigns"
```

---

## Component Inventory (After Completion)

| Component | Status | Phase |
|-----------|--------|-------|
| Button | Existing | — |
| Input | Existing | — |
| Label | Existing | — |
| Select | Existing | — |
| Textarea | Existing | — |
| Dialog | New | 2 |
| Card | New | 2 |
| Badge | New | 2 |
| Skeleton | New | 2 |
| Tooltip | New | 2 |
| Sheet | New | 2 |
| DropdownMenu | New | 2 |
| Avatar | New | 2 |
| Tabs | New | 2 |
| Separator | New | 2 |
| Alert | New | 2 |
| Checkbox | New | 2 |
| Switch | New | 2 |
| Progress | New | 2 |
| Breadcrumb | New | 2 |
| ScrollArea | New | 2 |
| ThemeProvider | New | 1 |
| Motion Presets | New | 1 |
| Chart Theme | New | 2 |

**Total new components: 21 | Total enhanced: 8 | Total tasks: 23**
