# CMS Screens — Layout Spec

> Content Management System for managing app-website content from app-dashboard.
> All website content is served via API `/api/v1/public/*` endpoints.

---

**Route:** `/cms`
**Title:** Manajemen Konten Website
**Subtitle:** Kelola halaman, artikel, testimoni, dan FAQ

---

## Section 1: Pages

Manage static/semi-static page content (hero text, descriptions, benefits, etc.)

### Card: Page List

**Table:**

| Halaman | Slug | Terakhir Diedit | Diedit Oleh | Aksi |
|---------|------|----------------|-------------|------|
| Home | `/` | [date] | [name] | ✏️ |
| Program Karir | `/program/karir` | [date] | [name] | ✏️ |
| Untuk Universitas | `/untuk/universitas` | [date] | [name] | ✏️ |
| ... | ... | ... | ... | ✏️ |

**On edit click:** → Page Editor

### Page Editor (modal or `/cms/pages/:slug/edit`)

- Page title, subtitle (text inputs)
- Content blocks: rich text editor (sections, benefits, pain points, etc.)
- Hero image upload
- SEO fields: meta title, meta description, OG image
- `Preview` button (opens app-website in new tab with draft content)
- `Simpan` / `Publish` buttons

---

## Section 2: Articles / Blog

**Route tab or:** `/cms/articles`

### Actions
- `+ Buat Artikel` button

### Filters
- Kategori (dropdown: Tips Karir / Info Kursus / Berita / Event)
- Status (dropdown: Draft / Published / Archived)

### Table: Pagination 15 per page

| Judul | Kategori | Status | Tanggal Publish | Author | Aksi |
|-------|----------|--------|----------------|--------|------|
| [title] | [category pill] | [status pill] | [date or —] | [name] | ✏️ 🗑 |

### Article Editor (`/cms/articles/new` or `/cms/articles/:id/edit`)

| Field | Type |
|-------|------|
| Judul | text input |
| Slug | auto-generated from title (editable) |
| Kategori | dropdown |
| Konten | rich text editor (with image embed) |
| Featured Image | image upload |
| SEO: meta title, description | text inputs |
| Status | Draft / Published |

---

## Section 3: Testimonials

### Actions
- `+ Tambah Testimoni` button

### Table: Pagination 10 per page

| Nama | Kursus | Rating | Featured | Aksi |
|------|--------|--------|----------|------|
| [student name] | [course name] | ⭐⭐⭐⭐⭐ | ☑/☐ | ✏️ 🗑 |

### Testimonial Form (modal)

| Field | Type |
|-------|------|
| Nama Siswa | text (or select from student list) |
| Kursus | dropdown |
| Quote | textarea |
| Rating | 1-5 stars |
| Foto | image upload |
| Featured | toggle (shown on home page) |

---

## Section 4: FAQ

### Actions
- `+ Tambah FAQ` button

### Filters
- Kategori (dropdown: Umum / Pendaftaran / Pembayaran / Sertifikat / Program Karir)
- Halaman (dropdown: which page this FAQ appears on)

### Table: Sortable (drag to reorder)

| Pertanyaan | Kategori | Halaman | Order | Aksi |
|-----------|----------|---------|-------|------|
| [question — truncate] | [category] | [page slug] | [↑↓] | ✏️ 🗑 |

### FAQ Form (modal)

| Field | Type |
|-------|------|
| Pertanyaan | text input |
| Jawaban | rich text |
| Kategori | dropdown |
| Tampil di Halaman | multi-select (home, program-karir, hubungi, etc.) |

---

## Section 5: Media Library

### Actions
- `Upload Media` button

### Content: Grid of uploaded images/files

- Thumbnail preview
- File name, size, upload date
- Copy URL button
- Delete button

---

## Section 6: SEO Overview

**Table:** SEO status per page

| Halaman | Meta Title | Meta Description | OG Image | Score |
|---------|-----------|-----------------|----------|-------|
| [page name] | ✅/❌ | ✅/❌ | ✅/❌ | [completeness %] |

Click → edit SEO for that page

---

## Role Access

| Role | Access |
|------|--------|
| Director | Full CMS access |
| Education Leader | Edit program pages, testimonials |
| Operation Leader | Edit segment pages, FAQ |
| Marketing | Full CMS access (primary user) |
| Others | No CMS access |

---

**Last Updated:** Maret 2026
