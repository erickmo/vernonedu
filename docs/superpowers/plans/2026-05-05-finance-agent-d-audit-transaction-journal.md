# Finance Agent D — Audit Transaction + Journal Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit TransactionListPage, TransactionFormPage, JournalPage, and `accountingService` against the API spec. Fix endpoint mismatches — especially JournalPage which likely uses wrong endpoint.

**Architecture:** Read each file → compare endpoints vs API docs → fix issues → type check → commit.

**Tech Stack:** React 18, TypeScript, `accountingService` (`@/services/accounting.service`)

---

## Before You Start

Read `.wolf/cerebrum.md` (Do-Not-Repeat section). Key constraints:
- VITE_API_BASE_URL already includes `/api/v1`. Paths must NOT include `/api/v1`.
- All paths start with `/finance/...`.

**API reference for this domain:**
```
GET    /finance/transactions    ?type, account, branch_id, source
POST   /finance/transactions
PUT    /finance/transactions/{id}
DELETE /finance/transactions/{id}

GET    /finance/journal         ?account, source, date_range
```

**KNOWN POTENTIAL BUG:** `JournalPage` likely fetches from `accountingService.listTransactions()` which hits `/finance/transactions`. But journal data should come from `GET /finance/journal`. Verify and fix this.

---

## Task 1: Add getJournal to accountingService

**Files:**
- Read + modify: `src/services/accounting.service.ts`

- [ ] **Step 1: Read the current service**

Read `web-dashboard/src/services/accounting.service.ts`.

- [ ] **Step 2: Check if getJournal exists**

Look for a method hitting `/finance/journal`. If it exists and is correct, skip to Task 2.

If it does NOT exist, add it inside the `accountingService` object (after `listTransactions`):

```ts
getJournal: (params?: { account?: string; source?: string; date_range?: string } & ListParams) => {
  const qs = buildQS(params)
  return apiClient.get<any>(`/finance/journal${qs}`).then(r => (r as any).data ?? r)
},
```

- [ ] **Step 3: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "accounting.service" | head -5
```

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/services/accounting.service.ts
git commit -m "fix(finance): add getJournal method to accountingService"
```

---

## Task 2: Audit JournalPage

**Files:**
- Read + modify: `src/pages/Finance/JournalPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/JournalPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. **Fetcher endpoint**: Should call `accountingService.getJournal()` → hits `/finance/journal`. If it calls `accountingService.listTransactions()` instead, that's the bug — fix it.
2. Query key should be `'finance/journal'` (not `'finance/transactions'`)
3. Loading state shown
4. Error state shown
5. Empty state shown

- [ ] **Step 3: Fix fetcher if wrong**

If `fetcher` calls `listTransactions` instead of `getJournal`:
```tsx
// Wrong:
fetcher={(params) => accountingService.listTransactions(params)}
// Correct:
fetcher={(params) => accountingService.getJournal(params)}
```

Also fix the `queryKey` if it says `'finance/transactions'`:
```tsx
// Wrong:
queryKey="finance/transactions"
// Correct:
queryKey="finance/journal"
```

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/JournalPage.tsx
git commit -m "fix(finance): JournalPage use correct /finance/journal endpoint"
```

---

## Task 3: Audit TransactionListPage

**Files:**
- Read + possibly modify: `src/pages/Finance/TransactionListPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/TransactionListPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Uses `accountingService.listTransactions(params)` → hits `/finance/transactions`
2. Query key: `'finance/transactions'`
3. Create button → navigates to `/dashboard/finance/transactions/new`
4. Edit action → navigates to `/dashboard/finance/transactions/:txId/edit`
5. Delete action → calls `accountingService.deleteTransaction(row.id)` with confirmation
6. Columns include: date, description/reference, account, debit/credit/amount, type
7. Filter by type (debit/credit) present or acceptable to be missing
8. Loading/error/empty states present

- [ ] **Step 3: Fix missing delete action if absent**

If delete action is missing:
```tsx
// Import at top if not present:
import { useQueryClient } from '@tanstack/react-query'
import { toast } from '@/widgets/Toast/Toast'

// Inside component:
const queryClient = useQueryClient()

// In rowActions array:
{
  label: 'Hapus',
  icon: <Trash2 size={14} />,
  variant: 'danger' as const,
  onClick: async (row: Transaction) => {
    if (!confirm(`Hapus transaksi ini?`)) return
    try {
      await accountingService.deleteTransaction(row.id)
      queryClient.invalidateQueries({ queryKey: ['finance/transactions'] })
      toast.success('Transaksi dihapus')
    } catch {
      toast.error('Gagal menghapus transaksi')
    }
  },
}
```

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/TransactionListPage.tsx
git commit -m "fix(finance): audit and fix TransactionListPage"
```

---

## Task 4: Audit TransactionFormPage

**Files:**
- Read + possibly modify: `src/pages/Finance/TransactionFormPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/TransactionFormPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Detects edit mode via `useParams()` — extracts `:txId`
2. In edit mode: loads data via `accountingService.getTransaction(txId)` or equivalent
3. On submit (create): calls `accountingService.createTransaction(data)`
4. On submit (edit): calls `accountingService.updateTransaction(txId, data)`
5. On success: navigates back to `/dashboard/finance/transactions`
6. Required fields: `date`, `account_id`, `type` (debit/credit), `amount`, `description`
7. Account field: dropdown populated from `accountingService.listCoa()`
8. Loading state during submit + fetch

- [ ] **Step 3: Fix missing getTransaction if needed**

If `accountingService` doesn't have `getTransaction(id)`, add it to `src/services/accounting.service.ts`:

```ts
getTransaction: (id: string) =>
  apiClient.get<any>(`/finance/transactions/${id}`).then(r => (r as any).data ?? r),
```

- [ ] **Step 4: Fix TransactionFormPage issues if found**

Apply fixes based on audit.

- [ ] **Step 5: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "TransactionForm\|TransactionList" | head -10
```

- [ ] **Step 6: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/TransactionFormPage.tsx web-dashboard/src/services/accounting.service.ts
git commit -m "fix(finance): audit and fix TransactionFormPage"
```

---

## Task 5: Final check

- [ ] **Step 1: Full type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -20
```
Expected: 0 errors in Transaction* and Journal* files.

- [ ] **Step 2: Write summary**

After completing, summarize:
- accountingService: [what was added/fixed or "no issues"]
- JournalPage: [was endpoint wrong? what was fixed]
- TransactionListPage: [what was fixed or "no issues"]
- TransactionFormPage: [what was fixed or "no issues"]
