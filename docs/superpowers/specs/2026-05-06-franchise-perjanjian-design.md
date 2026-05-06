# Franchise Perjanjian — Design Spec

**Date:** 2026-05-06  
**Branch:** feat/franchise-perjanjian  
**Scope:** FranchiseeDetailPage action enhancements + FranchiseManagementPage implementation

---

## Background

`FranchiseeDetailPage` already renders 4 read-only sections (Info, Perjanjian, Royalty Payments, Pendapatan Lain) but has no create/edit/delete actions. `FranchiseManagementPage` is an empty placeholder. The backend and service layer are complete — all endpoints and `franchiseeService` methods already exist.

---

## Part 1: FranchiseeDetailPage Enhancements

### 1.1 Agreement Modal (`AgreementFormModal`)

**Trigger:**
- When `agreement === null/undefined`: "Buat Perjanjian" button in Perjanjian section header
- When `agreement` exists: "Edit Perjanjian" button in Perjanjian section header

**Fields:**

| Field | Type | Validation |
|---|---|---|
| `buy_in_fee` | number (currency input) | required, >= 0 |
| `monthly_royalty` | number (currency input) | required, >= 0 |
| `revenue_royalty_pct` | number | required, 0–100 |
| `start_date` | date input | required |
| `end_date` | date input | optional |
| `status` | select: `active` / `terminated` | required |

**Submit logic:**
- No agreement → `franchiseeService.createAgreement(id, payload)`
- Agreement exists → `franchiseeService.updateAgreement(id, agreement.id, payload)`
- On success: `invalidateQueries(['franchisee-agreement', id])` + `toast.success`
- On error: `toast.error`

---

### 1.2 Royalty Payment Modal (`RoyaltyPaymentFormModal`)

**Trigger:** "Tambah Pembayaran" button in Royalty section header (create only — no edit)

**Fields:**

| Field | Type | Validation |
|---|---|---|
| `period` | text input (YYYY-MM format) | required, pattern: `/^\d{4}-\d{2}$/` |
| `gross_revenue` | number (currency input) | required, >= 0 |

Note: total royalty computed by backend using agreement rates.

**Per-row action:** "Tandai Lunas" button — shown only when `status !== 'paid'`
- Calls `franchiseeService.markRoyaltyPaid(id, payment.id)`
- On success: `invalidateQueries(['franchisee-royalty', id])` + `toast.success`

**Submit logic:**
- `franchiseeService.createRoyaltyPayment(id, payload)`
- On success: `invalidateQueries(['franchisee-royalty', id])` + `toast.success`

---

### 1.3 Other Revenue Modal (`OtherRevenueFormModal`)

**Trigger:**
- "Tambah Pendapatan" button in Pendapatan Lain section header → create mode
- Edit icon per row → edit mode (pre-fills form with row data)

**Fields:**

| Field | Type | Validation |
|---|---|---|
| `label` | text input | required |
| `amount` | number (currency input) | required, >= 0 |
| `revenue_date` | date input | required |

**Per-row delete:** trash icon → browser `confirm()` dialog → `franchiseeService.deleteOtherRevenue(id, revenue.id)`

**Submit logic:**
- Create mode: `franchiseeService.createOtherRevenue(id, payload)`
- Edit mode: `franchiseeService.updateOtherRevenue(id, revenue.id, payload)`
- On success: `invalidateQueries(['franchisee-other-revenue', id])` + `toast.success`

---

### 1.4 State Pattern

All modals are co-located in `FranchiseeDetailPage.tsx`:

```tsx
const [agreementModalOpen, setAgreementModalOpen] = useState(false)
const [royaltyModalOpen, setRoyaltyModalOpen]     = useState(false)
const [otherRevenueModalOpen, setOtherRevenueModalOpen] = useState(false)
const [editingRevenue, setEditingRevenue] = useState<OtherRevenue | null>(null)
// null = create mode, non-null = edit mode
```

Mutations via `useMutation` (TanStack Query), `onSuccess` handler invalidates relevant query keys.

Modal implementation: plain `<dialog>` or inline overlay div — consistent with existing project modal pattern.

---

## Part 2: FranchiseManagementPage

### 2.1 Data Fetch

Single call: `franchiseeService.list({ limit: 1000 })` — sufficient for summary computation and table display. No N+1 per-franchisee agreement calls.

Note: Agreement status per franchisee row is **not shown** — requires backend list endpoint to include `agreement_status` field, which is not currently supported. Deferred to a future iteration.

---

### 2.2 Summary Cards

Three stat cards at top, computed client-side from list results:

| Card | Value |
|---|---|
| Total Franchisee | `data.total` (or `items.length`) |
| Aktif | `items.filter(f => f.status === 'active').length` |
| Nonaktif / Diakhiri | `items.filter(f => f.status !== 'active').length` |

---

### 2.3 Franchisee Table

**Columns:** Nama, Nama Cabang, Lokasi, Kontak, Status (badge), Aksi

**Aksi column:** "Lihat Detail" button → `navigate('/pengembangan/franchisees/:id')`

**Filter bar:**
- Search input (nama / cabang) — filters client-side or via `?search=` param
- Status filter select: All / Aktif / Nonaktif / Diakhiri

**Component reuse:** Use same `StatusBadge` component already defined in `FranchiseeDetailPage`. Move it to a shared location or duplicate minimally.

---

## Files Changed

| File | Change |
|---|---|
| `web-dashboard/src/pages/Franchisee/FranchiseeDetailPage.tsx` | Add 3 modals + action buttons |
| `web-dashboard/src/pages/BusinessDev/FranchiseManagementPage.tsx` | Full implementation |

No backend changes required. No new service methods required. No new route changes required.

---

## Out of Scope

- Agreement status column in management page table (requires backend list endpoint change)
- Royalty payment edit (backend has no edit endpoint for royalty payments)
- Bulk operations

---

**Last Updated:** 2026-05-06
