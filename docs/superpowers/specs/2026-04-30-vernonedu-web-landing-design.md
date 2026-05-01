# VernonEdu Web Landing Page — Design Spec

**Date:** 2026-04-30  
**Status:** Approved  
**Stack:** React + Vite + Tailwind CSS  
**Location:** `/web` directory (separate from `/frontend`)

---

## Overview

Public-facing marketing website for VernonEdu. Targets two primary audiences (B2C students, B2B institutional partners) with a multi-page architecture where each audience has a dedicated page. Homepage acts as brand hub and audience router.

---

## Architecture

### Approach: Multi-Page (audience-segmented)

| Route | Page | Purpose |
|---|---|---|
| `/` | Home | Brand overview + audience chooser + sections |
| `/students` | Students | Kursus catalog, formats, pricing, registration |
| `/partners` | Partners | B2B program detail, contact form |
| `/batch` | Kelas Batch | Batch class listings + registration |
| `/blog` | Blog | Article index |
| `/blog/:slug` | Blog Post | Single article |
| `/about` | About | Lembaga profile |

---

## Design System

**Colors** — reuse existing `frontend/` brand tokens:
- Primary: `#9561ab` (brand-500)
- Dark: `#2e1a37` (brand-900)
- Light: `#d8a8f0` (brand-200)
- Pale: `#f8f0fd` (brand-50)
- Neutral: slate scale from `frontend/tailwind.config.ts`

**Typography:** Plus Jakarta Sans (same as frontend)

**Theme:** Light (white paper background, purple accents)

**Radius:** 14–24px rounded cards, 100px pill buttons

---

## Homepage Sections (in order)

### 1. Navigation (sticky)
- Logo: `VernonEdu` (brand-dark + brand accent on "Edu")
- Links: Beranda · Kursus · Kelas Batch · Mitra · Blog · Tentang
- CTA pill: "Daftar Sekarang" (brand purple)
- Frosted glass background on scroll

### 2. Hero
- Left: badge + oversized headline (`Belajar Lebih. Raih Lebih.` with italic accent) + description + CTA row (`Mulai Belajar` primary + `Lihat Kelas Batch` outline)
- Right: audience chooser card (pale purple bg) with two items: Siswa/Pelajar → `/students`, Mitra Institusi → `/partners`
- Bottom: stats strip (4 cols, border-separated): 12K+ Siswa · 500+ Kursus · 80+ Mitra · 15+ Kota

### 3. Sertifikasi Band (dark strip)
- Dark background (`brand-dark`)
- Three items: **BNSP** (Badan Nasional Sertifikasi Profesi) · **SKKNI** (Standar Kompetensi Kerja Nasional Indonesia) · Sertifikat Terverifikasi Digital
- Dividers between items

### 4. Partner List
- Off-white background
- Label: "Dipercaya oleh institusi terkemuka"
- Display: pill chips with partner institution names (placeholder: UI, ITB, UGM, Unair, SMKN, dll)

### 5. Course Ticker (marquee)
- Pale brand background
- Scrolling course category names (auto-scroll, infinite)

### 6. Kelas Batch (3-card grid)
- Section header with "Lihat Semua Batch →" link
- Each card: colored gradient image area + tags (kategori + Online/Offline) + batch name + description + start date + remaining seats + "Daftar Sekarang" CTA button
- Card colors: purple, lavender, rose gradients
- Tags: Online (green), Offline (amber)

### 7. Keunggulan / Features (2-col)
- Left: 5 feature rows (icon box + title + desc):
  1. Kurikulum Relevan Industri
  2. Online & Offline
  3. Sertifikasi BNSP & SKKNI
  4. Regular & Private Class
  5. **Talent Pool Alumni** — alumni masuk database talent pool, terhubung ke perusahaan mitra rekrutmen
- Right: sticky B2B card (brand purple bg) — short pitch + checklist + "Hubungi Tim Partnership" CTA

### 8. Testimoni (3-col asymmetric)
- Featured card (2fr, dark bg): alumni B2C — mention talent pool
- 2 compact cards: mitra institusi + peserta batch

### 9. B2B Section (2-col editorial, pale purple bg)
- Left: large headline (`Tingkatkan Kualitas Siswa Anda Bersama Kami`) + body + CTA button (dark bg)
- Right: 4 program cards: Kursus Standar · Program Custom · Seminar & Workshop · **Akses Talent Pool**

### 10. Blog (3-col asymmetric)
- Featured article (2fr): large thumbnail + category + title + excerpt + meta
- 2 compact articles: category + title + excerpt + meta
- "Semua Artikel →" link

### 11. CTA Band (dark brand-dark bg)
- Centered: headline + sub + two buttons (Daftar Gratis white + Hubungi Kami outline)

### 12. FAQ
- Off-white bg, centered max-width 720px
- 5 items covering: Kelas Batch, Talent Pool, Sertifikasi BNSP/SKKNI, online availability, cara daftar mitra

### 13. Footer (4-col, dark bg)
- Brand + tagline
- Belajar: Katalog Kursus · Kelas Batch · Kelas Private · Talent Pool · Verifikasi Sertifikat
- Institusi: Program Mitra · Hubungi Partnership · Akses Talent Pool
- Perusahaan: Tentang Kami · Blog · Kontak · Kebijakan Privasi
- Bottom bar: copyright + "Made in Indonesia 🇮🇩"

---

## Key Features

### Kelas Batch
- Public listing page at `/batch`
- Card per batch: nama + nomor batch + kategori + format (online/offline) + tanggal mulai + sisa kursi + tombol daftar
- "Daftar" links to `/register` in main `frontend/` app

### Talent Pool
- Presented as alumni benefit (feature section + B2B card + FAQ)
- Not a standalone page on web — links to student portal for detail
- B2B partners: access framed as recruitment benefit in partners page

### Sertifikasi
- BNSP + SKKNI highlighted in dark band immediately after hero (high trust signal)
- Repeated in Features section (feat #3)
- Dedicated FAQ answer
- Footer link: "Verifikasi Sertifikat" → `/verify` in main app

---

## Technical Notes

- **Separate Vite app** in `/web` directory, not nested in `/frontend`
- Shares brand token values (hardcoded from `frontend/tailwind.config.ts`) — no shared package yet
- All CTAs that require login (Daftar, Verifikasi Sertifikat) link to `frontend/` app routes
- Blog articles: static content initially (MDX or JSON), no CMS dependency in v1
- Responsive: mobile breakpoint at 768px (stack to single column)
- No auth required — fully public

---

## Out of Scope (v1)

- Franchise page (hidden from web)
- Student dashboard / portal (lives in `frontend/`)
- Payment integration
- CMS for blog
- Search functionality
