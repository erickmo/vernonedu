# Finance Invoices Screen — Layout Spec

> Invoice management: auto-generated from enrollment, manual creation, payment tracking.

---

**Route:** `/finance/invoices`
**Title:** Invoice
**Subtitle:** Manajemen Faktur & Pembayaran

---

## Statistics Section

### Number Cards Row

| Card | Value | Color |
|------|-------|-------|
| Total Invoice | count | blue |
| Lunas (Paid) | count + amount | green |
| Belum Lunas (Outstanding) | count + amount | orange |
| Jatuh Tempo (Overdue) | count + amount | red |

---

## Tabs

### Tab 1: Semua Invoice

**Actions:**
- `+ Buat Invoice Manual` button (for non-automated cases)

**Filters:**
- Nomor Invoice (text input)
- Nama Siswa / Client (text input)
- Status (dropdown: Draft / Terkirim / Lunas / Jatuh Tempo / Dibatalkan)
- Batch (dropdown)
- Metode Pembayaran (dropdown)
- Tanggal (date range)

**Table:** Pagination 20 per page

| No Invoice | Siswa / Client | Batch | Jumlah | Metode | Jatuh Tempo | Status | Aksi |
|-----------|---------------|-------|--------|--------|------------|--------|------|
| [INV-xxx] | [name] | [batch code] | [amount] | [method pill] | [date] | [status pill] | 👁 📧 |

**Aksi:**
- 👁 View detail
- 📧 Send/resend invoice

### Tab 2: Jatuh Tempo (Overdue)

Same table filtered to overdue invoices only. Sorted by oldest overdue first.

### Tab 3: Riwayat Pembayaran

**Table:** Recent payment receipts

| Tanggal Bayar | No Invoice | Siswa / Client | Jumlah | Metode Bayar | Bukti |
|--------------|-----------|---------------|--------|-------------|-------|
| [date] | [INV-xxx] | [name] | [amount] | [transfer/cash/etc] | [link or —] |

---

## Invoice Detail (modal or separate page)

| Field | Value |
|-------|-------|
| Nomor Invoice | INV-2026-xxxx |
| Tanggal | [created date] |
| Jatuh Tempo | [due date] |
| Siswa / Client | [name + contact] |
| Course Batch | [batch code + name] |
| Metode Pembayaran | [payment method] |
| Jumlah | [amount] |
| Status | [status] |
| Sumber | [Auto / Manual] |
| Riwayat Pembayaran | [payment history table if partial payments] |

**Actions:**
- `Tandai Lunas` — mark as paid (input payment date + method + proof)
- `Kirim Ulang` — resend invoice
- `Batalkan` — cancel invoice (with reason)
- `Print / Download PDF`

---

## Auto-Generation Rules

Invoices are automatically created by the system:

| Trigger | Invoice Created |
|---------|----------------|
| Student enrolls in batch | Invoice(s) based on batch payment method (see [batch-enrollment.md](batch-enrollment.md)) |
| Payment method: `upfront` | 1 invoice, full amount, due before class start |
| Payment method: `scheduled` | Multiple invoices per installment schedule |
| Payment method: `monthly` | Invoice generated at start of each month |
| Payment method: `batch_lump` | 1 invoice to client company |
| Payment method: `per_session` | Invoice generated after each attended session |

All auto-generated invoices have `Sumber: Auto` tag.

---

**Last Updated:** Maret 2026
