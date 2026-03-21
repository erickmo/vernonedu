# Finance Payables Screen — Layout Spec

> Account payable management: auto-generated for facilitators, commissions, and marketing partners.

---

**Route:** `/finance/payables`
**Title:** Hutang (Account Payable)
**Subtitle:** Manajemen Kewajiban Pembayaran

---

## Statistics Section

### Number Cards Row

| Card | Value | Color |
|------|-------|-------|
| Total Hutang | amount | red |
| Hutang Fasilitator | amount | orange |
| Hutang Komisi | amount | orange |
| Hutang Marketing Partner | amount | orange |
| Jatuh Tempo Minggu Ini | count + amount | red if > 0 |

---

## Tabs

### Tab 1: Semua Hutang

**Filters:**
- Tipe (dropdown: Fasilitator / Komisi Op Leader / Komisi Dept Leader / Komisi Course Creator / Marketing Partner / Lainnya)
- Status (dropdown: Pending / Disetujui / Dibayar / Dibatalkan)
- Nama Penerima (text input)
- Batch (dropdown)
- Tanggal (date range)

**Table:** Pagination 20 per page

| Tanggal | Tipe | Penerima | Batch | Jumlah | Status | Aksi |
|---------|------|----------|-------|--------|--------|------|
| [date] | [type pill] | [name] | [batch code] | [amount] | [status pill] | 👁 ✅ |

**Aksi:**
- 👁 View detail
- ✅ Mark as paid (input payment proof)

### Tab 2: Fasilitator

Filtered to facilitator payables only.

**Summary card:** Total sesi bulan ini, Total hutang fasilitator bulan ini

**Table:**

| Fasilitator | Level | Jumlah Sesi | Fee per Sesi | Total | Status |
|------------|-------|-------------|-------------|-------|--------|
| [name] | Level [n] | [count] | [amount] | [total] | [status] |

### Tab 3: Komisi

Filtered to commission payables (Op Leader, Dept Leader, Course Creator).

**Table:**

| Penerima | Role | Batch | Basis (Profit/Revenue) | % | Jumlah | Status |
|----------|------|-------|----------------------|---|--------|--------|
| [name] | [role pill] | [batch code] | [basis] | [%] | [amount] | [status] |

### Tab 4: Marketing Partner

Filtered to marketing partner / referral commissions.

**Table:**

| Partner | Kode Referral | Siswa | Batch | Komisi | Status |
|---------|--------------|-------|-------|--------|--------|
| [partner name] | [code] | [student name] | [batch code] | [amount] | [status] |

---

## Auto-Generation Rules

Account payables are automatically created by the system:

| Trigger | Payable Created | Calculation |
|---------|----------------|-------------|
| Facilitator completes a session | AP to facilitator | Fee per session based on facilitator level (max 2hr) |
| Batch completes / period closes | AP to Course Creator | % of batch profit or gross revenue (per settings) |
| Batch completes / period closes | AP to Dept Leader | % of batch profit or gross revenue (per settings) |
| Batch completes / period closes | AP to Op Leader | % of batch profit or gross revenue (per settings) |
| Student enrolls via referral code | AP to marketing partner | Commission per referral partner agreement (% or fixed) |

All auto-generated payables:
- Tagged with `Sumber: Auto`
- Auto-posted to accounting journal
- Status starts as `Pending` → approved by Accounting Leader → `Dibayar` after payment

---

**Last Updated:** Maret 2026
