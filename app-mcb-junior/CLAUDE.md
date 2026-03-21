# MCB Junior — Flutter Web PWA

## Overview
Aplikasi web PWA untuk membantu pembentukan mindset dan habit anak melalui permainan, tugas, dan sistem reward. Target pengguna: anak usia 6-12 tahun.

**PRD Lengkap:** docs/requirements/prd-mcb-junior.md

## Stack
- **Platform:** Flutter Web (PWA)
- **State Management:** BLoC / Cubit
- **Navigation:** go_router
- **DI:** get_it + injectable
- **Network:** Dio
- **Backend API:** https://api.mcbjunior.com/api/v1

## Active Sprint
**Sprint 1 — Maret 2026**

Feature yang sedang dikerjakan:
- [ ] Auth (login, onboarding) → requirement: docs/requirements/feature-auth.md
- [ ] Dashboard → requirement: docs/requirements/feature-dashboard.md
- [ ] Quest (misi) → requirement: docs/requirements/feature-quest.md
- [ ] Habit (kebiasaan) → requirement: docs/requirements/feature-habit.md
- [ ] Reward → requirement: docs/requirements/feature-reward.md
- [ ] Profile → requirement: docs/requirements/feature-profile.md

## Coding Rules
- SEMUA code ditulis oleh AI. Developer tidak menulis code manual.
- Ikuti flutter-coding-standard skill
- Tidak ada push langsung ke `main` atau `master`
- Wajib widget test untuk setiap screen baru
- Tidak ada business logic di dalam build()
- Tidak ada hardcode string/color/dimension — gunakan AppStrings, AppColors, AppDimensions
- Semua state (loading/success/error/empty) wajib di-handle
- Bahasa UI: Bahasa Indonesia yang ramah anak (tidak formal)

## Project Structure
```
lib/
├── core/
│   ├── constants/      ← AppColors, AppDimensions, AppStrings, AppTextStyles
│   ├── di/             ← Dependency injection (get_it)
│   ├── errors/         ← Failure classes
│   ├── network/        ← ApiClient, NetworkInfo
│   ├── router/         ← AppRouter (go_router)
│   ├── theme/          ← AppTheme
│   └── utils/          ← Logger, DateUtils, EitherExtension
├── features/
│   ├── auth/           ← Onboarding, Login
│   ├── dashboard/      ← Home dashboard
│   ├── quest/          ← Misi/Task
│   ├── habit/          ← Kebiasaan harian
│   ├── reward/         ← Katalog hadiah
│   └── profile/        ← Profil anak
└── main.dart
web/
├── index.html          ← PWA shell dengan loading screen
└── manifest.json       ← PWA manifest
docs/
└── requirements/       ← PRD & feature requirements
```

## Key Commands
```bash
make get          # flutter pub get
make dev          # flutter run di Chrome (port 3000)
make gen          # build_runner code generation
make test         # flutter test
make analyze      # flutter analyze
make build-web    # build release PWA
```

## Design Principles
- **Colorful & Fun:** Palet warna cerah — biru, kuning, hijau, ungu
- **Large Touch Targets:** Tombol dan elemen minimal 48x48px
- **Emoji First:** Gunakan emoji sebagai icon utama untuk kesan ramah anak
- **Celebration:** Animasi dan feedback positif saat menyelesaikan task
- **Readable:** Font besar (minimal 14px), kontras tinggi

## Important Notes
- BASE_URL diset via --dart-define saat run/build
- Wajib run `make gen` setelah buat/ubah freezed atau injectable
- App dirancang untuk tampil di mobile browser (max-width: 480px)
- PWA wajib bisa diinstall di Android & iOS

## Requirements Index
| File | Fitur | Status |
|---|---|---|
| docs/requirements/prd-mcb-junior.md | PRD Utama | Active |
