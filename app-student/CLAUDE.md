# VernonEdu Student App — CLAUDE.md

> Flutter mobile app untuk siswa VernonEdu. Android & iOS.
> **Language rule:** All UI strings/labels in Bahasa Indonesia. Comments and documentation in English.

---

## Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x + Dart, Platform: Android & iOS |
| State | BLoC / Cubit (flutter_bloc) |
| Navigation | go_router (v12) |
| DI | get_it — registerSingleton for infra, registerFactory for cubit |
| Network | Dio + pretty_dio_logger. `ApiClient` injects Bearer token via `_AuthInterceptor` |
| Storage | shared_preferences — **never flutter_secure_storage** (consistency rule) |
| Charts | fl_chart |

**Ports:** API `http://localhost:8081/api/v1`

---

## Architecture

Clean Architecture: `lib/features/[domain]/data|domain|presentation/`

```
data/
  datasources/   → [feature]_remote_datasource.dart
  models/        → [feature]_model.dart (fromJson, toEntity)
  repositories/  → [feature]_repository_impl.dart
domain/
  entities/      → [feature]_entity.dart (pure Dart)
  repositories/  → [feature]_repository.dart (abstract)
  usecases/      → verb_noun_usecase.dart (single call() method)
presentation/
  cubit/         → [feature]_cubit.dart + [feature]_state.dart
  pages/         → [feature]_page.dart
  widgets/       → [feature]_*.dart
```

---

## Core Rules

- **No business logic in `build()`**
- **No hardcoded string/color/dimension** — use `AppStrings`, `AppColors`, `AppDimensions`
- **Repository returns `Either<Failure, T>`** (dartz)
- **Handle all UI states:** loading / success / error / empty
- **All code written by AI** — developer does not write manually

---

## AppColors (key tokens)

```dart
AppColors.primary          // #1A237E — deep indigo, brand
AppColors.primarySurface   // #E8EAF6
AppColors.accent           // #0097A7 — cyan
AppColors.accentSurface    // #E0F7FA
AppColors.background       // #F5F7FA
AppColors.surface          // #FFFFFF
AppColors.textPrimary      // #1A1A2E
AppColors.textSecondary    // #6B7280
AppColors.success / .successSurface
AppColors.warning / .warningSurface
AppColors.error / .errorSurface
AppColors.gradientPrimary  // [#1A237E, #3949AB]
AppColors.gradientAccent   // [#0097A7, #00BCD4]
```

## AppDimensions (key tokens)

```dart
// Spacing: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
// BorderRadius: radiusSm=8, radiusMd=12, radiusLg=16, radiusXl=24
// Icons: iconSm=16, iconMd=24, iconLg=32
// pagePadding=20 (horizontal page padding)
// sliderHeight=180 (banner carousel height)
// buttonHeight=52, bottomNavHeight=64
```

---

## Navigation (go_router)

```
/login      → LoginPage (unauthenticated)
/home       → HomePage (inside ShellRoute)
/schedule   → SchedulePage (inside ShellRoute)
/course     → CoursePage (inside ShellRoute, 2 tabs: Kelas Saya | Tersedia)
/certificate → CertificatePage (inside ShellRoute)
/profile    → ProfilePage (inside ShellRoute)
```

Auth redirect: unauthenticated → `/login`; authenticated on `/login` → `/home`
Shell: `ShellPage` wraps all authenticated pages with bottom navigation (5 tabs).

---

## Domain Status

| Domain | Status | Notes |
|---|---|---|
| Auth | Mock data | login() simulates API, saves to shared_preferences |
| Home | Mock data | Banner slider + stat cards + schedule preview |
| Schedule | Mock data | Filter: Semua/Hari Ini/Akan Datang/Selesai |
| Course | Mock data | Tab: Kelas Saya (progress) + Tersedia (enroll) |
| Certificate | Mock data | Grade A/B/C with gold/silver/bronze styling |
| Profile | Mock data | Stats row + info tiles + history + logout |

**To implement:** Replace mock data with real API calls per domain:
- `GET /enrollments?student_id=:id` → Course & History
- `GET /course-batches` → Available courses
- `GET /students/:id/enrollment-history` → History tab
- `POST /enrollments` → Enroll course
- `GET /certificates?student_id=:id` → Certificate list

---

## Commands

```bash
make get        # flutter pub get
make run-dev    # flutter run
make test       # flutter test
make analyze    # flutter analyze
```
