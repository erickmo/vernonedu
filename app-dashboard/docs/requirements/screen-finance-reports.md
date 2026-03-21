# Finance Reports Screens — Layout Spec

> Balance sheet, profit & loss, cash flow, and other standard financial reports.

---

**Route:** `/finance/reports`
**Title:** Laporan Keuangan
**Subtitle:** Laporan Standar Akuntansi

---

## Common Controls (all reports)

**Filter Bar:**
- Period: dropdown (Bulanan / Kuartalan / Tahunan / Custom range)
- Branch: dropdown (Semua Cabang / specific branch) — Director sees all
- Tanggal: date range picker (for custom)
- `Export PDF` button
- `Export Excel` button

---

## Report 1: Neraca (Balance Sheet)

**Route:** `/finance/reports/balance-sheet`

### Layout

Two-column layout:

| Column 1 (1/2) | Column 2 (1/2) |
|-----------------|-----------------|
| **Aset (Assets)** | **Kewajiban & Ekuitas (Liabilities & Equity)** |

Per column — expandable account tree:

```
▶ Aset Lancar                          Rp XXX.XXX.XXX
    Kas & Bank                          Rp XXX.XXX.XXX
    Piutang Usaha                       Rp XXX.XXX.XXX
    Piutang Lain-lain                   Rp XXX.XXX.XXX
▶ Aset Tetap                           Rp XXX.XXX.XXX
    Peralatan                           Rp XXX.XXX.XXX
    Akumulasi Penyusutan               (Rp XXX.XXX.XXX)
────────────────────────────────────────────
Total Aset                              Rp XXX.XXX.XXX
```

**Footer:** Total Aset = Total Kewajiban + Ekuitas (balance check indicator ✅/❌)

---

## Report 2: Laba Rugi (Profit & Loss / Income Statement)

**Route:** `/finance/reports/profit-loss`

### Layout

Single column — expandable account tree:

```
▶ Pendapatan                            Rp XXX.XXX.XXX
    Pendapatan Kursus                   Rp XXX.XXX.XXX
    Pendapatan Inhouse                  Rp XXX.XXX.XXX
    Pendapatan Sertifikasi             Rp XXX.XXX.XXX
────────────────────────────────────────────
Total Pendapatan                        Rp XXX.XXX.XXX

▶ Harga Pokok Pendapatan (HPP)         Rp XXX.XXX.XXX
    Biaya Fasilitator                   Rp XXX.XXX.XXX
    Biaya Modul / Material             Rp XXX.XXX.XXX
────────────────────────────────────────────
Laba Kotor                              Rp XXX.XXX.XXX

▶ Beban Operasional                     Rp XXX.XXX.XXX
    Komisi (Op Leader)                  Rp XXX.XXX.XXX
    Komisi (Dept Leader)                Rp XXX.XXX.XXX
    Komisi (Course Creator)             Rp XXX.XXX.XXX
    Komisi (Marketing Partner)          Rp XXX.XXX.XXX
    Beban Sewa                          Rp XXX.XXX.XXX
    Beban Utilitas                      Rp XXX.XXX.XXX
    Beban Marketing                     Rp XXX.XXX.XXX
────────────────────────────────────────────
Laba Bersih                             Rp XXX.XXX.XXX
```

### Chart

**Bar chart** below the table: Monthly P&L trend (Pendapatan vs Pengeluaran vs Laba Bersih)

---

## Report 3: Arus Kas (Cash Flow Statement)

**Route:** `/finance/reports/cash-flow`

### Layout

Three sections:

```
▶ Arus Kas dari Aktivitas Operasi
    Penerimaan dari siswa                Rp XXX.XXX.XXX
    Penerimaan dari inhouse             Rp XXX.XXX.XXX
    Pembayaran fasilitator              (Rp XXX.XXX.XXX)
    Pembayaran komisi                   (Rp XXX.XXX.XXX)
    Pembayaran operasional              (Rp XXX.XXX.XXX)
    ─────────────────────────────
    Arus Kas Bersih Operasi              Rp XXX.XXX.XXX

▶ Arus Kas dari Aktivitas Investasi
    Pembelian peralatan                 (Rp XXX.XXX.XXX)
    Investasi cabang baru               (Rp XXX.XXX.XXX)
    ─────────────────────────────
    Arus Kas Bersih Investasi           (Rp XXX.XXX.XXX)

▶ Arus Kas dari Aktivitas Pendanaan
    Setoran modal                        Rp XXX.XXX.XXX
    Pinjaman                            Rp XXX.XXX.XXX
    ─────────────────────────────
    Arus Kas Bersih Pendanaan           Rp XXX.XXX.XXX

════════════════════════════════════════
Kenaikan/(Penurunan) Kas                Rp XXX.XXX.XXX
Saldo Awal Kas                          Rp XXX.XXX.XXX
Saldo Akhir Kas                         Rp XXX.XXX.XXX
```

### Chart

**Line chart:** Monthly cash position trend

---

## Report 4: Buku Besar (General Ledger)

**Route:** `/finance/reports/ledger`

**Filter:** Account (dropdown/search), Period (date range)

**Table:**

| Tanggal | Kode | Deskripsi | Ref | Debit | Kredit | Saldo |
|---------|------|-----------|-----|-------|--------|-------|
| [date] | [code] | [description] | [ref number] | [amount] | [amount] | [running balance] |

---

## Report 5: Neraca Saldo (Trial Balance)

**Route:** `/finance/reports/trial-balance`

**Table:**

| Kode Akun | Nama Akun | Debit | Kredit |
|-----------|-----------|-------|--------|
| [code] | [name] | [amount] | [amount] |
| | **Total** | **[total]** | **[total]** |

**Footer:** Balance check (Debit = Kredit) ✅/❌

---

## Report Navigation

Card grid on `/finance/reports`:

| Report | Icon | Description |
|--------|------|-------------|
| Neraca | 📋 | Balance Sheet — posisi keuangan |
| Laba Rugi | 📊 | Income Statement — kinerja keuangan |
| Arus Kas | 💰 | Cash Flow — pergerakan kas |
| Buku Besar | 📒 | General Ledger — detail per akun |
| Neraca Saldo | ⚖️ | Trial Balance — verifikasi saldo |

---

**Last Updated:** Maret 2026
