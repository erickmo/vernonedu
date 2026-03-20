# PRD: VernonEdu Entrepreneurship App

**Versi:** 1.0.0
**Tanggal:** 2026-03-16
**Status:** Draft
**Stack:** Flutter Web PWA
**Author:** AI-Generated
**Reviewer:** -

---

## 1. Overview

### 1.1 Latar Belakang
Siswa entrepreneurship di VernonEdu membutuhkan platform digital yang menjadi panduan komprehensif dalam perjalanan belajar dan praktek bisnis mereka. Saat ini belum ada tools terpadu yang menghubungkan teori dengan praktek.

### 1.2 Tujuan Produk
Menyediakan web app (PWA) yang menjadi one-stop guide bagi siswa untuk:
- Belajar ilmu bisnis secara terstruktur
- Melakukan business ideation
- Meluncurkan bisnis (business launchpad)
- Mengelola operasional bisnis
- Mengelola administrasi bisnis
- Merencanakan marketing & branding
- Mengelola human resource
- Mengelola finance & laporan keuangan

### 1.3 Target Pengguna
| Role | Deskripsi |
|---|---|
| Siswa | Siswa entrepreneurship VernonEdu yang belajar dan praktek bisnis |
| Mentor/Guru | Memantau progress siswa dan memberikan feedback |

---

## 2. Fitur Utama

| Fitur | Prioritas | Status | Details |
|---|---|---|---|
| Auth (Login/Register) | High | Belum mulai | - |
| Dashboard | High | Belum mulai | - |
| Learning Module | High | Belum mulai | - |
| Business Ideation | High | ✅ In Progress | Canvas-based worksheets (BMC, VPC, DT, PESTEL, Flywheel) |
| Business Launchpad | Medium | Belum mulai | - |
| Business Operation | Medium | Belum mulai | - |
| Business Administration | Medium | Belum mulai | - |
| Marketing & Branding | Medium | Belum mulai | - |
| HR Management | Medium | Belum mulai | - |
| Finance & Reporting | Medium | Belum mulai | - |

---

## 2.1 Business Ideation — Canvas-Based Worksheets ✅

**Status:** In Development (Canvas Implementation Complete)
**Tanggal:** 2026-03-17

### Overview
Fitur Business Ideation menggunakan canvas-based approach dengan sticky notes untuk collaborative ideation. Setiap worksheet type memiliki layout visual yang mencerminkan structure framework-nya, memudahkan siswa untuk visualize dan plan bisnis mereka.

### Worksheet Types

#### 1. Business Model Canvas (BMC)
9-blok model untuk design business model:
- Key Partners, Key Activities, Key Resources
- Value Propositions
- Channels, Customer Relationships, Customer Segments
- Cost Structure, Revenue Streams

**Features:**
- ✅ Cross-linking antar section
- ✅ Click chip → scroll ke linked section
- ✅ 9-blok grid layout

#### 2. Value Proposition Canvas (VPC)
2-sisi model: Value Map vs Customer Profile
- Left: Products & Services, Pain Relievers, Gain Creators
- Right: Customer Jobs, Pains, Gains

#### 3. Design Thinking
5-tahap framework: Empathize → Define → Ideate → Prototype → Test

#### 4. PESTEL Analysis
6-kategori analysis: Political, Economic, Social, Technological, Environmental, Legal

#### 5. Flywheel Marketing
3 main + 2 support: Attract, Engage, Delight, Friction Points, Force (Accelerators)

### Canvas Features

**Sticky Notes:**
- ✅ Inline text editing
- ✅ Expandable note section per item
- ✅ Delete button (X) di pojok kanan atas
- ✅ Auto-focus pada item baru

**Section Controls:**
- ✅ Add item button (+) per section
- ✅ Color indicator per section
- ✅ Linked-section chips (BMC: 9 cross-links)
- ✅ Click-to-scroll navigation

**Responsive Layout:**
- ✅ Desktop: Complex grid/column layouts sesuai framework
- ✅ Tablet: Adaptive sizing
- ✅ Mobile: Single-column vertical list with cards

### User Actions

| Action | Behavior |
|--------|----------|
| Add Item | Click (+) → new sticky note dengan auto-focus |
| Edit Text | Click sticky note → edit inline |
| Expand Note | Click "Catatan" → toggle note section |
| Delete Item | Click (✕) → item dihapus |
| Jump Section (BMC) | Click linked chip → scroll ke target |

### State Management
- Local StatefulWidget dengan `Map<String, List<CanvasItem>>`
- CanvasItem: id, text, note, isExpanded
- Callbacks: onAdd, onUpdate, onDelete (section-aware)

### Implementation Details
- **Files Created:** 7 new widget files + 1 modified page
- **Widgets:** CanvasStickyNoteWidget, CanvasSectionWidget, BMCCanvasWidget, VPCCanvasWidget, DTCanvasWidget, PestelCanvasWidget, FlywheelCanvasWidget
- **State:** Local state (TODO: integrate with backend BLoC)
- **Persistence:** TODO - implement local storage or backend API

### Known Limitations (v1.0)
- Local state only (no persistence)
- No backend integration yet
- No undo/redo
- No content validation
- No collaboration features

### Next Steps (v1.1+)
- [ ] Backend integration untuk persist data
- [ ] Local storage caching (shared_preferences)
- [ ] Undo/redo functionality
- [ ] Content validation & suggestions
- [ ] Export to PDF/image
- [ ] Mentor feedback/comments
- [ ] Progress tracking & analytics

### Documentation
- Detailed feature docs: `docs/FEATURES.md`
- Widget implementation: Individual file comments
- Testing guide: In-code comments

---

## 3. User Journey Utama

### Journey 1: Siswa Memulai Perjalanan Bisnis
1. Siswa login ke aplikasi
2. Melihat dashboard dengan progress learning
3. Mengikuti modul pembelajaran bisnis
4. Membuat ide bisnis di Business Ideation
5. Meluncurkan bisnis melalui Business Launchpad
6. Mengelola bisnis (operasional, admin, marketing, HR, finance)

---

## 4. Non-Functional Requirements

| Kategori | Target |
|---|---|
| Load time | < 3 detik (koneksi 4G) |
| Platform | Web (PWA - installable) |
| Offline | Basic caching untuk content yang sudah dibuka |
| Browser support | Chrome, Safari, Firefox, Edge (latest 2 versions) |
| Responsive | Mobile, Tablet, Desktop |

---

## 5. Out of Scope (v1.0)
- Payment/billing system
- Real-time collaboration
- Mobile native app (Android/iOS)

---

## 6. Open Questions
- [ ] Apakah ada backend API yang sudah tersedia?
- [ ] Apakah ada desain UI/UX (Figma) yang sudah dibuat?
- [ ] Berapa jumlah siswa yang akan menggunakan aplikasi ini?
- [ ] Fitur mana yang menjadi MVP (minimum viable product)?

---
*Template PRD — lengkapi sebelum mulai development.*
