# Business Development Screen — Layout Spec

> Main Business Development screen with all sections.

---

**Route:** `/business-development`
**Title:** Business Development

---

## Section 1: Partners

### Number Cards Row

| Card | Value |
|------|-------|
| Partner Aktif | count (grouped by Group Partner) |
| Partner Akan Expired | count |
| Partner Dalam Negosiasi | count |
| Partner Belum Diapproach | count |

### Card: List of Partner

**Actions:**
- `+ Partner` button → add new partner
- `+ Group Partner` button → add new partner group

**Filters:**
- Nama (text input)
- Status (dropdown)

**Table:** Pagination 15 per page

| Nama | Group | Status | MoU Expired At |
|------|-------|--------|---------------|
| [name] | [group name] | [status pill] | [date or —] |

**On row click:** Navigate to → Partner Detail Screen (`/business-development/partners/:partnerId`)

---

## Section 2: Branch

### Number Cards Row

| Card | Value |
|------|-------|
| Cabang Aktif | count |

### Card: List of Branch

**Action:** `+ Branch` button → add new branch

**Filters:**
- Nama (text input)
- Kota (text input)

**Table:** Pagination 10 per page

| Nama | Kota | Partner | Settings |
|------|------|---------|----------|
| [branch name] | [city] | [partner name or —] | [settings icon → branch settings] |

---

## Section 3: OKR & KPI

### Number Cards Row

| Card | Value |
|------|-------|
| Total Objectives | count |
| On Track | count (green) |
| At Risk | count (yellow) |
| Behind | count (red) |

### Card: OKR Overview

**Tabs:** Company | Department | Team

Per tab:

**Table/List:** Expandable rows

```
┌──────────────────────────────────────────────────────────┐
│ ▶ [Objective Title]                    [Progress Bar 75%]│
│   Owner: [name]  Period: [Q1 2026]     Status: On Track  │
│                                                          │
│   Key Results:                                           │
│   ├── [KR 1 title]          [60%] ████████░░             │
│   ├── [KR 2 title]          [90%] █████████░             │
│   └── [KR 3 title]          [70%] ███████░░░             │
└──────────────────────────────────────────────────────────┘
```

**Actions:**
- `+ Objective` button (if permitted)
- Click objective → expand to show key results
- Click KR → edit progress

---

## Section 4: Investment Plan

### Number Cards Row

| Card | Value |
|------|-------|
| Total Investasi Direncanakan | total amount |
| Investasi Berjalan | count + amount |
| Investasi Selesai | count + amount |
| ROI Rata-rata | percentage |

### Card: Investment List

**Action:** `+ Investment Plan` button (if permitted — leaders can propose, Director approves)

**Filters:**
- Status (dropdown: Draft / Proposed / Approved / In Progress / Completed / Cancelled)
- Category (dropdown)

**Table:** Pagination 10 per page

| Judul | Kategori | Diajukan Oleh | Jumlah | Expected ROI | Status | Realisasi |
|-------|----------|--------------|--------|-------------|--------|-----------|
| [title] | [category] | [name] | [amount] | [%] | [status pill] | [actual spend] |

---

## Section 5: Financial Projections

### Filter Bar

- Period: dropdown (1 bulan / 3 bulan / 6 bulan / 12 bulan)
- Branch: dropdown (Semua Cabang / specific branch) — Director sees all, others see own branch

### Cards Row: Key Projection Numbers

| Card | Value |
|------|-------|
| Proyeksi Pendapatan | amount |
| Proyeksi Pengeluaran | amount |
| Proyeksi Laba/Rugi | amount (green if profit, red if loss) |
| Proyeksi Kas Bulanan | amount |

### Charts (2-column layout)

| Column 1 (1/2) | Column 2 (1/2) |
|-----------------|-----------------|
| **Bar Chart:** Proyeksi Pendapatan vs Pengeluaran (monthly) | **Line Chart:** Proyeksi Arus Kas (monthly trend) |

### Card: Revenue Breakdown

**Table:**

| Sumber | Bulan Ini | Bulan Depan | 3 Bulan | 6 Bulan |
|--------|----------|------------|---------|---------|
| Batch Aktif | [amount] | [amount] | [amount] | [amount] |
| Batch Mendatang | [amount] | [amount] | [amount] | [amount] |
| Pipeline (Leads) | [amount] | [amount] | [amount] | [amount] |
| **Total** | **[amount]** | **[amount]** | **[amount]** | **[amount]** |

### Card: Cost Breakdown

**Table:**

| Komponen | Bulan Ini | Bulan Depan | 3 Bulan | 6 Bulan |
|----------|----------|------------|---------|---------|
| Gaji Fasilitator | [amount] | [amount] | [amount] | [amount] |
| Komisi | [amount] | [amount] | [amount] | [amount] |
| Operasional | [amount] | [amount] | [amount] | [amount] |
| Investasi | [amount] | [amount] | [amount] | [amount] |
| **Total** | **[amount]** | **[amount]** | **[amount]** | **[amount]** |

---

## Section 6: Delegation

### Number Cards Row

| Card | Value |
|------|-------|
| Total Delegasi Aktif | count |
| Menunggu Respon | count |
| Dalam Pengerjaan | count |
| Selesai (bulan ini) | count |

### Card: Delegation List

**Action:** `+ Delegasi Baru` button

**Filters:**
- Type (dropdown: Request Course / Request Project / Delegate Task)
- Status (dropdown: Pending / Accepted / In Progress / Completed / Cancelled)
- Assigned To (dropdown/search)

**Table:** Pagination 15 per page

| Judul | Tipe | Didelegasikan Ke | Prioritas | Deadline | Status |
|-------|------|-----------------|-----------|----------|--------|
| [title] | [type pill] | [name + role] | [priority pill] | [date or —] | [status pill] |

**On row click:** Expand or open detail modal showing:
- Full description
- Linked entity (course/project if any)
- Status timeline
- Comments/updates

---

**Last Updated:** Maret 2026
