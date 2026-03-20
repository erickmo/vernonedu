# VernonEdu Entrepreneurship App — Flutter Web PWA

## Project Overview
Aplikasi web PWA untuk siswa entrepreneurship di VernonEdu. Menjadi guide mulai dari belajar ilmu bisnis, business ideation, launchpad, operation, administration, marketing & branding, HR management, hingga finance & laporan keuangan.

## Stack
- Flutter 3.41.4 + Dart 3.11.1
- Platform: Web PWA
- State Management: BLoC / Cubit
- Navigation: go_router
- DI: get_it
- Network: Dio
- Font: Google Fonts (Inter)

## Architecture
Clean Architecture — `lib/features/[feature]/data|domain|presentation/`

## PRD & Requirements
- PRD Utama: `docs/requirements/prd-vernonedu-entrepreneurship.md`

## Coding Rules
- SEMUA code ditulis oleh AI — tidak ada manual coding
- Ikuti `flutter-coding-standard` skill
- Widget > 50 baris → pecah ke sub-widget
- DILARANG business logic di build()
- DILARANG hardcode string/color/dimension
- Repository return Either<Failure, T>
- Handle semua state: loading/success/error/empty
- Gunakan `Responsive` widget untuk layout responsive (mobile/tablet/desktop)

## Commands
```bash
make run          # run di chrome
make run-dev      # run dengan dev API
make test         # flutter test
make gen          # build_runner (code generation)
make analyze      # flutter analyze
make build-web    # build web release (PWA)
```

## Forbidden
- JANGAN push langsung ke main/master
- JANGAN hardcode URL atau API key
- JANGAN gunakan flutter_secure_storage (web tidak support, pakai shared_preferences)
