# Finance Analysis Screen — Layout Spec

> Financial analysis, ratios, trends, and actionable insights.

---

**Route:** `/finance/analysis`
**Title:** Analisis Keuangan
**Subtitle:** Analisis & Insight Keuangan

---

## Common Controls

**Filter Bar:**
- Period: dropdown (Bulanan / Kuartalan / Tahunan / Custom)
- Branch: dropdown (Semua Cabang / specific)
- Comparison: dropdown (vs Bulan Lalu / vs Kuartal Lalu / vs Tahun Lalu)

---

## Section 1: Key Financial Ratios

### Cards Row (4 cards)

| Card | Value | Trend |
|------|-------|-------|
| Profit Margin | percentage | ↑/↓ vs previous period |
| Operating Expense Ratio | percentage | ↑/↓ |
| Revenue per Student | amount | ↑/↓ |
| Cost per Student | amount | ↑/↓ |

### Cards Row 2 (4 cards)

| Card | Value | Trend |
|------|-------|-------|
| Average Batch Profitability | percentage | ↑/↓ |
| Collection Rate (paid / total invoice) | percentage | ↑/↓ |
| Days Sales Outstanding (DSO) | days | ↑/↓ |
| Revenue Growth Rate | percentage | ↑/↓ |

---

## Section 2: Revenue Analysis

### Chart: Revenue Trend

**Line chart:** Monthly revenue breakdown (last 12 months)
- Lines: Total Revenue, Kursus Reguler, Program Karir, Inhouse, Kolaborasi, Sertifikasi

### Card: Revenue by Course Type

**Table:**

| Tipe Kursus | Pendapatan | % Total | Jumlah Batch | Avg per Batch | Trend |
|-------------|-----------|---------|-------------|--------------|-------|
| Program Karir | [amount] | [%] | [count] | [avg] | ↑/↓ |
| Reguler | [amount] | [%] | [count] | [avg] | ↑/↓ |
| Inhouse | [amount] | [%] | [count] | [avg] | ↑/↓ |
| ... | ... | ... | ... | ... | ... |

### Card: Revenue by Branch

**Bar chart:** Revenue comparison across branches

---

## Section 3: Cost Analysis

### Chart: Cost Breakdown Trend

**Stacked bar chart:** Monthly cost breakdown (last 12 months)
- Segments: Facilitator, Commission, Operational, Marketing, Investment

### Card: Cost per Category

**Table:**

| Kategori | Jumlah | % Total | vs Bulan Lalu | Trend |
|----------|--------|---------|--------------|-------|
| Biaya Fasilitator | [amount] | [%] | [+/- amount] | ↑/↓ |
| Komisi | [amount] | [%] | [+/- amount] | ↑/↓ |
| Operasional | [amount] | [%] | [+/- amount] | ↑/↓ |
| Marketing | [amount] | [%] | [+/- amount] | ↑/↓ |
| Lainnya | [amount] | [%] | [+/- amount] | ↑/↓ |

---

## Section 4: Batch Profitability Analysis

### Card: Most Profitable Batches

**Table:** Top 10 batches by profit margin

| Batch | Course | Pendapatan | Pengeluaran | Komisi | Laba | Margin % |
|-------|--------|-----------|-------------|--------|------|----------|
| [code] | [course] | [rev] | [exp] | [comm] | [profit] | [%] |

### Card: Least Profitable Batches

**Table:** Bottom 10 batches by profit margin (same columns)

### Chart: Batch Profitability Distribution

**Histogram:** Distribution of batch profit margins (how many batches at each % range)

---

## Section 5: Cash Flow Forecast

### Chart: Cash Position Projection

**Line chart:** Projected cash position for next 3 months
- Lines: Projected Cash, Projected Inflow, Projected Outflow
- Based on: scheduled invoices, pending payables, recurring costs

### Card: Upcoming Cash Events

**Table:** Next 30 days — expected inflows and outflows

| Tanggal | Tipe | Deskripsi | Jumlah | Status |
|---------|------|-----------|--------|--------|
| [date] | [inflow/outflow pill] | [description] | [amount] | [confirmed/projected] |

---

## Section 6: Suggestions & Alerts

System-generated insights and alerts:

### Card: Alerts

```
┌─────────────────────────────────────────────────────┐
│ ⚠️  12 invoice jatuh tempo belum dibayar            │
│ ⚠️  Profit margin bulan ini turun 5% dari bulan lalu│
│ ⚠️  3 batch memiliki margin negatif                  │
│ ℹ️  Cash position projected to dip in 45 days        │
│ ✅  Collection rate improved by 8%                    │
└─────────────────────────────────────────────────────┘
```

### Card: Recommendations

```
┌─────────────────────────────────────────────────────┐
│ 💡 Follow up 12 outstanding invoices (Rp XX juta)   │
│ 💡 Review pricing for 3 negative-margin batches     │
│ 💡 Consider increasing min price for Privat type    │
│ 💡 Marketing ROI highest from referral channel       │
│ 💡 Branch [X] has highest revenue growth — replicate │
└─────────────────────────────────────────────────────┘
```

---

## API Requirements

```
# Financial Ratios
GET /finance/analysis/ratios           ?period, branch_id, comparison

# Revenue Analysis
GET /finance/analysis/revenue          ?period, branch_id, group_by (course_type|branch|month)

# Cost Analysis
GET /finance/analysis/costs            ?period, branch_id, group_by (category|month)

# Batch Profitability
GET /finance/analysis/batch-profit     ?period, branch_id, sort (top|bottom), limit

# Cash Forecast
GET /finance/analysis/cash-forecast    ?months=3, branch_id

# Alerts & Suggestions
GET /finance/analysis/alerts
GET /finance/analysis/suggestions
```

---

**Last Updated:** Maret 2026
