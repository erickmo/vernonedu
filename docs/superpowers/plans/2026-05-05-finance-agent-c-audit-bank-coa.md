# Finance Agent C — Audit BankAccounts + COA Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit 4 existing Finance pages (BankAccountsPage, BankAccountFormPage, ChartOfAccountsPage, CoaFormPage) against the API spec. Fix any endpoint mismatches, missing operations, or broken UX patterns.

**Architecture:** Read each file → compare endpoints vs API docs → fix issues → type check → commit.

**Tech Stack:** React 18, TypeScript, `accountingService` (`@/services/accounting.service`)

---

## Before You Start

Read `.wolf/cerebrum.md` (Do-Not-Repeat section). Key constraints:
- VITE_API_BASE_URL already includes `/api/v1`. Paths must NOT include `/api/v1`.
- All paths start with `/finance/...`.
- `accountingService` is at `@/services/accounting.service`.

**API reference for this domain:**
```
GET    /finance/bank-accounts
GET    /finance/bank-accounts/{id}
POST   /finance/bank-accounts
PUT    /finance/bank-accounts/{id}
DELETE /finance/bank-accounts/{id}

GET    /finance/coa              → returns tree
GET    /finance/coa/{id}
POST   /finance/coa
PUT    /finance/coa/{id}
```

**accountingService methods (already correct — DO NOT change service unless clearly broken):**
- `listBankAccounts(params?)` → `GET /finance/bank-accounts`
- `getBankAccount(id)` → `GET /finance/bank-accounts/{id}`
- `createBankAccount(data)` → `POST /finance/bank-accounts`
- `updateBankAccount(id, data)` → `PUT /finance/bank-accounts/{id}`
- `deleteBankAccount(id)` → `DELETE /finance/bank-accounts/{id}`
- `listCoa()` → `GET /finance/coa`
- `getCoaTree()` → `GET /finance/coa`

---

## Task 1: Audit BankAccountsPage

**Files:**
- Read + possibly modify: `src/pages/Finance/BankAccountsPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/BankAccountsPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify all of the following. Note any issues:
1. Uses `accountingService.listBankAccounts()` (not a hardcoded URL)
2. Has Create button → navigates to `/dashboard/finance/bank-accounts/new`
3. Has Edit action → navigates to `/dashboard/finance/bank-accounts/:id/edit`
4. Has Delete action → calls `accountingService.deleteBankAccount(id)`
5. Loading state shown while fetching
6. Error state shown on failure
7. Empty state shown when no data

- [ ] **Step 3: Fix any issues found**

Apply fixes based on audit. If no issues found, skip this step.

Common fixes pattern if fetcher is wrong:
```tsx
// Wrong:
fetcher={(params) => apiClient.get('/bank-accounts')}
// Correct:
fetcher={(params) => accountingService.listBankAccounts(params)}
```

Common fix if delete is missing:
```tsx
// Add to rowActions:
{
  label: 'Hapus',
  icon: <Trash2 size={14} />,
  variant: 'danger',
  onClick: async (row) => {
    if (!confirm(`Hapus rekening "${row.name}"?`)) return
    await accountingService.deleteBankAccount(row.id)
    queryClient.invalidateQueries({ queryKey: ['finance/bank-accounts'] })
    toast.success('Rekening dihapus')
  },
}
```

- [ ] **Step 4: Commit (only if changes made)**

```bash
git add web-dashboard/src/pages/Finance/BankAccountsPage.tsx
git commit -m "fix(finance): audit and fix BankAccountsPage"
```

---

## Task 2: Audit BankAccountFormPage

**Files:**
- Read + possibly modify: `src/pages/Finance/BankAccountFormPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/BankAccountFormPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Detects edit mode via `useParams()` — extracts `:accountId`
2. In edit mode: loads existing data via `accountingService.getBankAccount(accountId)`
3. On submit (create): calls `accountingService.createBankAccount(data)`
4. On submit (edit): calls `accountingService.updateBankAccount(accountId, data)`
5. On success: navigates back to `/dashboard/finance/bank-accounts`
6. Required fields present: at minimum `name`, `account_number`, `bank_name`
7. Loading state during submit

- [ ] **Step 3: Fix any issues found**

Apply fixes. Common issue — wrong param name in useParams:
```tsx
// Check routes.tsx: path is 'finance/bank-accounts/:accountId/edit'
// So param must be:
const { accountId } = useParams<{ accountId: string }>()
```

- [ ] **Step 4: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep "BankAccount" | head -10
```

- [ ] **Step 5: Commit (only if changes made)**

```bash
git add web-dashboard/src/pages/Finance/BankAccountFormPage.tsx
git commit -m "fix(finance): audit and fix BankAccountFormPage"
```

---

## Task 3: Audit ChartOfAccountsPage

**Files:**
- Read + possibly modify: `src/pages/Finance/ChartOfAccountsPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/ChartOfAccountsPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Uses `accountingService.listCoa()` or `accountingService.getCoaTree()` to fetch data
2. The COA API returns a TREE (nested structure), not a flat list. Verify the page handles nested data.
3. Has Create button → navigates to `/dashboard/finance/chart-of-accounts/new`
4. Has Edit action → navigates to `/dashboard/finance/chart-of-accounts/:coaId/edit`
5. COA tree display: parent accounts with child accounts indented or collapsible

- [ ] **Step 3: Fix COA tree rendering if broken**

If the page incorrectly treats COA data as a flat list, fix it to handle the tree structure. The API returns nested objects. A safe approach that handles both flat and tree:

```tsx
// Flatten tree for table display
function flattenCoa(nodes: any[], depth = 0): Array<any & { depth: number }> {
  return nodes.flatMap(n => [
    { ...n, depth },
    ...flattenCoa(n.children ?? [], depth + 1),
  ])
}
```

Then in the column render:
```tsx
render: (_v, row) => (
  <span style={{ paddingLeft: row.depth * 20, fontWeight: row.depth === 0 ? 600 : 400 }}>
    {row.name}
  </span>
)
```

- [ ] **Step 4: Commit (only if changes made)**

```bash
git add web-dashboard/src/pages/Finance/ChartOfAccountsPage.tsx
git commit -m "fix(finance): audit and fix ChartOfAccountsPage"
```

---

## Task 4: Audit CoaFormPage

**Files:**
- Read + possibly modify: `src/pages/Finance/CoaFormPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/CoaFormPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Detects edit mode via `useParams()` — extracts `:coaId`
2. In edit mode: loads existing data via `accountingService.getCoa(coaId)` or appropriate method
3. On submit (create): calls `accountingService.createCoa(data)` or `apiClient.post('/finance/coa', data)`
4. On submit (edit): calls `accountingService.updateCoa(coaId, data)` or `apiClient.put('/finance/coa/:id', data)`
5. On success: navigates back to `/dashboard/finance/chart-of-accounts`
6. Has `parent_id` field (for nested COA) — shows COA select
7. Has `type` field (asset/liability/equity/revenue/expense)
8. Has `code` field

- [ ] **Step 3: Fix missing service methods if needed**

If `accountingService` is missing `getCoa(id)`, `createCoa(data)`, or `updateCoa(id, data)`, add them to `src/services/accounting.service.ts`:

```ts
// Add inside accountingService object:
getCoa: (id: string) =>
  apiClient.get<any>(`/finance/coa/${id}`).then(r => (r as any).data ?? r),

createCoa: (data: any) =>
  apiClient.post<any>('/finance/coa', data),

updateCoa: (id: string, data: any) =>
  apiClient.put<any>(`/finance/coa/${id}`, data),
```

- [ ] **Step 4: Type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | grep -i "coa\|CoaForm\|ChartOf" | head -10
```

- [ ] **Step 5: Commit (only if changes made)**

```bash
git add web-dashboard/src/pages/Finance/CoaFormPage.tsx web-dashboard/src/services/accounting.service.ts
git commit -m "fix(finance): audit and fix CoaFormPage and accounting service"
```

---

## Task 5: Final check

- [ ] **Step 1: Full type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -20
```
Expected: 0 errors in BankAccount* and Coa* files.

- [ ] **Step 2: Write summary**

After completing all tasks, summarize what was found and fixed:
- BankAccountsPage: [what was fixed or "no issues found"]
- BankAccountFormPage: [what was fixed or "no issues found"]
- ChartOfAccountsPage: [what was fixed or "no issues found"]
- CoaFormPage: [what was fixed or "no issues found"]
