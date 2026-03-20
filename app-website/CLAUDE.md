# VernonEdu Website — Flutter Web

## Overview
Customer-facing promotional website untuk VernonEdu. Platform edukasi wirausaha terdepan.
Target: SEO tinggi (Google + AI indexing), desain premium, animasi trust-building.

## Stack
- Flutter 3.x + Dart 3.x
- Platform: **Web Only** (HTML renderer)
- Navigation: go_router
- Animations: flutter_animate + visibility_detector
- Typography: google_fonts (Poppins heading, Inter body)
- NO state management library — local setState cukup
- NO backend — semua data statis di `data/` folder

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
    ├── home/         ← home_page + widgets/
    ├── kursus/       ← kursus_page + data/
    ├── update/       ← update_page + data/
    └── hubungi/      ← hubungi_page
```

## Pages
| Page | Route | Deskripsi |
|---|---|---|
| Home | / | Hero, Stats, Features, Courses, Testimonials, CTA |
| Kursus | /kursus | Katalog kursus dengan filter & search |
| Update | /update | Blog/artikel + newsletter |
| Hubungi Kami | /hubungi | Form kontak, info kantor, FAQ |

## SEO Setup
- `web/index.html` — meta tags lengkap, OG, Twitter Card, JSON-LD
- `web/robots.txt` — crawl rules
- `web/sitemap.xml` — URL sitemap
- HTML renderer untuk SEO lebih baik
- `noscript` fallback untuk crawler tanpa JS

## Design System
- **Theme**: Dark Premium Navy (`#0A0F1E` background)
- **Primary**: Indigo `#4F46E5` → Violet `#7C3AED`
- **Accent**: Gold `#FBBF24`
- **Success**: Green `#10B981`
- **Font Heading**: Poppins (Bold 700-800)
- **Font Body**: Inter (Regular 400, Medium 500)

## Coding Rules
- SEMUA code ditulis oleh AI
- Ikuti `flutter-coding-standard` skill
- Tidak ada business logic di build()
- Tidak ada hardcode color/size — gunakan AppColors, AppDimensions, AppTextStyles
- Semua widget > 80 baris → pecah jadi subwidget
- Animasi scroll: gunakan `ScrollAnimateWidget` wrapper
- Animasi counter: gunakan `AnimatedCounterWidget`

## Commands
```bash
make get          # Install dependencies
make run-web      # Run di Chrome dengan HTML renderer
make build-web    # Build production
make analyze      # Lint check
```

## Important Notes
- Gunakan `--web-renderer html` untuk SEO yang lebih baik
- Semua konten data statis ada di `lib/features/[feature]/data/`
- Untuk produksi: ganti data statis dengan API calls
- Port default: 3002 (diatur di settings Flutter)
