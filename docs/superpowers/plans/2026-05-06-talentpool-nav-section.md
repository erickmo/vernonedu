# TalentPool Nav Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote TalentPool from a single item in "Pendidikan" to its own NavSection with two pipeline-based submenu items.

**Architecture:** Add `TALENTPOOL_ITEMS` const to navItems.ts (parallel to `FINANCE_ITEMS`/`HRM_ITEMS`), fix the pendidikan section slice to skip talentpool, and add a new `talent-pool` NavSection. Create a second page `TalentPoolPlacedPage` for the "Ditempatkan" submenu. Existing service is sufficient — `talentPoolService.list(params)` already accepts status filter.

**Tech Stack:** React 18, TypeScript, React Router 6, CSS Modules, TanStack React Query 5, ListPageTemplate widget, Lucide icons

---

## File Map

| File | Action |
|------|--------|
| `web-dashboard/src/layouts/AppSidebar/navItems.ts` | Modify — fix pendidikan slice, add TALENTPOOL_ITEMS + NavSection |
| `web-dashboard/src/app/routes.tsx` | Modify — add lazy import + route for TalentPoolPlacedPage |
| `web-dashboard/src/pages/TalentPool/TalentPoolPage.tsx` | Modify — update title + helpText only |
| `web-dashboard/src/pages/TalentPool/TalentPoolPlacedPage.tsx` | Create — new page for placed candidates |

---

### Task 1: Add TALENTPOOL_ITEMS and new NavSection to navItems.ts

**Files:**
- Modify: `web-dashboard/src/layouts/AppSidebar/navItems.ts`

Current state:
- `pendidikan` section uses `ALL_ITEMS.slice(1, 8)` which includes talentpool at index 6
- No dedicated section for TalentPool

- [ ] **Step 1: Add TALENTPOOL_ITEMS const**

In `navItems.ts`, after the HRM_ITEMS block (around line 437, before `// ─── Section grouping`), add:

```ts
// ─── TalentPool sub-nav items ───────────────────────────────────────────────────

const TALENTPOOL_ITEMS: NavItem[] = [
  {
    key: 'talentpool-pipeline',
    label: 'Dalam Pipeline',
    icon: Users,
    path: '/talentpool',
    hasAccess: (ctx) => canViewTalentPool(ctx),
  },
  {
    key: 'talentpool-placed',
    label: 'Ditempatkan',
    icon: Trophy,
    path: '/talentpool/placed',
    hasAccess: (ctx) => canViewTalentPool(ctx),
  },
]
```

- [ ] **Step 2: Fix pendidikan section slice**

Change the `pendidikan` section's items from:
```ts
items: ALL_ITEMS.slice(1, 8), // Kurikulum..Sertifikat
```
to:
```ts
items: [...ALL_ITEMS.slice(1, 6), ALL_ITEMS[7]], // Kurikulum..Siswa + Sertifikat (skip talentpool)
```

This removes talentpool (index 6) from Pendidikan without changing ALL_ITEMS order — all other section index references remain valid.

- [ ] **Step 3: Add talent-pool NavSection**

In `NAV_SECTIONS`, insert the new section after `pendidikan`:

```ts
{
  key: 'talent-pool',
  label: 'Talent Pool',
  icon: Magnet,
  items: TALENTPOOL_ITEMS,
},
```

Full updated `NAV_SECTIONS` block:
```ts
export const NAV_SECTIONS: NavSection[] = [
  {
    key: 'utama',
    label: 'Utama',
    icon: LayoutDashboard,
    items: [ALL_ITEMS[0]], // Dashboard
  },
  {
    key: 'pendidikan',
    label: 'Pendidikan',
    icon: BookOpen,
    items: [...ALL_ITEMS.slice(1, 6), ALL_ITEMS[7]], // Kurikulum..Siswa + Sertifikat
  },
  {
    key: 'talent-pool',
    label: 'Talent Pool',
    icon: Magnet,
    items: TALENTPOOL_ITEMS,
  },
  {
    key: 'operasi',
    label: 'Operasi',
    icon: MapPin,
    items: [ALL_ITEMS[8], ALL_ITEMS[10]], // Leads, Pembayaran
  },
  {
    key: 'marketing',
    label: 'Marketing',
    icon: Megaphone,
    items: ALL_ITEMS.slice(11, 14), // Marketing, CRM, Partner
  },
  {
    key: 'keuangan',
    label: 'Keuangan',
    icon: Wallet,
    items: FINANCE_ITEMS,
  },
  {
    key: 'sdm',
    label: 'SDM',
    icon: UserCog,
    items: HRM_ITEMS,
  },
  {
    key: 'pengembangan',
    label: 'Pengembangan',
    icon: Rocket,
    items: [ALL_ITEMS[9], ...ALL_ITEMS.slice(16, 18)], // Lokasi, Proyek, Business Dev
  },
  {
    key: 'sistem',
    label: 'Sistem',
    icon: Settings,
    items: ALL_ITEMS.slice(18), // CMS, Persetujuan, Notifikasi, Pengaturan
  },
]
```

- [ ] **Step 4: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep navItems
```
Expected: no errors for navItems.ts

- [ ] **Step 5: Commit**

```bash
git add web-dashboard/src/layouts/AppSidebar/navItems.ts
git commit -m "feat(nav): add TalentPool as standalone NavSection with pipeline submenus"
```

---

### Task 2: Update TalentPoolPage title

**Files:**
- Modify: `web-dashboard/src/pages/TalentPool/TalentPoolPage.tsx`

- [ ] **Step 1: Update title and help text**

Change `title="Talent Pool"` → `title="Dalam Pipeline"` and update helpTitle/helpText:

```tsx
<ListPageTemplate<TalentPoolEntry>
  title="Dalam Pipeline"
  queryKey="talentpool"
  fetcher={(params) => talentPoolService.list(params)}
  columns={columns}
  rowActions={rowActions}
  searchPlaceholder="Cari talent..."
  exportFilename="talent-pool"
  emptyTitle="Belum ada kandidat dalam pipeline"
  emptyDescription="Talent pool akan terisi dari pipeline Program Karir yang telah menyelesaikan tahap seleksi."
  helpTitle="Dalam Pipeline"
  helpText="Daftar kandidat Program Karir yang sedang aktif dalam talent pool dan belum ditempatkan."
/>
```

- [ ] **Step 2: Commit**

```bash
git add web-dashboard/src/pages/TalentPool/TalentPoolPage.tsx
git commit -m "feat(talent-pool): rename page title to Dalam Pipeline"
```

---

### Task 3: Create TalentPoolPlacedPage

**Files:**
- Create: `web-dashboard/src/pages/TalentPool/TalentPoolPlacedPage.tsx`

- [ ] **Step 1: Create the page**

```tsx
import { UserCheck } from 'lucide-react'
import { ListPageTemplate } from '@/widgets/ListPageTemplate/ListPageTemplate'
import type { ColumnDef, RowActionDef } from '@/widgets/DataTable/DataTable'
import { talentPoolService } from '@/services/talentpool.service'
import type { ListParams } from '@/services/createEntityService'

interface TalentPoolEntry {
  id: string
  student_name: string
  department_name?: string
  status?: string
  placement?: {
    company_name?: string
    position?: string
    start_date?: string
  }
  [key: string]: unknown
}

const columns: ColumnDef<TalentPoolEntry>[] = [
  {
    key: 'student_name',
    header: 'Nama',
    sortable: true,
    render: (_v, row) => (
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: '50%',
          background: 'var(--color-success-subtle)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--color-success)', flexShrink: 0, fontSize: 'var(--font-sm)', fontWeight: 600,
        }}>
          {row.student_name?.charAt(0)?.toUpperCase() || '?'}
        </div>
        <div style={{ fontWeight: 600, fontSize: 'var(--font-base)' }}>
          {row.student_name || '—'}
        </div>
      </div>
    ),
  },
  {
    key: 'department_name',
    header: 'Departemen',
    sortable: true,
    width: 160,
    render: (_v, row) => row.department_name || '—',
  },
  {
    key: 'placement.company_name',
    header: 'Perusahaan',
    width: 180,
    render: (_v, row) => (row.placement as any)?.company_name || '—',
  },
  {
    key: 'placement.position',
    header: 'Posisi',
    width: 160,
    render: (_v, row) => (row.placement as any)?.position || '—',
  },
  {
    key: 'placement.start_date',
    header: 'Tanggal Mulai',
    width: 140,
    render: (_v, row) => {
      const d = (row.placement as any)?.start_date
      return d ? new Date(d).toLocaleDateString('id-ID') : '—'
    },
  },
]

const rowActions: RowActionDef<TalentPoolEntry>[] = [
  {
    key: 'view',
    label: 'Lihat Detail',
    icon: <UserCheck size={14} />,
    onClick: () => {},
  },
]

export default function TalentPoolPlacedPage() {
  return (
    <ListPageTemplate<TalentPoolEntry>
      title="Ditempatkan"
      queryKey="talentpool-placed"
      fetcher={(params: ListParams) => talentPoolService.list({ ...params, status: 'placed' })}
      columns={columns}
      rowActions={rowActions}
      searchPlaceholder="Cari kandidat..."
      exportFilename="talentpool-ditempatkan"
      emptyTitle="Belum ada kandidat yang ditempatkan"
      emptyDescription="Kandidat akan muncul di sini setelah status diubah menjadi Ditempatkan."
      helpTitle="Ditempatkan"
      helpText="Daftar kandidat Program Karir yang telah berhasil ditempatkan di perusahaan partner."
    />
  )
}
```

- [ ] **Step 2: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep TalentPoolPlaced
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add web-dashboard/src/pages/TalentPool/TalentPoolPlacedPage.tsx
git commit -m "feat(talent-pool): add TalentPoolPlacedPage for placed candidates"
```

---

### Task 4: Register route for TalentPoolPlacedPage

**Files:**
- Modify: `web-dashboard/src/app/routes.tsx`

- [ ] **Step 1: Add lazy import**

After the existing `TalentPoolPage` import (around line 51):
```ts
const TalentPoolPage      = lazy(() => import('@/pages/TalentPool/TalentPoolPage'))
const TalentPoolPlacedPage = lazy(() => import('@/pages/TalentPool/TalentPoolPlacedPage'))
```

- [ ] **Step 2: Add route**

After `{ path: 'talentpool', element: <S><TalentPoolPage /></S> }`, add:
```ts
{ path: 'talentpool/placed',  element: <S><TalentPoolPlacedPage /></S> },
```

- [ ] **Step 3: TypeScript check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep -i "routes\|talentpool"
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add web-dashboard/src/app/routes.tsx
git commit -m "feat(routes): register /talentpool/placed route"
```

---

### Task 5: Verify in browser

- [ ] **Step 1: Start dev server**

```bash
cd web-dashboard && npm run dev
```

- [ ] **Step 2: Verify nav**

- Open `http://localhost:3001`
- Navbar1 shows "Talent Pool" as top-level section
- Clicking expands to show "Dalam Pipeline" and "Ditempatkan"
- "Talent Pool" no longer appears inside "Pendidikan" section

- [ ] **Step 3: Verify routes**

- `/talentpool` loads with title "Dalam Pipeline"
- `/talentpool/placed` loads with title "Ditempatkan"
- Both pages render table without TypeScript/console errors
