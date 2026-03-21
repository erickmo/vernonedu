# Page: Update & Hubungi

> Blog/articles page and contact page.

---

## Update / Blog

**Route:** `/update`
**Title:** Update & Artikel

### Filter
- Kategori: Semua / Tips Karir / Info Kursus / Berita / Event
- Search (text input)

### Content: Article Card Grid
Pagination 9 per page. Cards:

```
┌─────────────────────────────────┐
│ [Article Image]                 │
│─────────────────────────────────│
│ [Category pill]    [Date]       │
│ [Title — bold, 2 lines max]    │
│ [Excerpt — 2 lines max ...]    │
│ [Baca Selengkapnya →]           │
└─────────────────────────────────┘
```

### Article Detail: `/update/:slug`
- Title, date, author, category
- Full article content (rich text / markdown rendered)
- Share buttons
- Related articles at bottom

---

## Hubungi Kami

**Route:** `/hubungi`
**Title:** Hubungi Kami

### Two-column layout

**Column 1 (1/2): Contact Form**

| Field | Type | Required |
|-------|------|----------|
| Nama | text | ✅ |
| Email | email | ✅ |
| Telepon | phone | ❌ |
| Kategori | dropdown (Individu / Sekolah / Universitas / Korporat / Lainnya) | ✅ |
| Pesan | textarea | ✅ |

Submit → API + success toast

**Column 2 (1/2): Info**
- Office address + map embed
- Phone number
- Email
- Social media links
- Operating hours

### FAQ Section (below)
- Accordion: general FAQ items
- "Tidak menemukan jawaban? Hubungi kami"

---

**Last Updated:** Maret 2026
