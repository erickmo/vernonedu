# Finance Agent E — Audit Invoice + Payable Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit 6 existing Finance pages (Invoice + Payable) against the API spec. Fix endpoint mismatches, missing operations, or broken UX patterns.

**Architecture:** Read each file → compare endpoints vs API docs → fix issues → type check → commit.

**Tech Stack:** React 18, TypeScript, `invoiceService` (`@/services/invoice.service`), `payableService` (`@/services/payable.service`)

---

## Before You Start

Read `.wolf/cerebrum.md` (Do-Not-Repeat section). Key constraints:
- VITE_API_BASE_URL already includes `/api/v1`. Paths must NOT include `/api/v1`.
- All paths start with `/finance/...`.

**API reference for this domain:**
```
# Invoices
GET    /finance/invoices               ?status, batch_id, student_id
GET    /finance/invoices/{id}
POST   /finance/invoices               (manual)
PUT    /finance/invoices/{id}/pay
PUT    /finance/invoices/{id}/send
PUT    /finance/invoices/{id}/cancel

# Payables
GET    /finance/payables               ?type, status, batch_id
GET    /finance/payables/{id}
POST   /finance/payables
PUT    /finance/payables/{id}
PUT    /finance/payables/{id}/pay
PUT    /finance/payables/{id}/approve
PUT    /finance/payables/{id}/cancel
```

**invoiceService methods (already correct):**
- `list(params?)` → `GET /finance/invoices`
- `getDetail(id)` → `GET /finance/invoices/{id}`
- `createManual(data)` → `POST /finance/invoices`
- `markAsPaid(id)` → `PUT /finance/invoices/{id}/pay`
- `send(id)` → `PUT /finance/invoices/{id}/send`
- `cancel(id, reason)` → `PUT /finance/invoices/{id}/cancel`

**payableService methods (already correct):**
- `list(params?)` → `GET /finance/payables`
- `getById(id)` → `GET /finance/payables/{id}`
- `create(data)` → `POST /finance/payables`
- `update(id, data)` → `PUT /finance/payables/{id}`
- `markAsPaid(id)` → `PUT /finance/payables/{id}/pay`
- `approve(id)` → `PUT /finance/payables/{id}/approve`
- `cancel(id)` → `PUT /finance/payables/{id}/cancel`

---

## Task 1: Audit InvoiceListPage

**Files:**
- Read + possibly modify: `src/pages/Finance/InvoiceListPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/InvoiceListPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Uses `invoiceService.list(params)` (not a hardcoded URL)
2. Query key: `'finance/invoices'`
3. Create button → navigates to `/dashboard/finance/invoices/new`
4. View action → navigates to `/dashboard/finance/invoices/:id`
5. Row actions: Mark as Paid (calls `invoiceService.markAsPaid`), Send (calls `invoiceService.send`), Cancel (calls `invoiceService.cancel`)
6. Status badge shows correct colors (draft/sent/paid/overdue/cancelled)
7. Columns: invoice number, student name, amount, status, due date
8. Filters: status filter present

- [ ] **Step 3: Fix any issues found**

Apply fixes. Example fix if Cancel is missing reason parameter:
```tsx
// Wrong:
onClick: async (row) => { await invoiceService.cancel(row.id) }
// Correct:
onClick: async (row) => {
  const reason = prompt('Alasan pembatalan:')
  if (reason === null) return
  await invoiceService.cancel(row.id, reason)
}
```

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/InvoiceListPage.tsx
git commit -m "fix(finance): audit and fix InvoiceListPage"
```

---

## Task 2: Audit ManualInvoiceFormPage

**Files:**
- Read + possibly modify: `src/pages/Finance/ManualInvoiceFormPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/ManualInvoiceFormPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. On submit: calls `invoiceService.createManual(data)`
2. On success: navigates to `/dashboard/finance/invoices` or to new invoice detail
3. Required fields present: student_id (or student name), amount, due_date, description
4. Loading state during submit

- [ ] **Step 3: Fix any issues found**

Apply fixes.

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/ManualInvoiceFormPage.tsx
git commit -m "fix(finance): audit and fix ManualInvoiceFormPage"
```

---

## Task 3: Audit InvoiceDetailPage

**Files:**
- Read + possibly modify: `src/pages/Finance/InvoiceDetailPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/InvoiceDetailPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Extracts `:invoiceId` via `useParams()` (check routes.tsx: path is `finance/invoices/:invoiceId`)
2. Loads detail via `invoiceService.getDetail(invoiceId)`
3. Shows invoice fields: invoice number, student, amount, status, due date, items
4. Action buttons present based on status:
   - Draft → Send + Cancel buttons
   - Sent → Mark as Paid + Cancel buttons
   - Paid/Cancelled → no action buttons
5. Each action calls the correct service method
6. After action: invalidates query and shows toast

- [ ] **Step 3: Fix missing actions or wrong param**

Common fix — wrong param name (must match routes.tsx `:invoiceId`):
```tsx
// Check routes.tsx: path is 'finance/invoices/:invoiceId'
const { invoiceId } = useParams<{ invoiceId: string }>()
```

Common fix — missing conditional actions:
```tsx
{invoice?.status === 'draft' && (
  <button onClick={() => handleSend()}>Kirim Invoice</button>
)}
{(invoice?.status === 'draft' || invoice?.status === 'sent') && (
  <button onClick={() => handleCancel()}>Batalkan</button>
)}
{invoice?.status === 'sent' && (
  <button onClick={() => handleMarkPaid()}>Tandai Lunas</button>
)}
```

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/InvoiceDetailPage.tsx
git commit -m "fix(finance): audit and fix InvoiceDetailPage"
```

---

## Task 4: Audit PayableListPage

**Files:**
- Read + possibly modify: `src/pages/Finance/PayableListPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/PayableListPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Uses `payableService.list(params)`
2. Query key: `'finance/payables'`
3. Create button → navigates to `/dashboard/finance/payables/new`
4. View action → navigates to `/dashboard/finance/payables/:id`
5. Row actions: Approve (calls `payableService.approve`), Pay (calls `payableService.markAsPaid`), Cancel (calls `payableService.cancel`)
6. Columns: payable type, recipient, amount, status, due date

- [ ] **Step 3: Fix any issues found**

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/PayableListPage.tsx
git commit -m "fix(finance): audit and fix PayableListPage"
```

---

## Task 5: Audit PayableFormPage

**Files:**
- Read + possibly modify: `src/pages/Finance/PayableFormPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/PayableFormPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Detects edit mode via `useParams()` — extracts `:payableId`
2. In edit mode: loads data via `payableService.getById(payableId)`
3. On submit (create): calls `payableService.create(data)`
4. On submit (edit): calls `payableService.update(payableId, data)`
5. On success: navigates to `/dashboard/finance/payables`
6. Required fields: type, recipient/payee, amount, due_date, description
7. Loading state during submit

- [ ] **Step 3: Fix any issues**

Check routes.tsx: payable form path is `finance/payables/new` and `finance/payables/:payableId` (detail page, not edit). If there's no edit route for payables, the form is create-only. If that's intentional, remove edit-mode code.

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/PayableFormPage.tsx
git commit -m "fix(finance): audit and fix PayableFormPage"
```

---

## Task 6: Audit PayableDetailPage

**Files:**
- Read + possibly modify: `src/pages/Finance/PayableDetailPage.tsx`

- [ ] **Step 1: Read the file**

Read `web-dashboard/src/pages/Finance/PayableDetailPage.tsx`.

- [ ] **Step 2: Audit checklist**

Verify:
1. Extracts `:payableId` via `useParams()` — check routes.tsx: path is `finance/payables/:payableId`
2. Loads data via `payableService.getById(payableId)`
3. Shows payable fields: type, recipient, amount, status, due date, description
4. Action buttons based on status:
   - pending → Approve + Cancel buttons
   - approved → Pay + Cancel buttons
   - paid/cancelled → no action buttons
5. Each action calls correct service method
6. After action: invalidates `['finance/payables', payableId]` query

- [ ] **Step 3: Fix issues**

Common fix — wrong param name (must match routes.tsx `:payableId`):
```tsx
const { payableId } = useParams<{ payableId: string }>()
```

- [ ] **Step 4: Commit if changed**

```bash
git add web-dashboard/src/pages/Finance/PayableDetailPage.tsx
git commit -m "fix(finance): audit and fix PayableDetailPage"
```

---

## Task 7: Final check

- [ ] **Step 1: Full type check**

```bash
cd web-dashboard && npx tsc --noEmit 2>&1 | head -20
```
Expected: 0 errors in Invoice* and Payable* files.

- [ ] **Step 2: Write summary**

After completing, summarize:
- InvoiceListPage: [what was fixed or "no issues"]
- ManualInvoiceFormPage: [what was fixed or "no issues"]
- InvoiceDetailPage: [what was fixed or "no issues"]
- PayableListPage: [what was fixed or "no issues"]
- PayableFormPage: [what was fixed or "no issues"]
- PayableDetailPage: [what was fixed or "no issues"]
