# Finance Transactions Screen — Layout Spec

> Transaction input and journal entry management.

---

**Route:** `/finance/transactions`
**Title:** Transaksi
**Subtitle:** Input & Riwayat Transaksi

---

## Transaction List

**Actions:**
- `+ Input Transaksi` button → transaction form
- `+ Jurnal Umum` button → journal entry form

**Filters:**
- Tipe (dropdown: Pemasukan / Pengeluaran / Transfer)
- Akun (dropdown/search — from Chart of Accounts)
- Sumber (dropdown: Manual / Auto)
- Branch (dropdown)
- Tanggal (date range)

**Table:** Pagination 25 per page

| Tanggal | Kode | Deskripsi | Akun | Debit | Kredit | Sumber | Branch |
|---------|------|-----------|------|-------|--------|--------|--------|
| [date] | [code] | [description] | [account] | [amount or —] | [amount or —] | [auto/manual pill] | [branch] |

---

## Transaction Input Form

**Route:** `/finance/transactions/new`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Tanggal | date picker | ✅ | Default: today |
| Tipe | dropdown (Pemasukan / Pengeluaran / Transfer) | ✅ | — |
| Akun Debit | dropdown/search (CoA) | ✅ | — |
| Akun Kredit | dropdown/search (CoA) | ✅ | — |
| Jumlah | number input | ✅ | — |
| Deskripsi | text input | ✅ | — |
| Referensi | text input | ❌ | Invoice number, batch code, etc. |
| Branch | dropdown | ✅ | Default: user's branch |
| Lampiran | file upload | ❌ | Receipt, proof |

**Actions:**
- `Simpan` → saves transaction and posts to journal
- `Batal` → back to transaction list

---

## Journal Entry Screen

**Route:** `/finance/journal`
**Title:** Jurnal Umum

**Filters:**
- Tanggal (date range)
- Akun (dropdown/search)
- Sumber (dropdown: Manual / Auto-Invoice / Auto-Payable / Auto-Commission)

**Table:** Pagination 25 per page

| Tanggal | No Jurnal | Deskripsi | Akun | Debit | Kredit | Sumber |
|---------|----------|-----------|------|-------|--------|--------|
| [date] | [JRN-xxx] | [description] | [account] | [amount] | [amount] | [source pill] |

---

## Chart of Accounts Management

**Route:** `/finance/coa`
**Title:** Daftar Akun (Chart of Accounts)

**Action:** `+ Tambah Akun` button (if permitted)

**Tree view** (expandable):

```
▶ 1000 Aset
    1100 Aset Lancar
        1101 Kas
        1102 Bank BCA
        1103 Piutang Usaha
    1200 Aset Tetap
        1201 Peralatan
▶ 2000 Kewajiban
    2100 Hutang Usaha
    2200 Hutang Komisi
▶ 3000 Ekuitas
▶ 4000 Pendapatan
▶ 5000 Beban
```

Each account shows: code, name, type, current balance, is_active toggle

---

**Last Updated:** Maret 2026
