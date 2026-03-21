# app-mentors

## Overview
Flutter mobile app for VernonEdu mentors, facilitators, and course owners. Allows managing schedules, executing attendance, viewing batch information, and assigning facilitators to batches.

**Target platforms:** Android & iOS

## Stack
- **Framework:** Flutter (Dart)
- **State Management:** BLoC / Cubit + Equatable
- **Navigation:** go_router v14 (StatefulNavigationShell)
- **DI:** get_it (singleton for datasource/repo, factory for usecase/cubit)
- **Network:** Dio + pretty_dio_logger, Bearer token via `_AuthInterceptor`
- **Storage:** shared_preferences (token persistence)
- **Error handling:** dartz `Either<Failure, T>`

## Coding Standard
Skill: `flutter-coding-standard`

## Role-Based Access
| Role | isCourseOwner | canAssignFacilitator | canTakeAttendance |
|------|--------------|---------------------|-------------------|
| course_owner | ✅ | ✅ | ✅ |
| director | ✅ | ✅ | ✅ |
| dept_leader | ✅ | ✅ | ✅ |
| facilitator | ❌ | ❌ | ✅ |
| mentor | ❌ | ❌ | ✅ |

Logic in `AuthUserEntity` (`lib/features/auth/domain/entities/auth_user_entity.dart`).

## App Structure
```
lib/
├── core/
│   ├── constants/      app_colors, app_strings, app_dimensions, app_constants
│   ├── di/             injection.dart (get_it setup)
│   ├── errors/         failures.dart
│   ├── network/        api_client.dart, network_info.dart
│   ├── router/         app_router.dart (go_router config)
│   ├── theme/          app_theme.dart
│   ├── utils/          date_util.dart
│   └── widgets/        error_view.dart, empty_view.dart
├── features/
│   ├── auth/           Login, AuthCubit, AuthUserEntity
│   ├── batch/          BatchList, BatchDetail, assign facilitator usecase
│   ├── attendance/     Session list, take attendance, submit attendance
│   ├── assignment/     FacilitatorEntity, AssignmentCubit
│   ├── schedule/       SchedulePage (week view), GET /sessions/my
│   ├── home/           Dashboard with stats + active batches
│   ├── profile/        User info + logout
│   └── shell/          Bottom navigation (4 tabs)
└── main.dart
```

## Navigation Routes
| Path | Page | Notes |
|------|------|-------|
| `/login` | LoginPage | Redirect here if unauthenticated |
| `/home` | HomePage | Tab 0 — Beranda |
| `/schedule` | SchedulePage | Tab 1 — Jadwal |
| `/batches` | BatchListPage | Tab 2 — Kelas |
| `/batches/:id` | BatchDetailPage | 3 tabs: Siswa, Modul, Info |
| `/batches/:id/attendance` | AttendancePage | Take/view attendance |
| `/batches/:id/assign-facilitator` | AssignFacilitatorPage | Course Owner only; `extra: BatchEntity` |
| `/profile` | ProfilePage | Tab 3 — Profil |

## API Base URL
```
http://localhost:8081/api/v1
```
Set via `--dart-define=BASE_URL=...` (default: `http://localhost:8081/api/v1`)

## Key Endpoints
| Endpoint | Used By |
|----------|---------|
| `POST /auth/login` | LoginUseCase |
| `GET /auth/me` | GetCurrentUserUseCase |
| `GET /course-batches/my` | GetMyBatchesUseCase |
| `GET /course-batches/:id/detail` | GetBatchDetailUseCase |
| `PUT /course-batches/:id/facilitator` | AssignFacilitatorUseCase |
| `GET /course-batches/:id/sessions` | GetAttendanceSessionsUseCase |
| `POST /course-batches/:id/sessions/:sid/attendance` | SubmitAttendanceUseCase |
| `GET /users?role=facilitator` | GetFacilitatorsUseCase |
| `GET /sessions/my?from=&to=` | GetMyScheduleUseCase |

## Attendance Statuses
| Code | Label | Shorthand |
|------|-------|-----------|
| present | Hadir | H |
| late | Terlambat | T |
| absent | Tidak Hadir | A |
| excused | Izin | I |

## Design
- **Primary:** #1565C0 (Deep Blue)
- **Secondary:** #00897B (Teal)
- **Font:** Google Fonts Inter
- **Theme:** Material 3, `AppTheme.light`

## Key Commands
```bash
# Run
flutter run --dart-define=BASE_URL=http://localhost:8081/api/v1

# Build APK
flutter build apk --dart-define=BASE_URL=https://api.vernonedu.com/api/v1

# Test
flutter test

# Analyze
flutter analyze
```

## Important Notes
- `BatchListCubit` is provided at the **shell level** (wraps all 4 tabs), not per-page
- `AuthCubit` is provided at **app root** via `BlocProvider.value`
- `AttendancePage` uses `MultiBlocProvider` with both `AttendanceCubit` + `BatchDetailCubit`
- `AssignFacilitatorPage` uses `MultiBlocProvider` with both `AssignmentCubit` + `BatchDetailCubit`
- All `DateTime` fields use local time from API (no explicit UTC conversion)
- `go_router` redirect listens to `AuthCubit` stream via `_AuthStateListenable`
