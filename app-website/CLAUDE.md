# VernonEdu Website — CLAUDE.md

> Customer-facing website. Flutter Web. Marketing + enrollment + certificate verification.
> **Language:** All UI in Bahasa Indonesia. Code comments in English.
> **Page specs:** See `docs/requirements/` for per-page layout details.

---

## Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x + Dart 3.x, Platform: Web Only (HTML renderer) |
| Navigation | go_router |
| Animations | flutter_animate + visibility_detector |
| Typography | google_fonts (Poppins heading, Inter body) |
| State | Local setState for UI. BLoC/Cubit for API-connected pages (enrollment, courses) |
| Network | Dio (for API-connected pages: course catalog, enrollment, certificate verification) |
| Content Source | API `/api/v1/public/*` — managed via CMS in app-dashboard |
| SEO | HTML renderer, meta tags, OG, JSON-LD, sitemap.xml, robots.txt |

---

## Architecture

```
lib/
├── core/
│   ├── constants/    ← colors, dimensions, text_styles
│   ├── router/       ← app_router.dart
│   ├── theme/        ← app_theme.dart
│   ├── utils/        ← responsive.dart, seo_helper.dart
│   └── widgets/      ← navbar, footer, reusable widgets
└── features/
    ├── home/         ← landing page
    ├── katalog/      ← course catalog (dynamic from API)
    ├── program/      ← program pages (karir, reguler, etc.)
    ├── segment/      ← audience pages (universitas, sekolah, korporat)
    ├── enrollment/   ← enrollment flow
    ├── sertifikat/   ← certificate verification
    ├── update/       ← blog/articles
    └── hubungi/      ← contact page
```

---

## Design System

| Token | Value |
|-------|-------|
| Background | Dark Premium Navy `#0A0F1E` |
| Primary | Indigo `#4F46E5` → Violet `#7C3AED` gradient |
| Accent | Gold `#FBBF24` |
| Success | Green `#10B981` |
| Font Heading | Poppins (Bold 700-800) |
| Font Body | Inter (Regular 400, Medium 500) |

---

## Navigation Structure (Navbar)

```
Logo  |  Program ▼  |  Untuk ▼  |  Katalog  |  Update  |  Hubungi  |  [CTA: Daftar Sekarang]

Program dropdown:
  ├── Program Karir
  ├── Kursus Reguler
  ├── Kursus Privat
  └── Sertifikasi

Untuk dropdown:
  ├── Untuk Universitas
  ├── Untuk Sekolah
  ├── Untuk Korporat (Inhouse Training)
  └── Untuk Individu
```

---

## Pages & Routes

| Page | Route | Source | Spec |
|------|-------|--------|------|
| Home | `/` | Static + API (stats, featured courses) | [page-home.md](docs/requirements/page-home.md) |
| Program Karir | `/program/karir` | Static + API | [page-programs.md](docs/requirements/page-programs.md) |
| Kursus Reguler | `/program/reguler` | Static + API | [page-programs.md](docs/requirements/page-programs.md) |
| Kursus Privat | `/program/privat` | Static + API | [page-programs.md](docs/requirements/page-programs.md) |
| Sertifikasi | `/program/sertifikasi` | Static + API | [page-programs.md](docs/requirements/page-programs.md) |
| Untuk Universitas | `/untuk/universitas` | Static | [page-segments.md](docs/requirements/page-segments.md) |
| Untuk Sekolah | `/untuk/sekolah` | Static | [page-segments.md](docs/requirements/page-segments.md) |
| Untuk Korporat | `/untuk/korporat` | Static | [page-segments.md](docs/requirements/page-segments.md) |
| Untuk Individu | `/untuk/individu` | Static | [page-segments.md](docs/requirements/page-segments.md) |
| Katalog Kursus | `/katalog` | API (dynamic) | [page-katalog.md](docs/requirements/page-katalog.md) |
| Detail Kursus | `/katalog/:courseId` | API | [page-katalog.md](docs/requirements/page-katalog.md) |
| Detail Batch | `/katalog/:courseId/batch/:batchId` | API | [page-katalog.md](docs/requirements/page-katalog.md) |
| Enrollment | `/daftar/:batchId` | API | [page-enrollment.md](docs/requirements/page-enrollment.md) |
| Verifikasi Sertifikat | `/sertifikat/:code` | API | [page-sertifikat.md](docs/requirements/page-sertifikat.md) |
| Update / Blog | `/update` | Static / CMS | [page-update.md](docs/requirements/page-update.md) |
| Hubungi Kami | `/hubungi` | Static + form submit | [page-hubungi.md](docs/requirements/page-hubungi.md) |

---

## Coding Rules

- SEMUA code ditulis oleh AI
- Tidak ada business logic di `build()`
- Tidak ada hardcode color/size — gunakan `AppColors`, `AppDimensions`, `AppTextStyles`
- Semua widget > 80 baris → pecah jadi subwidget
- Animasi scroll: gunakan `ScrollAnimateWidget` wrapper
- Animasi counter: gunakan `AnimatedCounterWidget`
- **Design consistency** — follow VernonEdu brand identity across all apps

---

## Commands

```bash
make get          # Install dependencies
make run-web      # Run di Chrome dengan HTML renderer
make build-web    # Build production
make analyze      # Lint check
```

---

## SEO

- `web/index.html` — meta tags, OG, Twitter Card, JSON-LD per page
- `web/robots.txt` — crawl rules
- `web/sitemap.xml` — all public URLs
- HTML renderer (`--web-renderer html`) for SEO
- `noscript` fallback for non-JS crawlers
- Each page has unique title, description, and structured data

---

**Last Updated:** Maret 2026
