# Internal Portal Complete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 403 for non-CEO roles, add 10 missing internal portal pages, and add role-aware navigation.

**Architecture:** Three waves. Wave 1 (single agent) fixes 403 and adds `roleNav.ts`. Wave 2 (5 parallel subagents) builds missing pages — each subagent creates page components + API hooks without touching `App.tsx` or `InternalPortal.tsx`. Wave 3 (single agent) wires all new routes and switches `InternalPortal.tsx` to role-aware nav.

**Tech Stack:** React 18, TypeScript, TailwindCSS 3, `@tanstack/react-query`, `axios` (via `apiClient`), Radix UI (`@radix-ui/react-dialog`), `react-hook-form` + `zod`, `sonner` (toast), Lucide React, `date-fns`.

---

## File Map

| Wave | Action | File |
|------|--------|------|
| W1 | Modify | `frontend/src/App.tsx` |
| W1 | Create | `frontend/src/lib/auth/roleNav.ts` |
| W2-SA1 | Create | `frontend/src/lib/api/people.ts` |
| W2-SA1 | Create | `frontend/src/portals/internal/pages/Departments.tsx` |
| W2-SA1 | Create | `frontend/src/portals/internal/pages/TeamMembers.tsx` |
| W2-SA1 | Create | `frontend/src/portals/internal/pages/Proposals.tsx` |
| W2-SA2 | Create | `frontend/src/lib/api/academic.ts` |
| W2-SA2 | Create | `frontend/src/portals/internal/pages/Budget.tsx` |
| W2-SA2 | Create | `frontend/src/portals/internal/pages/ProfitSplit.tsx` |
| W2-SA3 | Create | `frontend/src/lib/api/businessops.ts` |
| W2-SA3 | Create | `frontend/src/portals/internal/pages/Partners.tsx` |
| W2-SA3 | Create | `frontend/src/portals/internal/pages/Vouchers.tsx` |
| W2-SA3 | Create | `frontend/src/portals/internal/pages/Calendar.tsx` |
| W2-SA4 | Extend | `frontend/src/lib/api/franchise.ts` |
| W2-SA4 | Create | `frontend/src/portals/internal/pages/Franchises.tsx` |
| W2-SA5 | Create | `frontend/src/lib/api/platform-admin.ts` |
| W2-SA5 | Create | `frontend/src/portals/internal/pages/Notifications.tsx` |
| W2-SA5 | Modify | `frontend/src/portals/internal/pages/Students.tsx` |
| W2-SA5 | Modify | `frontend/src/portals/internal/pages/Enrollments.tsx` |
| W2-SA5 | Modify | `frontend/src/portals/internal/pages/Payments.tsx` |
| W3 | Modify | `frontend/src/App.tsx` |
| W3 | Modify | `frontend/src/portals/internal/InternalPortal.tsx` |

---

## ═══════════════════════════════════════
## WAVE 1 — FOUNDATION (single agent)
## ═══════════════════════════════════════

---

## Task 1: Fix 403 — Update allowedRoles

**Files:**
- Modify: `frontend/src/App.tsx`

- [ ] **Step 1: Update allowedRoles on line 70**

In `frontend/src/App.tsx`, find:
```ts
<Route element={<ProtectedRoute allowedRoles={['admin', 'ceo', 'manager', 'staff', 'facilitator']} />}>
```

Replace with:
```ts
<Route element={<ProtectedRoute allowedRoles={['ceo', 'admin', 'vernonedu_admin', 'finance', 'academic_leader', 'dept_leader', 'course_creator', 'facilitator']} />}>
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no TypeScript errors related to this change.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/App.tsx
git commit -m "fix(frontend): allow all internal roles in ProtectedRoute — fixes 403 for finance/dept_leader/etc"
```

---

## Task 2: Create roleNav utility

**Files:**
- Create: `frontend/src/lib/auth/roleNav.ts`

- [ ] **Step 1: Create `frontend/src/lib/auth/roleNav.ts`**

```ts
import type { NavItem } from '@/components/layout/TopNavBar'

interface RoleNavItem extends NavItem {
  allowedRoles?: string[]
}

const INTERNAL_NAV: RoleNavItem[] = [
  { to: '/internal', label: 'Dashboard', end: true },
  { to: '/internal/enrollments', label: 'Enrollments' },
  {
    to: '/internal/payments',
    label: 'Payments',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'finance'],
  },
  { to: '/internal/courses', label: 'Courses' },
  {
    to: '/internal/students',
    label: 'Students',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  {
    to: '/internal/departments',
    label: 'Departments',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
  },
  {
    to: '/internal/team-members',
    label: 'Team Members',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin', 'dept_leader', 'academic_leader'],
  },
  {
    to: '/internal/proposals',
    label: 'Proposals',
    allowedRoles: [
      'ceo', 'admin', 'vernonedu_admin',
      'dept_leader', 'academic_leader', 'course_creator', 'finance', 'facilitator',
    ],
  },
  {
    to: '/internal/budget',
    label: 'Budget',
    allowedRoles: ['course_creator', 'dept_leader', 'vernonedu_admin', 'ceo'],
  },
  {
    to: '/internal/profit-split',
    label: 'Profit Split',
    allowedRoles: ['ceo', 'vernonedu_admin', 'course_creator'],
  },
  {
    to: '/internal/partners',
    label: 'Partners',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  {
    to: '/internal/vouchers',
    label: 'Vouchers',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  { to: '/internal/calendar', label: 'Calendar' },
  {
    to: '/internal/franchises',
    label: 'Franchises',
    allowedRoles: ['ceo', 'admin', 'vernonedu_admin'],
  },
  {
    to: '/internal/notifications',
    label: 'Notifications',
    allowedRoles: ['admin', 'vernonedu_admin'],
  },
]

export function getInternalNavItems(role: string): NavItem[] {
  return INTERNAL_NAV
    .filter((item) => !item.allowedRoles || item.allowedRoles.includes(role))
    .map(({ allowedRoles: _r, ...item }) => item)
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/auth/roleNav.ts
git commit -m "feat(frontend): add roleNav utility for role-filtered internal nav items"
```

---

## ═══════════════════════════════════════
## WAVE 2 — MISSING PAGES (5 parallel subagents)
## IMPORTANT: Tasks 3–16 may run in parallel.
## DO NOT modify App.tsx or InternalPortal.tsx in Wave 2.
## ═══════════════════════════════════════

---

## Task 3: People API hooks

**Files:**
- Create: `frontend/src/lib/api/people.ts`

- [ ] **Step 1: Create `frontend/src/lib/api/people.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Types ──────────────────────────────────────────────────────────────────

export interface Department {
  id: string
  name: string
  leader_id: string
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

export interface TeamMember {
  id: string
  user_id: string
  full_name: string
  phone: string
  department_id?: string
  role: string
  employment_status: 'active' | 'inactive' | 'on_leave'
  joined_at: string
  is_facilitator: boolean
  created_at: string
  updated_at: string
}

export interface FeeTier {
  id: string
  name: string
  amount_per_class?: number
  amount_per_course?: number
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

export interface FacilitatorProposal {
  id: string
  course_id: string
  proposed_by: string
  facilitator_id: string
  fee_tier_id: string
  fee_basis: 'per_class' | 'per_course' | 'both'
  dept_leader_status: 'pending' | 'approved' | 'rejected'
  dept_leader_reviewed_at?: string
  dept_leader_note?: string
  academic_leader_status: 'pending' | 'approved' | 'rejected'
  academic_leader_reviewed_at?: string
  academic_leader_note?: string
  final_status: 'pending' | 'approved' | 'rejected'
  created_at: string
  updated_at: string
}

// ── Department Hooks ───────────────────────────────────────────────────────

export function useDepartments() {
  return useQuery({
    queryKey: ['departments'],
    queryFn: () => apiClient.get<Department[]>('/departments').then((r) => r.data),
  })
}

// ── Team Member Hooks ──────────────────────────────────────────────────────

export function useTeamMembersFull() {
  return useQuery({
    queryKey: ['team-members-full'],
    queryFn: () => apiClient.get<TeamMember[]>('/team-members').then((r) => r.data),
  })
}

export interface CreateTeamMemberInput {
  full_name: string
  phone: string
  role: string
  department_id?: string
  employment_status: 'active' | 'inactive' | 'on_leave'
  is_facilitator: boolean
}

export function useCreateTeamMember() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateTeamMemberInput) =>
      apiClient.post<TeamMember>('/team-members', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['team-members-full'] }),
  })
}

export function useDeactivateUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (userId: string) =>
      apiClient.delete(`/users/${userId}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['team-members-full'] }),
  })
}

export function useFeeTiersFull() {
  return useQuery({
    queryKey: ['fee-tiers-full'],
    queryFn: () => apiClient.get<FeeTier[]>('/fee-tiers').then((r) => r.data),
  })
}

export interface CreateFeeTierInput {
  name: string
  amount_per_class?: number
  amount_per_course?: number
}

export function useCreateFeeTier() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateFeeTierInput) =>
      apiClient.post<FeeTier>('/fee-tiers', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['fee-tiers-full'] }),
  })
}

// ── Proposal Hooks ─────────────────────────────────────────────────────────

export function useProposal(id: string) {
  return useQuery({
    queryKey: ['proposal', id],
    queryFn: () =>
      apiClient.get<FacilitatorProposal>(`/facilitator-proposals/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export interface CreateProposalInput {
  course_id: string
  facilitator_id: string
  fee_tier_id: string
  fee_basis: 'per_class' | 'per_course' | 'both'
}

export function useCreateProposal() {
  return useMutation({
    mutationFn: (input: CreateProposalInput) =>
      apiClient.post<FacilitatorProposal>('/facilitator-proposals', input).then((r) => r.data),
  })
}

export interface ReviewInput {
  status: 'approved' | 'rejected'
  note?: string
}

export function useDeptLeaderReview() {
  return useMutation({
    mutationFn: ({ id, ...body }: ReviewInput & { id: string }) =>
      apiClient
        .post(`/facilitator-proposals/${id}/dept-review`, body)
        .then((r) => r.data),
  })
}

export function useAcademicLeaderReview() {
  return useMutation({
    mutationFn: ({ id, ...body }: ReviewInput & { id: string }) =>
      apiClient
        .post(`/facilitator-proposals/${id}/academic-review`, body)
        .then((r) => r.data),
  })
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/api/people.ts
git commit -m "feat(frontend): add people API hooks — departments, team members, proposals"
```

---

## Task 4: Departments page

**Files:**
- Create: `frontend/src/portals/internal/pages/Departments.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/Departments.tsx`**

```tsx
import { Building2 } from 'lucide-react'
import { useDepartments, type Department } from '@/lib/api/people'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'

const COLUMNS: Column<Department>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Status',
    accessor: 'is_active',
    cell: (row) => (
      <span
        className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
          row.is_active
            ? 'bg-emerald-50 text-emerald-700'
            : 'bg-neutral-100 text-neutral-500'
        }`}
      >
        {row.is_active ? 'Active' : 'Inactive'}
      </span>
    ),
  },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (row) => formatDate(row.created_at),
  },
]

export default function Departments() {
  const { data = [], isLoading } = useDepartments()

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Building2 className="w-5 h-5 text-brand-600" />}
        title="Departments"
        description={`${data.length} department${data.length !== 1 ? 's' : ''}`}
      />
      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable
          columns={COLUMNS}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Departments.tsx
git commit -m "feat(frontend): add Departments page — read-only list from GET /api/v1/departments"
```

---

## Task 5: TeamMembers page

**Files:**
- Create: `frontend/src/portals/internal/pages/TeamMembers.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/TeamMembers.tsx`**

```tsx
import { useState } from 'react'
import { Plus, Users } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  useTeamMembersFull,
  useCreateTeamMember,
  useDeactivateUser,
  type TeamMember,
} from '@/lib/api/people'
import { useDepartments } from '@/lib/api/people'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const EMPLOYMENT_STATUS_LABELS: Record<string, string> = {
  active: 'Active',
  inactive: 'Inactive',
  on_leave: 'On Leave',
}

const ROLE_OPTIONS = [
  'ceo', 'finance', 'academic_leader', 'dept_leader',
  'course_creator', 'vernonedu_admin', 'admin', 'facilitator',
] as const

const memberSchema = z.object({
  full_name: z.string().min(2, 'Name required'),
  phone: z.string().min(8, 'Phone required'),
  role: z.enum(ROLE_OPTIONS),
  department_id: z.string().optional(),
  employment_status: z.enum(['active', 'inactive', 'on_leave']),
  is_facilitator: z.boolean(),
})

type MemberForm = z.infer<typeof memberSchema>

export default function TeamMembers() {
  const [open, setOpen] = useState(false)
  const { data = [], isLoading } = useTeamMembersFull()
  const { data: depts = [] } = useDepartments()
  const createMember = useCreateTeamMember()
  const deactivate = useDeactivateUser()

  const deptMap = Object.fromEntries(depts.map((d) => [d.id, d.name]))

  const columns: Column<TeamMember>[] = [
    { header: 'Name', accessor: 'full_name' },
    {
      header: 'Role',
      accessor: 'role',
      cell: (row) => (
        <span className="text-sm capitalize">{row.role.replace(/_/g, ' ')}</span>
      ),
    },
    {
      header: 'Department',
      accessor: 'department_id',
      cell: (row) => (
        <span className="text-sm text-neutral-500">
          {row.department_id ? (deptMap[row.department_id] ?? '—') : '—'}
        </span>
      ),
    },
    {
      header: 'Status',
      accessor: 'employment_status',
      cell: (row) => (
        <span
          className={cn(
            'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
            row.employment_status === 'active'
              ? 'bg-emerald-50 text-emerald-700'
              : row.employment_status === 'on_leave'
              ? 'bg-amber-50 text-amber-700'
              : 'bg-neutral-100 text-neutral-500',
          )}
        >
          {EMPLOYMENT_STATUS_LABELS[row.employment_status]}
        </span>
      ),
    },
    {
      header: 'Facilitator',
      accessor: 'is_facilitator',
      cell: (row) =>
        row.is_facilitator ? (
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-brand-50 text-brand-700">
            Yes
          </span>
        ) : (
          <span className="text-neutral-400 text-sm">—</span>
        ),
    },
    {
      header: 'Joined',
      accessor: 'joined_at',
      cell: (row) => formatDate(row.joined_at),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) => (
        <button
          onClick={() => {
            if (confirm(`Deactivate ${row.full_name}?`)) {
              deactivate.mutate(row.user_id, {
                onSuccess: () => toast.success('User deactivated'),
                onError: () => toast.error('Failed to deactivate'),
              })
            }
          }}
          className="text-xs text-red-500 hover:text-red-700 font-medium"
        >
          Deactivate
        </button>
      ),
    },
  ]

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<MemberForm>({
    resolver: zodResolver(memberSchema),
    defaultValues: { employment_status: 'active', is_facilitator: false },
  })

  const onSubmit = async (form: MemberForm) => {
    try {
      await createMember.mutateAsync(form)
      toast.success('Team member added')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to add member')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Users className="w-5 h-5 text-brand-600" />}
        title="Team Members"
        description={`${data.length} member${data.length !== 1 ? 's' : ''}`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Member
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable
          columns={columns}
          data={data}
          loading={isLoading}
          rowKey={(row) => row.id}
        />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              Add Team Member
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Full Name
                </label>
                <input
                  {...register('full_name')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.full_name && (
                  <p className="text-xs text-red-500 mt-1">{errors.full_name.message}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Phone
                </label>
                <input
                  {...register('phone')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                {errors.phone && (
                  <p className="text-xs text-red-500 mt-1">{errors.phone.message}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Role
                </label>
                <select
                  {...register('role')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  {ROLE_OPTIONS.map((r) => (
                    <option key={r} value={r}>
                      {r.replace(/_/g, ' ')}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Department
                </label>
                <select
                  {...register('department_id')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="">None</option>
                  {depts.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Employment Status
                </label>
                <select
                  {...register('employment_status')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                  <option value="on_leave">On Leave</option>
                </select>
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_facilitator"
                  {...register('is_facilitator')}
                  className="rounded border-neutral-300 text-brand-600 focus:ring-brand-500"
                />
                <label htmlFor="is_facilitator" className="text-sm text-neutral-700">
                  Is Facilitator
                </label>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => { setOpen(false); reset() }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createMember.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50 transition-colors"
                >
                  {createMember.isPending ? 'Adding…' : 'Add Member'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/TeamMembers.tsx
git commit -m "feat(frontend): add TeamMembers page — list, create, deactivate"
```

---

## Task 6: Proposals page

**Files:**
- Create: `frontend/src/portals/internal/pages/Proposals.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/Proposals.tsx`**

```tsx
import { useState } from 'react'
import { Plus, FileText } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  useProposal,
  useCreateProposal,
  useDeptLeaderReview,
  useAcademicLeaderReview,
  type FacilitatorProposal,
} from '@/lib/api/people'
import { useAuth } from '@/lib/auth/useAuth'
import { cn } from '@/lib/utils/cn'
import PageHeader from '@/components/shared/PageHeader'

const proposalSchema = z.object({
  course_id: z.string().uuid('Valid course ID required'),
  facilitator_id: z.string().uuid('Valid facilitator ID required'),
  fee_tier_id: z.string().uuid('Valid fee tier ID required'),
  fee_basis: z.enum(['per_class', 'per_course', 'both']),
})
type ProposalForm = z.infer<typeof proposalSchema>

const reviewSchema = z.object({
  status: z.enum(['approved', 'rejected']),
  note: z.string().optional(),
})
type ReviewForm = z.infer<typeof reviewSchema>

function StatusBadge({ status }: { status: string }) {
  const cls =
    status === 'approved'
      ? 'bg-emerald-50 text-emerald-700'
      : status === 'rejected'
      ? 'bg-red-50 text-red-600'
      : 'bg-amber-50 text-amber-700'
  return (
    <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize', cls)}>
      {status}
    </span>
  )
}

function ProposalRow({
  proposal,
  role,
}: {
  proposal: FacilitatorProposal
  role: string
}) {
  const [reviewOpen, setReviewOpen] = useState(false)
  const deptReview = useDeptLeaderReview()
  const academicReview = useAcademicLeaderReview()

  const canDeptReview =
    role === 'dept_leader' && proposal.dept_leader_status === 'pending'
  const canAcademicReview =
    role === 'academic_leader' && proposal.academic_leader_status === 'pending'
  const canReview = canDeptReview || canAcademicReview

  const { register, handleSubmit, reset } = useForm<ReviewForm>({
    resolver: zodResolver(reviewSchema),
    defaultValues: { status: 'approved' },
  })

  const onReview = async (form: ReviewForm) => {
    try {
      if (canDeptReview) {
        await deptReview.mutateAsync({ id: proposal.id, ...form })
      } else {
        await academicReview.mutateAsync({ id: proposal.id, ...form })
      }
      toast.success('Review submitted')
      setReviewOpen(false)
      reset()
    } catch {
      toast.error('Failed to submit review')
    }
  }

  return (
    <div className="flex items-center justify-between py-4 px-4 border-b border-neutral-100 last:border-0">
      <div className="space-y-1">
        <p className="text-sm font-medium text-neutral-800 font-mono">{proposal.id.slice(0, 8)}…</p>
        <p className="text-xs text-neutral-500">Basis: {proposal.fee_basis.replace(/_/g, ' ')}</p>
        <div className="flex gap-2 mt-1">
          <span className="text-xs text-neutral-400">Dept:</span>
          <StatusBadge status={proposal.dept_leader_status} />
          <span className="text-xs text-neutral-400">Academic:</span>
          <StatusBadge status={proposal.academic_leader_status} />
          <span className="text-xs text-neutral-400">Final:</span>
          <StatusBadge status={proposal.final_status} />
        </div>
      </div>
      {canReview && (
        <>
          <button
            onClick={() => setReviewOpen(true)}
            className="px-3 py-1.5 text-xs font-medium bg-brand-600 text-white rounded-lg hover:bg-brand-700"
          >
            Review
          </button>
          <Dialog.Root open={reviewOpen} onOpenChange={setReviewOpen}>
            <Dialog.Portal>
              <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
              <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-sm bg-white rounded-xl shadow-xl p-6 space-y-4">
                <Dialog.Title className="text-base font-semibold text-neutral-900">
                  Submit Review
                </Dialog.Title>
                <form onSubmit={handleSubmit(onReview)} className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">
                      Decision
                    </label>
                    <select
                      {...register('status')}
                      className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                    >
                      <option value="approved">Approve</option>
                      <option value="rejected">Reject</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-neutral-700 mb-1">
                      Note (optional)
                    </label>
                    <textarea
                      {...register('note')}
                      rows={3}
                      className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none"
                    />
                  </div>
                  <div className="flex justify-end gap-3 pt-1">
                    <button
                      type="button"
                      onClick={() => setReviewOpen(false)}
                      className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700"
                    >
                      Submit
                    </button>
                  </div>
                </form>
              </Dialog.Content>
            </Dialog.Portal>
          </Dialog.Root>
        </>
      )}
    </div>
  )
}

export default function Proposals() {
  const { user } = useAuth()
  const [createOpen, setCreateOpen] = useState(false)
  const [viewId, setViewId] = useState('')
  const createProposal = useCreateProposal()

  const { data: viewProposal } = useProposal(viewId)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<ProposalForm>({
    resolver: zodResolver(proposalSchema),
    defaultValues: { fee_basis: 'per_class' },
  })

  const onSubmit = async (form: ProposalForm) => {
    try {
      const created = await createProposal.mutateAsync(form)
      toast.success('Proposal created')
      setCreateOpen(false)
      reset()
      setViewId(created.id)
    } catch {
      toast.error('Failed to create proposal')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<FileText className="w-5 h-5 text-brand-600" />}
        title="Facilitator Proposals"
        description="Create and review facilitator assignment proposals"
        action={
          <button
            onClick={() => setCreateOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Proposal
          </button>
        }
      />

      {viewProposal && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
          <div className="px-4 py-3 border-b border-neutral-100">
            <h3 className="text-sm font-semibold text-neutral-700">Latest Proposal</h3>
          </div>
          <ProposalRow proposal={viewProposal} role={user?.role ?? ''} />
        </div>
      )}

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6">
        <p className="text-sm text-neutral-500">
          Enter a proposal ID above to load and review a specific proposal.
        </p>
        <div className="flex gap-2 mt-3">
          <input
            value={viewId}
            onChange={(e) => setViewId(e.target.value)}
            placeholder="Paste proposal UUID…"
            className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
      </div>

      <Dialog.Root open={createOpen} onOpenChange={setCreateOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              New Facilitator Proposal
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {(
                [
                  ['course_id', 'Course ID (UUID)'],
                  ['facilitator_id', 'Facilitator ID (UUID)'],
                  ['fee_tier_id', 'Fee Tier ID (UUID)'],
                ] as const
              ).map(([field, label]) => (
                <div key={field}>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">
                    {label}
                  </label>
                  <input
                    {...register(field)}
                    className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 font-mono"
                  />
                  {errors[field] && (
                    <p className="text-xs text-red-500 mt-1">{errors[field]?.message}</p>
                  )}
                </div>
              ))}
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">
                  Fee Basis
                </label>
                <select
                  {...register('fee_basis')}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                >
                  <option value="per_class">Per Class</option>
                  <option value="per_course">Per Course</option>
                  <option value="both">Both</option>
                </select>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => { setCreateOpen(false); reset() }}
                  className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={createProposal.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
                >
                  {createProposal.isPending ? 'Creating…' : 'Create'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Proposals.tsx
git commit -m "feat(frontend): add Proposals page — create and review facilitator proposals"
```

---

## Task 7: Academic Ops API hooks

**Files:**
- Create: `frontend/src/lib/api/academic.ts`

- [ ] **Step 1: Create `frontend/src/lib/api/academic.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Budget Types ───────────────────────────────────────────────────────────

export interface BudgetTemplateItem {
  id: string
  course_id: string
  label: string
  category?: string
  preset_amount: number
  overridable: boolean
  created_at: string
  updated_at: string
}

export interface BatchBudgetItem {
  id: string
  course_batch_id: string
  template_ref_id?: string
  label: string
  category?: string
  planned_amount: number
  overridable: boolean
  class_id?: string
  created_by: string
  created_at: string
  updated_at: string
}

export interface BudgetRealization {
  id: string
  batch_budget_item_id: string
  class_id?: string
  actual_amount: number
  description: string
  spent_at: string
  proof_url?: string
  recorded_by: string
  created_at: string
  updated_at: string
}

export interface BatchBudgetSummary {
  items: Array<{
    item: BatchBudgetItem
    actual: number
    variance: number
  }>
  total_planned: number
  total_actual: number
  total_variance: number
}

// ── Budget Hooks ───────────────────────────────────────────────────────────

export function useBudgetTemplates(courseId: string) {
  return useQuery({
    queryKey: ['budget-templates', courseId],
    queryFn: () =>
      apiClient
        .get<BudgetTemplateItem[]>(`/courses/${courseId}/budget-templates`)
        .then((r) => r.data),
    enabled: !!courseId,
  })
}

export function useCreateBudgetTemplate(courseId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { label: string; category?: string; preset_amount: number; overridable: boolean }) =>
      apiClient
        .post<BudgetTemplateItem>(`/courses/${courseId}/budget-templates`, input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['budget-templates', courseId] }),
  })
}

export function useBatchBudgetItems(batchId: string) {
  return useQuery({
    queryKey: ['batch-budget-items', batchId],
    queryFn: () =>
      apiClient
        .get<BatchBudgetItem[]>(`/batches/${batchId}/budget-items`)
        .then((r) => r.data),
    enabled: !!batchId,
  })
}

export function useBatchBudgetSummary(batchId: string) {
  return useQuery({
    queryKey: ['batch-budget-summary', batchId],
    queryFn: () =>
      apiClient
        .get<BatchBudgetSummary>(`/batches/${batchId}/budget-summary`)
        .then((r) => r.data),
    enabled: !!batchId,
  })
}

export function useCreateBatchBudgetItem(batchId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { label: string; planned_amount: number; category?: string }) =>
      apiClient
        .post<BatchBudgetItem>(`/batches/${batchId}/budget-items`, input)
        .then((r) => r.data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['batch-budget-items', batchId] })
      qc.invalidateQueries({ queryKey: ['batch-budget-summary', batchId] })
    },
  })
}

export function useBudgetRealizations(itemId: string) {
  return useQuery({
    queryKey: ['budget-realizations', itemId],
    queryFn: () =>
      apiClient
        .get<BudgetRealization[]>(`/budget-items/${itemId}/realizations`)
        .then((r) => r.data),
    enabled: !!itemId,
  })
}

export function useCreateRealization(itemId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { actual_amount: number; description: string; spent_at: string }) =>
      apiClient
        .post<BudgetRealization>(`/budget-items/${itemId}/realizations`, input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['budget-realizations', itemId] }),
  })
}

// ── Profit Split Types ─────────────────────────────────────────────────────

export interface GlobalSettings {
  id: string
  vernonedu_pct: string
  course_creator_pct: string
  dept_leader_pct: string
  updated_by: string
  updated_at: string
}

export interface CourseOverride {
  id: string
  course_id: string
  vernonedu_pct: string
  course_creator_pct: string
  dept_leader_pct: string
  overridden_by: string
  overridden_at: string
  created_at: string
  updated_at: string
}

export interface ExtraRevenue {
  id: string
  course_batch_id: string
  label: string
  amount: string
  added_by: string
  approval_status: 'pending' | 'approved' | 'rejected'
  approved_by?: string
  approved_at?: string
  created_at: string
  updated_at: string
}

// ── Profit Split Hooks ─────────────────────────────────────────────────────

export function useGlobalSettings() {
  return useQuery({
    queryKey: ['profit-split-settings'],
    queryFn: () =>
      apiClient.get<GlobalSettings>('/profit-split/settings').then((r) => r.data),
  })
}

export function useUpdateGlobalSettings() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: { vernonedu_pct: string; course_creator_pct: string; dept_leader_pct: string }) =>
      apiClient.put<GlobalSettings>('/profit-split/settings', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['profit-split-settings'] }),
  })
}

export function useCourseOverride(courseId: string) {
  return useQuery({
    queryKey: ['profit-split-override', courseId],
    queryFn: () =>
      apiClient
        .get<CourseOverride>(`/profit-split/overrides/${courseId}`)
        .then((r) => r.data),
    enabled: !!courseId,
  })
}

export function useCreateCourseOverride() {
  return useMutation({
    mutationFn: (input: { course_id: string; vernonedu_pct: string; course_creator_pct: string; dept_leader_pct: string }) =>
      apiClient.post<CourseOverride>('/profit-split/overrides', input).then((r) => r.data),
  })
}

export function useAddExtraRevenue() {
  return useMutation({
    mutationFn: (input: { course_batch_id: string; label: string; amount: string }) =>
      apiClient.post<ExtraRevenue>('/profit-split/extra-revenue', input).then((r) => r.data),
  })
}

export function useApproveExtraRevenue() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/profit-split/extra-revenue/${id}/approve`).then((r) => r.data),
  })
}

export function useRejectExtraRevenue() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/profit-split/extra-revenue/${id}/reject`).then((r) => r.data),
  })
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/api/academic.ts
git commit -m "feat(frontend): add academic API hooks — budget templates, batch items, profit split"
```

---

## Task 8: Budget page

**Files:**
- Create: `frontend/src/portals/internal/pages/Budget.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/Budget.tsx`**

```tsx
import { useState } from 'react'
import { BookOpen } from 'lucide-react'
import { toast } from 'sonner'
import {
  useBatchBudgetSummary,
  useBatchBudgetItems,
  useCreateBatchBudgetItem,
} from '@/lib/api/academic'
import { formatCurrency } from '@/lib/utils/format'
import PageHeader from '@/components/shared/PageHeader'

type Tab = 'summary' | 'items'

export default function Budget() {
  const [tab, setTab] = useState<Tab>('summary')
  const [batchId, setBatchId] = useState('')
  const [inputId, setInputId] = useState('')

  const { data: summary, isLoading: summaryLoading } = useBatchBudgetSummary(batchId)
  const { data: items = [], isLoading: itemsLoading } = useBatchBudgetItems(batchId)
  const createItem = useCreateBatchBudgetItem(batchId)

  const [newLabel, setNewLabel] = useState('')
  const [newAmount, setNewAmount] = useState('')

  const handleLookup = () => {
    if (inputId.trim()) setBatchId(inputId.trim())
  }

  const handleCreateItem = async () => {
    if (!newLabel || !newAmount) return
    try {
      await createItem.mutateAsync({
        label: newLabel,
        planned_amount: parseFloat(newAmount),
      })
      toast.success('Budget item added')
      setNewLabel('')
      setNewAmount('')
    } catch {
      toast.error('Failed to add item')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<BookOpen className="w-5 h-5 text-brand-600" />}
        title="Budget"
        description="Batch budget items and realizations"
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4">
        <label className="block text-sm font-medium text-neutral-700 mb-2">Batch ID</label>
        <div className="flex gap-2">
          <input
            value={inputId}
            onChange={(e) => setInputId(e.target.value)}
            placeholder="Paste batch UUID…"
            className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
          <button
            onClick={handleLookup}
            className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700"
          >
            Load
          </button>
        </div>
      </div>

      {batchId && (
        <>
          <div className="flex gap-2">
            {(['summary', 'items'] as Tab[]).map((t) => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  tab === t
                    ? 'bg-brand-600 text-white'
                    : 'bg-white border border-neutral-200 text-neutral-600 hover:bg-neutral-50'
                }`}
              >
                {t === 'summary' ? 'Summary' : 'Line Items'}
              </button>
            ))}
          </div>

          {tab === 'summary' && (
            <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6">
              {summaryLoading ? (
                <p className="text-sm text-neutral-400">Loading…</p>
              ) : summary ? (
                <div className="space-y-4">
                  <div className="grid grid-cols-3 gap-4">
                    {[
                      { label: 'Total Planned', value: summary.total_planned },
                      { label: 'Total Actual', value: summary.total_actual },
                      { label: 'Variance', value: summary.total_variance },
                    ].map(({ label, value }) => (
                      <div key={label} className="bg-neutral-50 rounded-lg p-4">
                        <p className="text-xs text-neutral-500 mb-1">{label}</p>
                        <p className="text-lg font-semibold text-neutral-900 font-mono">
                          {formatCurrency(value)}
                        </p>
                      </div>
                    ))}
                  </div>
                  <div className="divide-y divide-neutral-100">
                    {summary.items.map((row) => (
                      <div key={row.item.id} className="flex justify-between py-3">
                        <div>
                          <p className="text-sm font-medium text-neutral-800">{row.item.label}</p>
                          {row.item.category && (
                            <p className="text-xs text-neutral-400">{row.item.category}</p>
                          )}
                        </div>
                        <div className="text-right">
                          <p className="text-sm font-mono text-neutral-800">
                            {formatCurrency(row.item.planned_amount)}
                          </p>
                          <p className="text-xs text-neutral-400 font-mono">
                            actual: {formatCurrency(row.actual)}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <p className="text-sm text-neutral-400">No summary data.</p>
              )}
            </div>
          )}

          {tab === 'items' && (
            <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
              <div className="p-4 border-b border-neutral-100 flex gap-2">
                <input
                  value={newLabel}
                  onChange={(e) => setNewLabel(e.target.value)}
                  placeholder="Label"
                  className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                <input
                  value={newAmount}
                  onChange={(e) => setNewAmount(e.target.value)}
                  placeholder="Planned amount"
                  type="number"
                  className="w-36 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
                <button
                  onClick={handleCreateItem}
                  disabled={createItem.isPending}
                  className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
                >
                  Add
                </button>
              </div>
              {itemsLoading ? (
                <p className="p-4 text-sm text-neutral-400">Loading…</p>
              ) : (
                <div className="divide-y divide-neutral-100">
                  {items.map((item) => (
                    <div key={item.id} className="flex justify-between px-4 py-3">
                      <div>
                        <p className="text-sm font-medium text-neutral-800">{item.label}</p>
                        {item.category && (
                          <p className="text-xs text-neutral-400">{item.category}</p>
                        )}
                      </div>
                      <p className="text-sm font-mono text-neutral-700">
                        {formatCurrency(item.planned_amount)}
                      </p>
                    </div>
                  ))}
                  {items.length === 0 && (
                    <p className="p-4 text-sm text-neutral-400">No items yet.</p>
                  )}
                </div>
              )}
            </div>
          )}
        </>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Budget.tsx
git commit -m "feat(frontend): add Budget page — batch summary + line items"
```

---

## Task 9: ProfitSplit page

**Files:**
- Create: `frontend/src/portals/internal/pages/ProfitSplit.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/ProfitSplit.tsx`**

```tsx
import { useState } from 'react'
import { BarChart2 } from 'lucide-react'
import { toast } from 'sonner'
import {
  useGlobalSettings,
  useUpdateGlobalSettings,
  useCourseOverride,
  useCreateCourseOverride,
  useAddExtraRevenue,
  useApproveExtraRevenue,
  useRejectExtraRevenue,
} from '@/lib/api/academic'
import PageHeader from '@/components/shared/PageHeader'

type Tab = 'settings' | 'overrides' | 'extra-revenue'

export default function ProfitSplit() {
  const [tab, setTab] = useState<Tab>('settings')

  // settings
  const { data: settings, isLoading } = useGlobalSettings()
  const updateSettings = useUpdateGlobalSettings()
  const [settingsForm, setSettingsForm] = useState({ vernonedu_pct: '', course_creator_pct: '', dept_leader_pct: '' })

  // override
  const [overrideCourseId, setOverrideCourseId] = useState('')
  const [lookupId, setLookupId] = useState('')
  const { data: override } = useCourseOverride(overrideCourseId)
  const createOverride = useCreateCourseOverride()
  const [overrideForm, setOverrideForm] = useState({ vernonedu_pct: '', course_creator_pct: '', dept_leader_pct: '' })

  // extra revenue
  const addRevenue = useAddExtraRevenue()
  const approveRevenue = useApproveExtraRevenue()
  const rejectRevenue = useRejectExtraRevenue()
  const [revenueForm, setRevenueForm] = useState({ course_batch_id: '', label: '', amount: '' })
  const [revenueIdAction, setRevenueIdAction] = useState('')

  const handleSettingsSave = async () => {
    try {
      await updateSettings.mutateAsync(settingsForm)
      toast.success('Settings updated')
    } catch {
      toast.error('Failed to update settings')
    }
  }

  const TABS: { key: Tab; label: string }[] = [
    { key: 'settings', label: 'Global Settings' },
    { key: 'overrides', label: 'Course Overrides' },
    { key: 'extra-revenue', label: 'Extra Revenue' },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<BarChart2 className="w-5 h-5 text-brand-600" />}
        title="Profit Split"
        description="Configure revenue distribution percentages"
      />

      <div className="flex gap-2">
        {TABS.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              tab === key
                ? 'bg-brand-600 text-white'
                : 'bg-white border border-neutral-200 text-neutral-600 hover:bg-neutral-50'
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'settings' && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-6 space-y-4 max-w-md">
          {isLoading ? (
            <p className="text-sm text-neutral-400">Loading…</p>
          ) : (
            <>
              {settings && (
                <div className="text-sm text-neutral-500 space-y-1 mb-4">
                  <p>Current: VernonEdu {settings.vernonedu_pct}% / Creator {settings.course_creator_pct}% / Dept {settings.dept_leader_pct}%</p>
                </div>
              )}
              {(['vernonedu_pct', 'course_creator_pct', 'dept_leader_pct'] as const).map((field) => (
                <div key={field}>
                  <label className="block text-sm font-medium text-neutral-700 mb-1 capitalize">
                    {field.replace(/_pct$/, '').replace(/_/g, ' ')} %
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    value={settingsForm[field]}
                    onChange={(e) => setSettingsForm((f) => ({ ...f, [field]: e.target.value }))}
                    className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                  />
                </div>
              ))}
              <button
                onClick={handleSettingsSave}
                disabled={updateSettings.isPending}
                className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
              >
                {updateSettings.isPending ? 'Saving…' : 'Save Settings'}
              </button>
            </>
          )}
        </div>
      )}

      {tab === 'overrides' && (
        <div className="space-y-4 max-w-lg">
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4">
            <label className="block text-sm font-medium text-neutral-700 mb-2">Look up course override</label>
            <div className="flex gap-2">
              <input
                value={lookupId}
                onChange={(e) => setLookupId(e.target.value)}
                placeholder="Course UUID"
                className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
              <button
                onClick={() => setOverrideCourseId(lookupId)}
                className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm hover:bg-brand-700"
              >
                Load
              </button>
            </div>
            {override && (
              <div className="mt-3 text-sm text-neutral-600 space-y-1">
                <p>VernonEdu: {override.vernonedu_pct}%</p>
                <p>Creator: {override.course_creator_pct}%</p>
                <p>Dept: {override.dept_leader_pct}%</p>
              </div>
            )}
          </div>

          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4 space-y-3">
            <h3 className="text-sm font-semibold text-neutral-700">Create Override</h3>
            <div>
              <label className="block text-xs text-neutral-500 mb-1">Course ID</label>
              <input
                value={overrideForm.vernonedu_pct}
                placeholder="Course UUID"
                className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                onChange={(e) => setOverrideForm((f) => ({ ...f, vernonedu_pct: e.target.value }))}
              />
            </div>
            {(['vernonedu_pct', 'course_creator_pct', 'dept_leader_pct'] as const).map((field) => (
              <div key={field}>
                <label className="block text-xs text-neutral-500 mb-1 capitalize">
                  {field.replace(/_pct$/, '').replace(/_/g, ' ')} %
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={overrideForm[field]}
                  onChange={(e) => setOverrideForm((f) => ({ ...f, [field]: e.target.value }))}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
                />
              </div>
            ))}
            <button
              onClick={async () => {
                try {
                  await createOverride.mutateAsync({
                    course_id: overrideCourseId,
                    ...overrideForm,
                  })
                  toast.success('Override created')
                } catch {
                  toast.error('Failed to create override')
                }
              }}
              disabled={createOverride.isPending}
              className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
            >
              {createOverride.isPending ? 'Creating…' : 'Create Override'}
            </button>
          </div>
        </div>
      )}

      {tab === 'extra-revenue' && (
        <div className="space-y-4 max-w-lg">
          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4 space-y-3">
            <h3 className="text-sm font-semibold text-neutral-700">Add Extra Revenue</h3>
            <input
              value={revenueForm.course_batch_id}
              onChange={(e) => setRevenueForm((f) => ({ ...f, course_batch_id: e.target.value }))}
              placeholder="Batch UUID"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <input
              value={revenueForm.label}
              onChange={(e) => setRevenueForm((f) => ({ ...f, label: e.target.value }))}
              placeholder="Label"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <input
              value={revenueForm.amount}
              onChange={(e) => setRevenueForm((f) => ({ ...f, amount: e.target.value }))}
              placeholder="Amount"
              type="number"
              className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <button
              onClick={async () => {
                try {
                  await addRevenue.mutateAsync(revenueForm)
                  toast.success('Revenue added')
                  setRevenueForm({ course_batch_id: '', label: '', amount: '' })
                } catch {
                  toast.error('Failed to add revenue')
                }
              }}
              disabled={addRevenue.isPending}
              className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50"
            >
              {addRevenue.isPending ? 'Adding…' : 'Add Revenue'}
            </button>
          </div>

          <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)] p-4 space-y-3">
            <h3 className="text-sm font-semibold text-neutral-700">Approve / Reject Revenue</h3>
            <div className="flex gap-2">
              <input
                value={revenueIdAction}
                onChange={(e) => setRevenueIdAction(e.target.value)}
                placeholder="Revenue UUID"
                className="flex-1 px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500"
              />
              <button
                onClick={() => approveRevenue.mutate(revenueIdAction, {
                  onSuccess: () => toast.success('Approved'),
                  onError: () => toast.error('Failed'),
                })}
                className="px-3 py-2 bg-emerald-600 text-white rounded-lg text-sm hover:bg-emerald-700"
              >
                Approve
              </button>
              <button
                onClick={() => rejectRevenue.mutate(revenueIdAction, {
                  onSuccess: () => toast.success('Rejected'),
                  onError: () => toast.error('Failed'),
                })}
                className="px-3 py-2 bg-red-500 text-white rounded-lg text-sm hover:bg-red-600"
              >
                Reject
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/ProfitSplit.tsx
git commit -m "feat(frontend): add ProfitSplit page — global settings, overrides, extra revenue"
```

---

## Task 10: Business Ops API hooks

**Files:**
- Create: `frontend/src/lib/api/businessops.ts`

- [ ] **Step 1: Create `frontend/src/lib/api/businessops.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

// ── Partner Types ──────────────────────────────────────────────────────────

export interface Partner {
  id: string
  name: string
  type: 'university' | 'vendor' | 'sponsor' | 'franchise_candidate' | 'community' | 'other'
  status: 'lead' | 'active' | 'inactive'
  contact_name?: string
  contact_email?: string
  contact_phone?: string
  address?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface PartnershipAgreement {
  id: string
  partner_id: string
  status: 'draft' | 'active' | 'expired' | 'terminated'
  created_at: string
  updated_at: string
}

// ── Partner Hooks ──────────────────────────────────────────────────────────

export function usePartners() {
  return useQuery({
    queryKey: ['partners'],
    queryFn: () => apiClient.get<Partner[]>('/partners').then((r) => r.data),
  })
}

export function usePartner(id: string) {
  return useQuery({
    queryKey: ['partner', id],
    queryFn: () => apiClient.get<Partner>(`/partners/${id}`).then((r) => r.data),
    enabled: !!id,
  })
}

export function useCreatePartner() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      name: string
      type: Partner['type']
      contact_name?: string
      contact_email?: string
      contact_phone?: string
      notes?: string
    }) => apiClient.post<Partner>('/partners', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['partners'] }),
  })
}

export function useCreateAgreement() {
  return useMutation({
    mutationFn: (input: { partner_id: string }) =>
      apiClient.post<PartnershipAgreement>('/agreements', input).then((r) => r.data),
  })
}

export function useActivateAgreement() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/agreements/${id}/activate`).then((r) => r.data),
  })
}

// ── Voucher Types ──────────────────────────────────────────────────────────

export interface Voucher {
  id: string
  code: string
  discount_type: 'fixed_amount' | 'percentage' | 'fixed_final_price'
  discount_value: string
  assigned_to?: string
  course_id?: string
  course_batch_id?: string
  valid_from: string
  valid_until?: string
  max_uses?: number
  used_count: number
  is_active: boolean
  created_by: string
  created_at: string
  updated_at: string
}

// ── Voucher Hooks ──────────────────────────────────────────────────────────

export function useVouchers() {
  return useQuery({
    queryKey: ['vouchers'],
    queryFn: () => apiClient.get<Voucher[]>('/vouchers').then((r) => r.data),
  })
}

export function useCreateVoucher() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      code: string
      discount_type: Voucher['discount_type']
      discount_value: string
      valid_from: string
      valid_until?: string
      max_uses?: number
    }) => apiClient.post<Voucher>('/vouchers', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['vouchers'] }),
  })
}

// ── Calendar Types ─────────────────────────────────────────────────────────

export interface CalendarEvent {
  id: string
  title: string
  description?: string
  event_type:
    | 'class_session'
    | 'staff_meeting'
    | 'admin_deadline'
    | 'payment_due'
    | 'facilitator_schedule'
    | 'partner_meeting'
  start_at: string
  end_at: string
  is_all_day: boolean
  location?: string
  agenda?: string
  created_by: string
  created_at: string
}

// ── Calendar Hooks ─────────────────────────────────────────────────────────

export function useCalendarEvents() {
  return useQuery({
    queryKey: ['calendar-events'],
    queryFn: () => apiClient.get<CalendarEvent[]>('/calendar').then((r) => r.data),
  })
}

export function useCreateCalendarEvent() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      title: string
      event_type: CalendarEvent['event_type']
      start_at: string
      end_at: string
      is_all_day: boolean
      description?: string
      location?: string
    }) => apiClient.post<CalendarEvent>('/calendar', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['calendar-events'] }),
  })
}

export function useDeleteCalendarEvent() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => apiClient.delete(`/calendar/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['calendar-events'] }),
  })
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/lib/api/businessops.ts
git commit -m "feat(frontend): add business ops API hooks — partners, vouchers, calendar"
```

---

## Task 11: Partners page

**Files:**
- Create: `frontend/src/portals/internal/pages/Partners.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/Partners.tsx`**

```tsx
import { useState } from 'react'
import { Plus, Handshake } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { usePartners, useCreatePartner, type Partner } from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const PARTNER_TYPES = ['university', 'vendor', 'sponsor', 'franchise_candidate', 'community', 'other'] as const

const STATUS_STYLES: Record<string, string> = {
  lead: 'bg-amber-50 text-amber-700',
  active: 'bg-emerald-50 text-emerald-700',
  inactive: 'bg-neutral-100 text-neutral-500',
}

const partnerSchema = z.object({
  name: z.string().min(2, 'Name required'),
  type: z.enum(PARTNER_TYPES),
  contact_name: z.string().optional(),
  contact_email: z.string().email().optional().or(z.literal('')),
  contact_phone: z.string().optional(),
  notes: z.string().optional(),
})
type PartnerForm = z.infer<typeof partnerSchema>

const COLUMNS: Column<Partner>[] = [
  { header: 'Name', accessor: 'name' },
  {
    header: 'Type',
    accessor: 'type',
    cell: (row) => (
      <span className="text-sm capitalize">{row.type.replace(/_/g, ' ')}</span>
    ),
  },
  {
    header: 'Status',
    accessor: 'status',
    cell: (row) => (
      <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize', STATUS_STYLES[row.status])}>
        {row.status}
      </span>
    ),
  },
  {
    header: 'Contact',
    accessor: 'contact_name',
    cell: (row) => (
      <span className="text-sm text-neutral-500">{row.contact_name ?? '—'}</span>
    ),
  },
  {
    header: 'Created',
    accessor: 'created_at',
    cell: (row) => formatDate(row.created_at),
  },
]

export default function Partners() {
  const [open, setOpen] = useState(false)
  const { data = [], isLoading } = usePartners()
  const createPartner = useCreatePartner()

  const { register, handleSubmit, reset, formState: { errors } } = useForm<PartnerForm>({
    resolver: zodResolver(partnerSchema),
    defaultValues: { type: 'vendor' },
  })

  const onSubmit = async (form: PartnerForm) => {
    try {
      await createPartner.mutateAsync(form)
      toast.success('Partner added')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to add partner')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Handshake className="w-5 h-5 text-brand-600" />}
        title="Partners"
        description={`${data.length} partner${data.length !== 1 ? 's' : ''}`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Partner
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable columns={COLUMNS} data={data} loading={isLoading} rowKey={(r) => r.id} />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">Add Partner</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Name</label>
                <input {...register('name')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                {errors.name && <p className="text-xs text-red-500 mt-1">{errors.name.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Type</label>
                <select {...register('type')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500">
                  {PARTNER_TYPES.map((t) => (
                    <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Contact Name</label>
                <input {...register('contact_name')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Contact Email</label>
                <input {...register('contact_email')} type="email" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Notes</label>
                <textarea {...register('notes')} rows={2} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => { setOpen(false); reset() }} className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800">Cancel</button>
                <button type="submit" disabled={createPartner.isPending} className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50">
                  {createPartner.isPending ? 'Adding…' : 'Add Partner'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Partners.tsx
git commit -m "feat(frontend): add Partners page — list and create partners"
```

---

## Task 12: Vouchers page

**Files:**
- Create: `frontend/src/portals/internal/pages/Vouchers.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/Vouchers.tsx`**

```tsx
import { useState } from 'react'
import { Plus, Tag } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useVouchers, useCreateVoucher, type Voucher } from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const voucherSchema = z.object({
  code: z.string().min(3, 'Code required'),
  discount_type: z.enum(['fixed_amount', 'percentage', 'fixed_final_price']),
  discount_value: z.string().min(1, 'Value required'),
  valid_from: z.string().min(1, 'Start date required'),
  valid_until: z.string().optional(),
  max_uses: z.coerce.number().int().positive().optional(),
})
type VoucherForm = z.infer<typeof voucherSchema>

const COLUMNS: Column<Voucher>[] = [
  { header: 'Code', accessor: 'code', cell: (row) => <span className="font-mono text-sm font-medium">{row.code}</span> },
  { header: 'Type', accessor: 'discount_type', cell: (row) => <span className="text-sm capitalize">{row.discount_type.replace(/_/g, ' ')}</span> },
  { header: 'Value', accessor: 'discount_value', cell: (row) => <span className="font-mono text-sm">{row.discount_value}</span> },
  { header: 'Used', accessor: 'used_count', cell: (row) => <span className="text-sm">{row.used_count}{row.max_uses ? ` / ${row.max_uses}` : ''}</span> },
  {
    header: 'Status',
    accessor: 'is_active',
    cell: (row) => (
      <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium', row.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-neutral-100 text-neutral-500')}>
        {row.is_active ? 'Active' : 'Inactive'}
      </span>
    ),
  },
  { header: 'Valid From', accessor: 'valid_from', cell: (row) => formatDate(row.valid_from) },
]

export default function Vouchers() {
  const [open, setOpen] = useState(false)
  const { data = [], isLoading } = useVouchers()
  const createVoucher = useCreateVoucher()

  const { register, handleSubmit, reset, formState: { errors } } = useForm<VoucherForm>({
    resolver: zodResolver(voucherSchema),
    defaultValues: { discount_type: 'percentage' },
  })

  const onSubmit = async (form: VoucherForm) => {
    try {
      await createVoucher.mutateAsync({
        ...form,
        discount_value: form.discount_value,
        valid_until: form.valid_until || undefined,
      })
      toast.success('Voucher created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create voucher')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Tag className="w-5 h-5 text-brand-600" />}
        title="Vouchers"
        description={`${data.length} voucher${data.length !== 1 ? 's' : ''}`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Create Voucher
          </button>
        }
      />
      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable columns={COLUMNS} data={data} loading={isLoading} rowKey={(r) => r.id} />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">Create Voucher</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Code</label>
                <input {...register('code')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono uppercase focus:outline-none focus:ring-2 focus:ring-brand-500" />
                {errors.code && <p className="text-xs text-red-500 mt-1">{errors.code.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Discount Type</label>
                <select {...register('discount_type')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500">
                  <option value="percentage">Percentage</option>
                  <option value="fixed_amount">Fixed Amount</option>
                  <option value="fixed_final_price">Fixed Final Price</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Discount Value</label>
                <input {...register('discount_value')} type="number" step="0.01" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500" />
                {errors.discount_value && <p className="text-xs text-red-500 mt-1">{errors.discount_value.message}</p>}
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Valid From</label>
                  <input {...register('valid_from')} type="datetime-local" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Valid Until</label>
                  <input {...register('valid_until')} type="datetime-local" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Max Uses (optional)</label>
                <input {...register('max_uses')} type="number" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => { setOpen(false); reset() }} className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800">Cancel</button>
                <button type="submit" disabled={createVoucher.isPending} className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50">
                  {createVoucher.isPending ? 'Creating…' : 'Create'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Vouchers.tsx
git commit -m "feat(frontend): add Vouchers page — list and create discount vouchers"
```

---

## Task 13: Calendar page

**Files:**
- Create: `frontend/src/portals/internal/pages/Calendar.tsx`

- [ ] **Step 1: Create `frontend/src/portals/internal/pages/Calendar.tsx`**

```tsx
import { useState } from 'react'
import { Plus, CalendarDays, Trash2 } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { useCalendarEvents, useCreateCalendarEvent, useDeleteCalendarEvent, type CalendarEvent } from '@/lib/api/businessops'
import { formatDate } from '@/lib/utils/format'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const EVENT_TYPES = [
  'class_session',
  'staff_meeting',
  'admin_deadline',
  'payment_due',
  'facilitator_schedule',
  'partner_meeting',
] as const

const EVENT_TYPE_COLORS: Record<string, string> = {
  class_session: 'bg-brand-50 text-brand-700',
  staff_meeting: 'bg-violet-50 text-violet-700',
  admin_deadline: 'bg-red-50 text-red-600',
  payment_due: 'bg-amber-50 text-amber-700',
  facilitator_schedule: 'bg-emerald-50 text-emerald-700',
  partner_meeting: 'bg-sky-50 text-sky-700',
}

const eventSchema = z.object({
  title: z.string().min(2, 'Title required'),
  event_type: z.enum(EVENT_TYPES),
  start_at: z.string().min(1, 'Start required'),
  end_at: z.string().min(1, 'End required'),
  is_all_day: z.boolean(),
  description: z.string().optional(),
  location: z.string().optional(),
})
type EventForm = z.infer<typeof eventSchema>

export default function Calendar() {
  const [open, setOpen] = useState(false)
  const { data: events = [], isLoading } = useCalendarEvents()
  const createEvent = useCreateCalendarEvent()
  const deleteEvent = useDeleteCalendarEvent()

  const { register, handleSubmit, reset, formState: { errors } } = useForm<EventForm>({
    resolver: zodResolver(eventSchema),
    defaultValues: { event_type: 'staff_meeting', is_all_day: false },
  })

  const onSubmit = async (form: EventForm) => {
    try {
      await createEvent.mutateAsync(form)
      toast.success('Event created')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to create event')
    }
  }

  const sorted = [...events].sort(
    (a, b) => new Date(a.start_at).getTime() - new Date(b.start_at).getTime(),
  )

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<CalendarDays className="w-5 h-5 text-brand-600" />}
        title="Calendar"
        description={`${events.length} event${events.length !== 1 ? 's' : ''}`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Event
          </button>
        }
      />

      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        {isLoading ? (
          <div className="p-6 text-sm text-neutral-400">Loading…</div>
        ) : sorted.length === 0 ? (
          <div className="p-6 text-sm text-neutral-400">No events.</div>
        ) : (
          <div className="divide-y divide-neutral-100">
            {sorted.map((event) => (
              <div key={event.id} className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-3">
                  <div className="text-center min-w-[3rem]">
                    <p className="text-xs text-neutral-400">{formatDate(event.start_at)}</p>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-neutral-800">{event.title}</p>
                    {event.location && (
                      <p className="text-xs text-neutral-400">{event.location}</p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium', EVENT_TYPE_COLORS[event.event_type] ?? 'bg-neutral-100 text-neutral-600')}>
                    {event.event_type.replace(/_/g, ' ')}
                  </span>
                  <button
                    onClick={() => {
                      if (confirm(`Delete "${event.title}"?`)) {
                        deleteEvent.mutate(event.id, {
                          onSuccess: () => toast.success('Event deleted'),
                          onError: () => toast.error('Failed to delete'),
                        })
                      }
                    }}
                    className="text-neutral-300 hover:text-red-400 transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">New Event</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Title</label>
                <input {...register('title')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                {errors.title && <p className="text-xs text-red-500 mt-1">{errors.title.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Type</label>
                <select {...register('event_type')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500">
                  {EVENT_TYPES.map((t) => (
                    <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">Start</label>
                  <input {...register('start_at')} type="datetime-local" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">End</label>
                  <input {...register('end_at')} type="datetime-local" className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Location</label>
                <input {...register('location')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" id="is_all_day" {...register('is_all_day')} className="rounded border-neutral-300 text-brand-600 focus:ring-brand-500" />
                <label htmlFor="is_all_day" className="text-sm text-neutral-700">All day</label>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => { setOpen(false); reset() }} className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800">Cancel</button>
                <button type="submit" disabled={createEvent.isPending} className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50">
                  {createEvent.isPending ? 'Creating…' : 'Create'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 2: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/portals/internal/pages/Calendar.tsx
git commit -m "feat(frontend): add Calendar page — list, create, delete events"
```

---

## Task 14: Franchises page (internal view)

**Files:**
- Extend: `frontend/src/lib/api/franchise.ts`
- Create: `frontend/src/portals/internal/pages/Franchises.tsx`

- [ ] **Step 1: Add `useFranchisees` and `useCreateFranchisee` to `frontend/src/lib/api/franchise.ts`**

Append to end of `frontend/src/lib/api/franchise.ts`:
```ts
export function useFranchisees() {
  return useQuery({
    queryKey: ['franchisees'],
    queryFn: () => apiClient.get<Franchisee[]>('/franchisees').then((r) => r.data),
  })
}

export interface CreateFranchiseeInput {
  name: string
  branch_name: string
  location: string
  contact: string
}

export function useCreateFranchisee() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: CreateFranchiseeInput) =>
      apiClient.post<Franchisee>('/franchisees', input).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['franchisees'] }),
  })
}

export function useCreateRoyaltyRecord() {
  return useMutation({
    mutationFn: (input: {
      franchise_agreement_id: string
      period: string
      gross_revenue: number
    }) => apiClient.post<RoyaltyRecord>('/royalty-records', input).then((r) => r.data),
  })
}

export function useMarkRoyaltyPaid() {
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.post(`/royalty-records/${id}/mark-paid`).then((r) => r.data),
  })
}
```

Note: `useQueryClient` is already imported in `franchise.ts` via `@tanstack/react-query`.

- [ ] **Step 2: Create `frontend/src/portals/internal/pages/Franchises.tsx`**

```tsx
import { useState } from 'react'
import { Plus, Store } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  useFranchisees,
  useCreateFranchisee,
  useRoyaltyRecords,
  useMarkRoyaltyPaid,
  type Franchisee,
  type RoyaltyRecord,
} from '@/lib/api/franchise'
import { formatDate, formatCurrency } from '@/lib/utils/format'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const franchiseeSchema = z.object({
  name: z.string().min(2, 'Name required'),
  branch_name: z.string().min(2, 'Branch name required'),
  location: z.string().min(2, 'Location required'),
  contact: z.string().min(5, 'Contact required'),
})
type FranchiseeForm = z.infer<typeof franchiseeSchema>

const STATUS_STYLES: Record<string, string> = {
  active: 'bg-emerald-50 text-emerald-700',
  inactive: 'bg-neutral-100 text-neutral-500',
  terminated: 'bg-red-50 text-red-600',
}

const ROYALTY_STYLES: Record<string, string> = {
  paid: 'bg-emerald-50 text-emerald-700',
  unpaid: 'bg-amber-50 text-amber-700',
  overdue: 'bg-red-50 text-red-600',
}

type Tab = 'list' | 'royalty'

export default function Franchises() {
  const [tab, setTab] = useState<Tab>('list')
  const [open, setOpen] = useState(false)
  const [selectedFranchiseeId, setSelectedFranchiseeId] = useState('')

  const { data: franchisees = [], isLoading } = useFranchisees()
  const { data: royalties = [], isLoading: royaltyLoading } = useRoyaltyRecords(selectedFranchiseeId)
  const createFranchisee = useCreateFranchisee()
  const markPaid = useMarkRoyaltyPaid()

  const franchiseeColumns: Column<Franchisee>[] = [
    { header: 'Name', accessor: 'name' },
    { header: 'Branch', accessor: 'branch_name' },
    { header: 'Location', accessor: 'location' },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => (
        <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize', STATUS_STYLES[row.status])}>
          {row.status}
        </span>
      ),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) => (
        <button
          onClick={() => { setSelectedFranchiseeId(row.id); setTab('royalty') }}
          className="text-xs text-brand-600 hover:text-brand-700 font-medium"
        >
          View Royalty →
        </button>
      ),
    },
  ]

  const royaltyColumns: Column<RoyaltyRecord>[] = [
    { header: 'Period', accessor: 'period' },
    { header: 'Gross Revenue', accessor: 'gross_revenue', cell: (row) => <span className="font-mono text-sm">{formatCurrency(row.gross_revenue)}</span> },
    { header: 'Total Royalty', accessor: 'total_royalty', cell: (row) => <span className="font-mono text-sm">{formatCurrency(row.total_royalty)}</span> },
    {
      header: 'Status',
      accessor: 'status',
      cell: (row) => (
        <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize', ROYALTY_STYLES[row.status])}>
          {row.status}
        </span>
      ),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) =>
        row.status !== 'paid' ? (
          <button
            onClick={() => markPaid.mutate(row.id, {
              onSuccess: () => toast.success('Marked as paid'),
              onError: () => toast.error('Failed'),
            })}
            className="text-xs text-emerald-600 hover:text-emerald-700 font-medium"
          >
            Mark Paid
          </button>
        ) : (
          <span className="text-xs text-neutral-400">{row.paid_at ? formatDate(row.paid_at) : ''}</span>
        ),
    },
  ]

  const { register, handleSubmit, reset, formState: { errors } } = useForm<FranchiseeForm>({
    resolver: zodResolver(franchiseeSchema),
  })

  const onSubmit = async (form: FranchiseeForm) => {
    try {
      await createFranchisee.mutateAsync(form)
      toast.success('Franchisee added')
      setOpen(false)
      reset()
    } catch {
      toast.error('Failed to add franchisee')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Store className="w-5 h-5 text-brand-600" />}
        title="Franchises"
        description={`${franchisees.length} franchisee${franchisees.length !== 1 ? 's' : ''}`}
        action={
          <button
            onClick={() => setOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Add Franchisee
          </button>
        }
      />

      <div className="flex gap-2">
        {(['list', 'royalty'] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
              tab === t ? 'bg-brand-600 text-white' : 'bg-white border border-neutral-200 text-neutral-600 hover:bg-neutral-50'
            }`}
          >
            {t === 'list' ? 'Franchisees' : `Royalty${selectedFranchiseeId ? ' (selected)' : ''}`}
          </button>
        ))}
      </div>

      {tab === 'list' && (
        <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
          <DataTable columns={franchiseeColumns} data={franchisees} loading={isLoading} rowKey={(r) => r.id} />
        </div>
      )}

      {tab === 'royalty' && (
        <div className="space-y-4">
          {!selectedFranchiseeId && (
            <p className="text-sm text-neutral-400">Select a franchisee from the list tab to view royalty records.</p>
          )}
          {selectedFranchiseeId && (
            <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
              <DataTable columns={royaltyColumns} data={royalties} loading={royaltyLoading} rowKey={(r) => r.id} />
            </div>
          )}
        </div>
      )}

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-md bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">Add Franchisee</Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {(
                [
                  ['name', 'Name'],
                  ['branch_name', 'Branch Name'],
                  ['location', 'Location'],
                  ['contact', 'Contact'],
                ] as const
              ).map(([field, label]) => (
                <div key={field}>
                  <label className="block text-sm font-medium text-neutral-700 mb-1">{label}</label>
                  <input {...register(field)} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                  {errors[field] && <p className="text-xs text-red-500 mt-1">{errors[field]?.message}</p>}
                </div>
              ))}
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => { setOpen(false); reset() }} className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800">Cancel</button>
                <button type="submit" disabled={createFranchisee.isPending} className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50">
                  {createFranchisee.isPending ? 'Adding…' : 'Add'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/lib/api/franchise.ts frontend/src/portals/internal/pages/Franchises.tsx
git commit -m "feat(frontend): add Franchises page — list franchisees and royalty records"
```

---

## Task 15: Platform Admin API hooks + Notifications page

**Files:**
- Create: `frontend/src/lib/api/platform-admin.ts`
- Create: `frontend/src/portals/internal/pages/Notifications.tsx`

- [ ] **Step 1: Create `frontend/src/lib/api/platform-admin.ts`**

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient } from './client'

export interface NotificationTemplate {
  id: string
  key: string
  channel: 'email' | 'in_app' | 'push'
  subject?: string
  body: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export function useNotificationTemplates() {
  return useQuery({
    queryKey: ['notification-templates'],
    queryFn: () =>
      apiClient.get<NotificationTemplate[]>('/notification-templates').then((r) => r.data),
  })
}

export function useCreateNotificationTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (input: {
      key: string
      channel: NotificationTemplate['channel']
      subject?: string
      body: string
    }) =>
      apiClient
        .post<NotificationTemplate>('/notification-templates', input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notification-templates'] }),
  })
}

export function useUpdateNotificationTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({ id, ...input }: { id: string; subject?: string; body: string; is_active?: boolean }) =>
      apiClient
        .put<NotificationTemplate>(`/notification-templates/${id}`, input)
        .then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notification-templates'] }),
  })
}

export function useDeleteNotificationTemplate() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (id: string) =>
      apiClient.delete(`/notification-templates/${id}`).then((r) => r.data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notification-templates'] }),
  })
}
```

- [ ] **Step 2: Create `frontend/src/portals/internal/pages/Notifications.tsx`**

```tsx
import { useState } from 'react'
import { Plus, Bell, Trash2, Edit2 } from 'lucide-react'
import * as Dialog from '@radix-ui/react-dialog'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import {
  useNotificationTemplates,
  useCreateNotificationTemplate,
  useUpdateNotificationTemplate,
  useDeleteNotificationTemplate,
  type NotificationTemplate,
} from '@/lib/api/platform-admin'
import DataTable, { Column } from '@/components/shared/DataTable'
import PageHeader from '@/components/shared/PageHeader'
import { cn } from '@/lib/utils/cn'

const CHANNEL_STYLES: Record<string, string> = {
  email: 'bg-sky-50 text-sky-700',
  in_app: 'bg-brand-50 text-brand-700',
  push: 'bg-violet-50 text-violet-700',
}

const templateSchema = z.object({
  key: z.string().min(2, 'Key required'),
  channel: z.enum(['email', 'in_app', 'push']),
  subject: z.string().optional(),
  body: z.string().min(5, 'Body required'),
})
type TemplateForm = z.infer<typeof templateSchema>

export default function Notifications() {
  const [open, setOpen] = useState(false)
  const [editTarget, setEditTarget] = useState<NotificationTemplate | null>(null)
  const { data = [], isLoading } = useNotificationTemplates()
  const create = useCreateNotificationTemplate()
  const update = useUpdateNotificationTemplate()
  const remove = useDeleteNotificationTemplate()

  const { register, handleSubmit, reset, setValue, formState: { errors } } = useForm<TemplateForm>({
    resolver: zodResolver(templateSchema),
    defaultValues: { channel: 'in_app' },
  })

  const openCreate = () => { setEditTarget(null); reset(); setOpen(true) }
  const openEdit = (t: NotificationTemplate) => {
    setEditTarget(t)
    setValue('key', t.key)
    setValue('channel', t.channel)
    setValue('subject', t.subject ?? '')
    setValue('body', t.body)
    setOpen(true)
  }

  const onSubmit = async (form: TemplateForm) => {
    try {
      if (editTarget) {
        await update.mutateAsync({ id: editTarget.id, subject: form.subject, body: form.body })
        toast.success('Template updated')
      } else {
        await create.mutateAsync(form)
        toast.success('Template created')
      }
      setOpen(false)
      reset()
      setEditTarget(null)
    } catch {
      toast.error('Failed to save template')
    }
  }

  const columns: Column<NotificationTemplate>[] = [
    { header: 'Key', accessor: 'key', cell: (row) => <span className="font-mono text-sm">{row.key}</span> },
    {
      header: 'Channel',
      accessor: 'channel',
      cell: (row) => (
        <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium capitalize', CHANNEL_STYLES[row.channel])}>
          {row.channel.replace(/_/g, ' ')}
        </span>
      ),
    },
    { header: 'Subject', accessor: 'subject', cell: (row) => <span className="text-sm text-neutral-500">{row.subject ?? '—'}</span> },
    {
      header: 'Status',
      accessor: 'is_active',
      cell: (row) => (
        <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium', row.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-neutral-100 text-neutral-500')}>
          {row.is_active ? 'Active' : 'Inactive'}
        </span>
      ),
    },
    {
      header: '',
      accessor: 'id',
      cell: (row) => (
        <div className="flex gap-2">
          <button onClick={() => openEdit(row)} className="text-neutral-400 hover:text-brand-600"><Edit2 className="w-4 h-4" /></button>
          <button
            onClick={() => {
              if (confirm(`Delete template "${row.key}"?`)) {
                remove.mutate(row.id, {
                  onSuccess: () => toast.success('Template deleted'),
                  onError: () => toast.error('Failed to delete'),
                })
              }
            }}
            className="text-neutral-400 hover:text-red-400"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        icon={<Bell className="w-5 h-5 text-brand-600" />}
        title="Notification Templates"
        description={`${data.length} template${data.length !== 1 ? 's' : ''}`}
        action={
          <button
            onClick={openCreate}
            className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 transition-colors"
          >
            <Plus className="w-4 h-4" />
            New Template
          </button>
        }
      />
      <div className="bg-white rounded-xl border border-neutral-100 shadow-[0_1px_3px_rgba(0,0,0,0.06)]">
        <DataTable columns={columns} data={data} loading={isLoading} rowKey={(r) => r.id} />
      </div>

      <Dialog.Root open={open} onOpenChange={setOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 z-40" />
          <Dialog.Content className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-50 w-full max-w-lg bg-white rounded-xl shadow-xl p-6 space-y-4">
            <Dialog.Title className="text-lg font-semibold text-neutral-900">
              {editTarget ? 'Edit Template' : 'New Template'}
            </Dialog.Title>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Key</label>
                <input {...register('key')} disabled={!!editTarget} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500 disabled:bg-neutral-50" />
                {errors.key && <p className="text-xs text-red-500 mt-1">{errors.key.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Channel</label>
                <select {...register('channel')} disabled={!!editTarget} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 disabled:bg-neutral-50">
                  <option value="in_app">In App</option>
                  <option value="email">Email</option>
                  <option value="push">Push</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Subject (email only)</label>
                <input {...register('subject')} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-neutral-700 mb-1">Body</label>
                <textarea {...register('body')} rows={5} className="w-full px-3 py-2 border border-neutral-300 rounded-lg text-sm font-mono focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
                {errors.body && <p className="text-xs text-red-500 mt-1">{errors.body.message}</p>}
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => { setOpen(false); reset(); setEditTarget(null) }} className="px-4 py-2 text-sm text-neutral-600 hover:text-neutral-800">Cancel</button>
                <button type="submit" disabled={create.isPending || update.isPending} className="px-4 py-2 bg-brand-600 text-white rounded-lg text-sm font-medium hover:bg-brand-700 disabled:opacity-50">
                  {(create.isPending || update.isPending) ? 'Saving…' : 'Save'}
                </button>
              </div>
            </form>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  )
}
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/lib/api/platform-admin.ts frontend/src/portals/internal/pages/Notifications.tsx
git commit -m "feat(frontend): add Notifications page — notification template CRUD"
```

---

## Task 16: UX polish — existing pages

**Files:**
- Modify: `frontend/src/portals/internal/pages/Enrollments.tsx`
- Modify: `frontend/src/portals/internal/pages/Payments.tsx`

- [ ] **Step 1: Improve status badge colors in `Enrollments.tsx`**

Open `frontend/src/portals/internal/pages/Enrollments.tsx`. Find the status badge rendering for enrollment statuses. Replace with:

```tsx
// Status badge colors — add/replace in the status cell renderer
const ENROLLMENT_STATUS_STYLES: Record<string, string> = {
  active: 'bg-emerald-50 text-emerald-700',
  completed: 'bg-brand-50 text-brand-700',
  dropped: 'bg-neutral-100 text-neutral-500',
  pending: 'bg-amber-50 text-amber-700',
}
```

Use `cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium', ENROLLMENT_STATUS_STYLES[row.status] ?? 'bg-neutral-100 text-neutral-500')` for any status badge cell.

- [ ] **Step 2: Apply DM Mono font to currency amounts in `Payments.tsx`**

Open `frontend/src/portals/internal/pages/Payments.tsx`. Find any cell that renders currency/amount values. Add `font-mono` class to those cells so they use DM Mono.

Example: if amount is rendered as `<span>{formatCurrency(row.amount)}</span>`, change to `<span className="font-mono">{formatCurrency(row.amount)}</span>`.

- [ ] **Step 3: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/internal/pages/Enrollments.tsx frontend/src/portals/internal/pages/Payments.tsx
git commit -m "polish(frontend): improve enrollment status badge colors, apply font-mono to payment amounts"
```

---

## ═══════════════════════════════════════
## WAVE 3 — WIRING (single agent, after Wave 2 complete)
## ═══════════════════════════════════════

---

## Task 17: Wire new routes in App.tsx

**Files:**
- Modify: `frontend/src/App.tsx`

- [ ] **Step 1: Add all new imports to `frontend/src/App.tsx`**

After the existing internal page imports (after `import Students from ...`), add:

```ts
import Departments from '@/portals/internal/pages/Departments'
import TeamMembers from '@/portals/internal/pages/TeamMembers'
import Proposals from '@/portals/internal/pages/Proposals'
import Budget from '@/portals/internal/pages/Budget'
import ProfitSplit from '@/portals/internal/pages/ProfitSplit'
import Partners from '@/portals/internal/pages/Partners'
import Vouchers from '@/portals/internal/pages/Vouchers'
import InternalCalendar from '@/portals/internal/pages/Calendar'
import Franchises from '@/portals/internal/pages/Franchises'
import Notifications from '@/portals/internal/pages/Notifications'
```

Note: `Calendar` is imported as `InternalCalendar` to avoid conflict with browser's `Calendar` global.

- [ ] **Step 2: Add new routes inside the `/internal` Route group**

In `frontend/src/App.tsx`, find the `/internal` route block:
```tsx
<Route path="/internal" element={<InternalPortal />}>
  <Route index element={<InternalDashboard />} />
  <Route path="enrollments" element={<Enrollments />} />
  <Route path="payments" element={<Payments />} />
  <Route path="courses" element={<Courses />} />
  <Route path="students" element={<Students />} />
</Route>
```

Replace with:
```tsx
<Route path="/internal" element={<InternalPortal />}>
  <Route index element={<InternalDashboard />} />
  <Route path="enrollments" element={<Enrollments />} />
  <Route path="payments" element={<Payments />} />
  <Route path="courses" element={<Courses />} />
  <Route path="students" element={<Students />} />
  <Route path="departments" element={<Departments />} />
  <Route path="team-members" element={<TeamMembers />} />
  <Route path="proposals" element={<Proposals />} />
  <Route path="budget" element={<Budget />} />
  <Route path="profit-split" element={<ProfitSplit />} />
  <Route path="partners" element={<Partners />} />
  <Route path="vouchers" element={<Vouchers />} />
  <Route path="calendar" element={<InternalCalendar />} />
  <Route path="franchises" element={<Franchises />} />
  <Route path="notifications" element={<Notifications />} />
</Route>
```

- [ ] **Step 3: Verify TypeScript**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/App.tsx
git commit -m "feat(frontend): wire 10 new internal routes — departments through notifications"
```

---

## Task 18: Role-aware nav in InternalPortal.tsx

**Files:**
- Modify: `frontend/src/portals/internal/InternalPortal.tsx`

- [ ] **Step 1: Update `frontend/src/portals/internal/InternalPortal.tsx`**

Replace entire file content:

```tsx
import { Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '@/lib/auth/useAuth'
import { useUnreadCount } from '@/lib/api/platform'
import { SubNavProvider, SubNavBar } from '@/components/layout/SubNavContext'
import TopNavBar from '@/components/layout/TopNavBar'
import { getInternalNavItems } from '@/lib/auth/roleNav'

function InternalLayout() {
  const { user, logout } = useAuth()
  const unread = useUnreadCount()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const navItems = getInternalNavItems(user?.role ?? '')

  return (
    <div className="min-h-screen bg-neutral-50">
      <TopNavBar
        mainNav={navItems}
        user={user}
        unreadCount={unread}
        onLogout={handleLogout}
        avatarClass="bg-brand-100 text-brand-700"
      />
      <SubNavBar />
      <main className="px-6 md:px-8 lg:px-12 py-6">
        <Outlet />
      </main>
    </div>
  )
}

export default function InternalPortal() {
  return (
    <SubNavProvider>
      <InternalLayout />
    </SubNavProvider>
  )
}
```

- [ ] **Step 2: Verify TypeScript and build**

```bash
cd frontend && npm run build 2>&1 | grep -E "error|Error" | head -20
```
Expected: no TypeScript errors, build succeeds.

- [ ] **Step 3: Start dev server and smoke test**

```bash
cd frontend && npm run dev &
```

Test each role manually (or with test accounts):
1. Login as `ceo` → should see all 15 nav items
2. Login as `finance` → should see: Dashboard, Enrollments, Payments
3. Login as `dept_leader` → should see: Dashboard, Enrollments, Courses, Departments, Team Members, Proposals, Budget
4. Login as `course_creator` → should see: Dashboard, Enrollments, Courses, Proposals, Budget, Profit Split
5. Login as `facilitator` → should see: Dashboard, Enrollments, Courses, Calendar, Proposals
6. Verify any non-CEO/admin role no longer gets 403

- [ ] **Step 4: Commit**

```bash
git add frontend/src/portals/internal/InternalPortal.tsx
git commit -m "feat(frontend): role-aware nav in InternalPortal — each role sees filtered nav items"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Fix 403 → Task 1
- ✅ roleNav utility → Task 2
- ✅ Departments page (read-only) → Tasks 3, 4
- ✅ TeamMembers page (list + create + deactivate) → Tasks 3, 5
- ✅ Proposals page (create + review) → Tasks 3, 6
- ✅ Budget page (batch items + summary) → Tasks 7, 8
- ✅ ProfitSplit page (settings + overrides + extra revenue) → Tasks 7, 9
- ✅ Partners page (list + create) → Tasks 10, 11
- ✅ Vouchers page (list + create) → Tasks 10, 12
- ✅ Calendar page (list + create + delete) → Tasks 10, 13
- ✅ Franchises page (list + royalty) → Task 14
- ✅ Notifications page (CRUD) → Task 15
- ✅ UX polish → Task 16
- ✅ Route wiring → Task 17
- ✅ Role-aware nav → Task 18

**Type consistency:**
- `NavItem` from `@/components/layout/TopNavBar` — used in Tasks 2 and 18 ✅
- `apiClient` from `@/lib/api/client` — consistent across all API hook files ✅
- `useQuery`/`useMutation`/`useQueryClient` from `@tanstack/react-query` — consistent ✅
- `DataTable`, `PageHeader`, `cn`, `formatDate`, `formatCurrency` — used consistently ✅
- `franchise.ts` extended in Task 14 reuses existing `Franchisee`, `RoyaltyRecord` types ✅
