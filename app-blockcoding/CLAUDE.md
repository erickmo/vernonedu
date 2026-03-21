# VernonEdu BlockCode — Flutter Mobile App

## Overview
Aplikasi mobile block-coding untuk peserta pelatihan IT VernonEdu. Pengguna belajar
logika pemrograman dengan visual drag-and-drop block editor, mirip Scratch/MIT App Inventor.

## Stack
- Flutter 3.x + Dart 3.x
- Platform: Android & iOS (Mobile)
- State Management: BLoC / Cubit
- Navigation: go_router
- DI: get_it
- Local Storage: shared_preferences

## Architecture
Clean Architecture — `lib/features/[feature]/data|domain|presentation/`

## Features
- Splash Screen & Onboarding
- Home Dashboard (kategori & challenge)
- Block Editor (drag-and-drop dari palette ke canvas)
- Code Generator (pseudocode dari blok)
- Code Executor (simulasi eksekusi)
- Progress Tracking (lokal)
- 12+ Challenge terstruktur

## Block Categories
| Kategori | Warna | Blok |
|---|---|---|
| Control | Orange | Start, End, If, If-Else, Repeat, While |
| I/O | Biru | Print, Ask Input |
| Variables | Merah | Set Variable, Change Variable |
| Math | Ungu | Add, Subtract, Multiply, Divide |
| Logic | Hijau | And, Or, Not, Compare |

## Coding Rules
- SEMUA code ditulis oleh AI
- Ikuti `flutter-coding-standard` skill
- Tidak ada business logic di `build()`
- Tidak ada hardcode string/color/dimension
- Repository return `Either<Failure, T>`
- Handle semua state: loading/success/error/empty

## Commands
```bash
make get          # install dependencies
make run          # run di emulator
make run-android  # run di Android
make test         # flutter test
make analyze      # flutter analyze
make build-apk    # build APK release
```

## Important Notes
- Data challenge hardcoded di `lib/core/data/challenge_data.dart`
- Progress disimpan di SharedPreferences
- Tidak ada backend — offline-first
- Block ID menggunakan UUID
