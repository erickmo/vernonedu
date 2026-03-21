# Finance Main Screen — Layout Spec

> Finance dashboard with key metrics, quick actions, and navigation to sub-modules.

---

**Route:** `/finance`
**Title:** Keuangan
**Subtitle:** Manajemen Keuangan & Akuntansi

---

## Statistics Section

### Number Cards Row 1

| Card | Value | Color |
|------|-------|-------|
| Total Pendapatan (bulan ini) | amount | green |
| Total Pengeluaran (bulan ini) | amount | red |
| Laba Bersih (bulan ini) | amount | green/red based on value |
| Kas & Bank | amount | blue |

### Number Cards Row 2

| Card | Value | Color |
|------|-------|-------|
| Piutang (Outstanding Invoice) | amount | orange |
| Hutang (Account Payable) | amount | red |
| Invoice Jatuh Tempo Minggu Ini | count | warning if > 0 |
| Komisi Belum Dibayar | amount | orange |

### Charts Row (2-column layout)

| Column 1 (1/2) | Column 2 (1/2) |
|-----------------|-----------------|
| **Bar Chart:** Pendapatan vs Pengeluaran (last 6 months) | **Pie Chart:** Komposisi Pengeluaran (facilitator, commission, operational, etc.) |

---

## Quick Actions Row

Buttons/cards linking to sub-modules:

| Action | Route | Icon |
|--------|-------|------|
| Input Transaksi | `/finance/transactions/new` | ➕ |
| Lihat Invoice | `/finance/invoices` | 📄 |
| Lihat Hutang | `/finance/payables` | 📋 |
| Laporan Keuangan | `/finance/reports` | 📊 |
| Analisis Keuangan | `/finance/analysis` | 📈 |
| Jurnal Umum | `/finance/journal` | 📒 |

---

## Tabs

### Tab 1: Transaksi Terbaru

**Table:** Last 20 transactions (auto-refresh)

| Tanggal | Kode | Deskripsi | Akun | Debit | Kredit | Sumber |
|---------|------|-----------|------|-------|--------|--------|
| [date] | [code] | [description] | [account name] | [amount or —] | [amount or —] | [auto/manual pill] |

### Tab 2: Anggaran vs Realisasi

**Filter:** Period (month picker), Branch (dropdown)

**Table:**

| Akun / Kategori | Anggaran | Realisasi | Selisih | % |
|----------------|---------|-----------|---------|---|
| [account] | [budget] | [actual] | [variance] | [% bar] |

### Tab 3: Ringkasan per Batch

**Table:**

| Batch | Pendapatan | Pengeluaran | Komisi | Laba | Margin % |
|-------|-----------|-------------|--------|------|----------|
| [batch code] | [revenue] | [expense] | [commission] | [profit] | [%] |

---

**Last Updated:** Maret 2026
