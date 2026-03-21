# Pages: Katalog Kursus

> Course catalog, course detail, and batch detail — all dynamic from API.

---

## Katalog Kursus (Browse)

**Route:** `/katalog`
**Title:** Katalog Kursus

### Filter Sidebar (desktop) / Filter Sheet (mobile)

- Search (text input — course name)
- Tipe Program: checkboxes (Program Karir, Reguler, Privat, Sertifikasi, Kolaborasi, Inhouse)
- Departemen: dropdown
- Harga: range slider (min–max)
- Jadwal: Tersedia Sekarang / Akan Datang
- Sort: Terpopuler / Terbaru / Harga Terendah / Harga Tertinggi

### Content: Course Card Grid

Pagination 12 per page. Responsive: 3 columns desktop, 2 tablet, 1 mobile.

**Course Card:**
```
┌─────────────────────────────────┐
│ [Course Image / Placeholder]    │
│─────────────────────────────────│
│ [Type pill: Program Karir]      │
│ [Course Name — bold]            │
│ [Short desc — 2 lines max ...]  │
│─────────────────────────────────│
│ 💰 Mulai dari Rp [min_price]   │
│ 📅 [X batch tersedia]           │
│ 👥 [total enrolled] siswa       │
│─────────────────────────────────│
│ [Lihat Detail →]                │
└─────────────────────────────────┘
```

**On click:** → `/katalog/:courseId`

---

## Course Detail

**Route:** `/katalog/:courseId`

### Hero Section
- Course name (large)
- Type pills (all available types for this course)
- Short description
- Key stats: total siswa, total batch, rating
- **CTA:** "Pilih Jadwal & Daftar" (scroll to batch section)

### Section: Tentang Kursus
- Full description
- Syarat peserta
- What you'll learn (bullet list from modules overview)

### Section: Tipe Tersedia

Horizontal tab/pill selector for available course types:

Per type shows:
- Price: Rp [min_price] — Rp [normal_price]
- Duration: [X sessions]
- Participants: [min]–[max] per batch
- Certificate: ☑ Participant ☑ Competency (if applicable)

### Section: Batch Tersedia (from API, filtered by selected type)

**Cards:** Available batches (only `website_visible = true`)

```
┌─────────────────────────────────┐
│ Batch: [code]                   │
│ 📅 [start_date] — [end_date]   │
│ 🏢 [branch / location]         │
│ 👥 [enrolled]/[max] siswa      │
│ 💰 Rp [batch_price]            │
│ [Lihat Jadwal] [Daftar →]      │
└─────────────────────────────────┘
```

**"Lihat Jadwal"** → expand/modal showing session schedule (date, module, time)
**"Daftar →"** → `/daftar/:batchId`

If batch is full: show "Kuota Penuh" disabled state
If no batches: show "Belum ada jadwal tersedia. Hubungi kami untuk info."

### Section: Fasilitator
- Facilitator cards: photo, name, level, brief bio

### Section: Testimonials
- Filtered to this course

### Section: FAQ
- Course-specific FAQ accordion

---

## Batch Detail (optional deep-link)

**Route:** `/katalog/:courseId/batch/:batchId`

Focused view of a single batch:
- Batch metadata (dates, location, facilitator, price)
- Full session schedule with modules
- Enrollment status (seats remaining)
- **CTA:** "Daftar Sekarang" → `/daftar/:batchId`

---

**Last Updated:** Maret 2026
