# API ↔ Flutter Integration Status

**Last Updated:** 2026-03-17
**Status:** Ready to Sync

---

## 📊 Current Status

### Go API Backend ✅ PRODUCTION READY
```
/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-api/

Entities: User, Business, ValuePropositionCanvas, DesignThinking, Item
Endpoints: ✅ All CRUD endpoints implemented (/api/v1/{entities})
Database: ✅ PostgreSQL migrations ready
Auth: ✅ JWT ready
Stack: Chi, Uber FX, CQRS, Event-Driven
Status: Ready to serve requests
```

### Flutter Web Frontend ⚠️ PARTIAL READY
```
/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app/

UI Widgets: ✅ 100% Complete (canvas components)
API Client: ✅ Setup (Dio + interceptors)
Data Layer: ❌ MISSING
Repository: ❌ MISSING
BLoCs: ❌ MISSING
Models: ❌ MISSING

Need to complete: 4 layers before UI can talk to API
```

---

## 🎯 What Needs to Be Done

### 5 Implementation Phases

**Phase 1: Data Models** (1-2 days)
- Create API response models (business_model, canvas_model, etc)
- Create domain entities (clean architecture)
- Setup JSON serialization with freezed/json_annotation
- Location: `lib/features/business_ideation/data/models/`

**Phase 2: Remote Data Sources** (1 day)
- Create API clients for each entity
- Handle HTTP requests/responses
- Error handling
- Location: `lib/features/business_ideation/data/datasources/`

**Phase 3: Repositories** (1 day)
- Implement repository interfaces
- Map API responses to domain entities
- Either<Failure, T> return type
- Location: `lib/features/business_ideation/data/repositories/`

**Phase 4: State Management (BLoCs)** (2 days)
- Create BLoCs for each entity
- Events + States for CRUD operations
- Authentication BLoC for JWT management
- Location: `lib/features/business_ideation/presentation/bloc/`

**Phase 5: UI Integration** (1-2 days)
- Connect UI pages to BLoCs
- Replace local state with API state
- Handle loading/error/success states
- Update worksheet_page to load/save from API

---

## 📁 Full Directory Structure (After Completion)

### API Backend
```
/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-api/
├── cmd/api/main.go                           ← Entry point
├── internal/
│   ├── domain/                               ← Entities + interfaces
│   │   ├── user/
│   │   ├── business/
│   │   ├── valuepropositioncanvas/
│   │   ├── designthinking/
│   │   └── item/
│   ├── command/                              ← Write operations
│   ├── query/                                ← Read operations
│   ├── delivery/http/                        ← HTTP handlers
│   └── eventhandler/                         ← Side effects
├── infrastructure/
│   ├── config/                               ← Configuration
│   ├── database/                             ← Repositories
│   └── telemetry/                            ← Observability
├── pkg/
│   ├── commandbus/
│   ├── querybus/
│   ├── eventbus/
│   ├── hooks/
│   └── middleware/
├── migrations/                               ← SQL migrations
├── docker-compose.yml                        ← Local dev stack
├── Makefile
└── CLAUDE.md                                 ← Architecture guide
```

**Start API:** `make infra-up && make dev`

---

### Flutter Frontend
```
/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app/

lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart                   ✅ Done
│   │   ├── network_info.dart                 ✅ Done
│   │   └── api_constants.dart                ❌ Need to create
│   ├── errors/
│   │   └── failure.dart                      ❌ Need to create
│   └── constants/
│       └── app_constants.dart                ⚠️ Update baseUrl
│
├── features/business_ideation/
│   ├── data/
│   │   ├── models/                           ❌ PHASE 1
│   │   │   ├── business_model.dart
│   │   │   ├── canvas_model.dart
│   │   │   ├── design_thinking_model.dart
│   │   │   ├── item_model.dart
│   │   │   └── auth_response_model.dart
│   │   │
│   │   ├── datasources/                      ❌ PHASE 2
│   │   │   ├── business_remote_datasource.dart
│   │   │   ├── canvas_remote_datasource.dart
│   │   │   ├── design_thinking_remote_datasource.dart
│   │   │   ├── item_remote_datasource.dart
│   │   │   └── auth_remote_datasource.dart
│   │   │
│   │   └── repositories/                     ❌ PHASE 3
│   │       ├── business_repository_impl.dart
│   │       ├── canvas_repository_impl.dart
│   │       ├── design_thinking_repository_impl.dart
│   │       ├── item_repository_impl.dart
│   │       └── auth_repository_impl.dart
│   │
│   ├── domain/
│   │   ├── entities/                         ❌ PHASE 1
│   │   │   ├── business.dart
│   │   │   ├── canvas.dart
│   │   │   ├── design_thinking.dart
│   │   │   ├── item.dart
│   │   │   └── user.dart
│   │   │
│   │   └── repositories/                     ❌ PHASE 3
│   │       ├── business_repository.dart
│   │       ├── canvas_repository.dart
│   │       ├── design_thinking_repository.dart
│   │       ├── item_repository.dart
│   │       └── auth_repository.dart
│   │
│   └── presentation/
│       ├── bloc/                             ❌ PHASE 4
│       │   ├── business_bloc.dart
│       │   ├── business_state.dart
│       │   ├── business_event.dart
│       │   ├── canvas_bloc.dart
│       │   ├── design_thinking_bloc.dart
│       │   ├── item_bloc.dart
│       │   ├── auth_bloc.dart
│       │   └── (state/event files)
│       │
│       ├── pages/
│       │   └── worksheet_page.dart           ⚠️ PHASE 5 - Update
│       │
│       └── widgets/
│           ├── canvas_sticky_note_widget.dart ✅ Done
│           ├── canvas_section_widget.dart     ✅ Done
│           ├── bmc_canvas_widget.dart         ✅ Done
│           ├── vpc_canvas_widget.dart         ✅ Done
│           ├── dt_canvas_widget.dart          ✅ Done
│           ├── pestel_canvas_widget.dart      ✅ Done
│           └── flywheel_canvas_widget.dart    ✅ Done
│
├── docs/
│   ├── INTEGRATION_SYNC_PLAN.md              ✅ NEW - Detailed guide
│   ├── SYNC_STATUS.md                        ✅ NEW - This file
│   ├── FEATURES.md                           ✅ Done
│   ├── ARCHITECTURE.md                       ✅ Done
│   └── api_dev/
│       └── v1.0.0.md                         ✅ Done
│
└── pubspec.yaml                              ⚠️ Add dependencies:
    # Add:
    json_annotation: ^4.8.0
    json_serializable: ^6.7.0
    freezed_annotation: ^2.4.1
    freezed: ^2.4.0
    build_runner: ^2.4.0
    dartz: ^0.10.1  # Either<Failure, T>
    flutter_bloc: ^8.1.0  # Already there?
```

---

## 🚀 Quick Start Commands

### 1. Start Go API
```bash
cd /Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-api

# Setup
go mod download

# Infrastructure (PostgreSQL, Redis, NATS)
make infra-up

# Migrations
make migrate-up

# Run server
make dev

# Check health
curl http://localhost:8080/health
```

### 2. Update Flutter Project

```bash
cd /Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app

# Update app_constants.dart with API URL
# API URL: http://localhost:8080  (local dev)
# Or:      https://api.vernonedu.local (production)

# Add dependencies
flutter pub add json_annotation json_serializable freezed freezed_annotation build_runner dartz

# Generate models (after creating model files)
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run -d chrome

# Or with dev API
# API_URL=http://localhost:8080 flutter run -d chrome
```

---

## 📋 File Checklist

### ✅ Already Complete
- [x] Go API (all endpoints)
- [x] Flutter UI widgets (canvas components)
- [x] API client with Dio
- [x] Documentation (FEATURES.md, ARCHITECTURE.md, api_dev/v1.0.0.md)

### ❌ Need to Create (In Order)

**Priority 1: Setup & Constants**
- [ ] `/lib/core/constants/app_constants.dart` - API base URL + endpoints

**Priority 2: Phase 1 - Models & Entities**
- [ ] `/lib/core/errors/failure.dart` - Error handling
- [ ] `/lib/features/business_ideation/data/models/business_model.dart`
- [ ] `/lib/features/business_ideation/data/models/canvas_model.dart`
- [ ] `/lib/features/business_ideation/data/models/design_thinking_model.dart`
- [ ] `/lib/features/business_ideation/data/models/item_model.dart`
- [ ] `/lib/features/business_ideation/data/models/auth_response_model.dart`
- [ ] `/lib/features/business_ideation/domain/entities/business.dart`
- [ ] `/lib/features/business_ideation/domain/entities/canvas.dart`
- [ ] `/lib/features/business_ideation/domain/entities/design_thinking.dart`
- [ ] `/lib/features/business_ideation/domain/entities/item.dart`
- [ ] `/lib/features/business_ideation/domain/entities/user.dart`

**Priority 3: Phase 2 - Remote Data Sources**
- [ ] `/lib/features/business_ideation/data/datasources/business_remote_datasource.dart`
- [ ] `/lib/features/business_ideation/data/datasources/canvas_remote_datasource.dart`
- [ ] `/lib/features/business_ideation/data/datasources/design_thinking_remote_datasource.dart`
- [ ] `/lib/features/business_ideation/data/datasources/item_remote_datasource.dart`
- [ ] `/lib/features/business_ideation/data/datasources/auth_remote_datasource.dart`

**Priority 4: Phase 3 - Repository Interfaces & Implementations**
- [ ] `/lib/features/business_ideation/domain/repositories/business_repository.dart` (interface)
- [ ] `/lib/features/business_ideation/data/repositories/business_repository_impl.dart`
- [ ] `/lib/features/business_ideation/domain/repositories/canvas_repository.dart` (interface)
- [ ] `/lib/features/business_ideation/data/repositories/canvas_repository_impl.dart`
- [ ] `/lib/features/business_ideation/domain/repositories/design_thinking_repository.dart` (interface)
- [ ] `/lib/features/business_ideation/data/repositories/design_thinking_repository_impl.dart`
- [ ] `/lib/features/business_ideation/domain/repositories/item_repository.dart` (interface)
- [ ] `/lib/features/business_ideation/data/repositories/item_repository_impl.dart`
- [ ] `/lib/features/business_ideation/domain/repositories/auth_repository.dart` (interface)
- [ ] `/lib/features/business_ideation/data/repositories/auth_repository_impl.dart`

**Priority 5: Phase 4 - BLoCs**
- [ ] `/lib/features/business_ideation/presentation/bloc/business_event.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/business_state.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/business_bloc.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/canvas_event.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/canvas_state.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/canvas_bloc.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/design_thinking_event.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/design_thinking_state.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/design_thinking_bloc.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/item_event.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/item_state.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/item_bloc.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/auth_event.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/auth_state.dart`
- [ ] `/lib/features/business_ideation/presentation/bloc/auth_bloc.dart`

**Priority 6: Phase 5 - Update UI**
- [ ] `/lib/features/business_ideation/presentation/pages/worksheet_page.dart` - Update to use BLoCs

---

## 💾 Implementation Paths

| File | Full Path |
|------|-----------|
| Integration Plan | `/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app/docs/INTEGRATION_SYNC_PLAN.md` |
| Sync Status | `/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app/docs/SYNC_STATUS.md` |
| API Spec | `/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app/docs/api_dev/v1.0.0.md` |
| API Backend | `/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-api/` |
| Flutter App | `/Users/erickmo/Desktop/Project/vernonedu/entrepreneurship-ui/vernonedu_entrepreneurship_app/` |

---

## 🎬 Next Actions

**Recommended approach:**

1. **Use `flutter-coding-standard` skill** to generate all models + BLoCs
   - Provide the integration plan document
   - Let AI generate all files following Flutter best practices

2. **Use `go-code-audit` skill** to verify API is production-ready
   - Check API response formats
   - Verify error handling
   - Check JWT implementation

3. **Integration testing** once all layers complete
   - Test CRUD operations end-to-end
   - Verify authentication flow
   - Check error handling

---

**Status: 🟡 Ready to Sync - Waiting for Phase 1 Implementation**
