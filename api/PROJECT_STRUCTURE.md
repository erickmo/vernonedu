# Project Structure Summary

## Generated Files & Directories

### Root Level
```
.env.example                  ← Environment variables example
.gitignore                   ← Git ignore rules
Makefile                     ← Build & development commands
Dockerfile                   ← Docker container build
docker-compose.yml           ← Local development infrastructure
prometheus.yml               ← Prometheus monitoring config
go.mod                       ← Go module definition
CLAUDE.md                    ← Architecture & development guide
PROJECT_STRUCTURE.md         ← This file
```

### `cmd/api/`
```
cmd/api/
└── main.go                  ← Application entry point + FX wiring
```

### `infrastructure/`
```
infrastructure/
├── config/
│   └── config.go            ← Configuration management (Viper)
├── telemetry/
│   ├── otel.go              ← OpenTelemetry tracer setup
│   └── metrics.go           ← Prometheus metrics setup
└── database/
    ├── user_repository.go           ← User repository (PostgreSQL)
    ├── business_repository.go       ← Business repository
    ├── canvas_repository.go         ← Canvas repository
    ├── designthinking_repository.go ← DesignThinking repository
    └── item_repository.go           ← Item repository
```

### `internal/`
```
internal/
├── domain/
│   ├── user/
│   │   ├── user.go          ← User entity + repo interfaces
│   │   └── events.go        ← User domain events
│   ├── business/
│   │   ├── business.go
│   │   └── events.go
│   ├── valuepropositioncanvas/
│   │   ├── valuepropositioncanvas.go
│   │   └── events.go
│   ├── designthinking/
│   │   ├── designthinking.go
│   │   └── events.go
│   └── item/
│       ├── item.go
│       └── events.go
│
├── command/
│   ├── create_user/
│   │   ├── handler.go
│   │   └── errors.go
│   ├── update_user/
│   │   ├── handler.go
│   │   └── errors.go
│   ├── delete_user/
│   │   ├── handler.go
│   │   └── errors.go
│   ├── create_business/
│   ├── update_business/
│   ├── delete_business/
│   ├── create_canvas/
│   ├── update_canvas/
│   ├── delete_canvas/
│   ├── create_designthinking/
│   ├── update_designthinking/
│   ├── delete_designthinking/
│   ├── create_item/
│   ├── update_item/
│   └── delete_item/
│
├── query/
│   ├── get_user/
│   │   ├── handler.go       ← GetUserQuery, UserReadModel, Handler
│   │   └── errors.go
│   ├── list_user/
│   │   ├── handler.go
│   │   └── errors.go
│   ├── search_user/
│   │   ├── handler.go
│   │   └── errors.go
│   ├── get_business/
│   ├── list_business/
│   ├── search_business/
│   ├── get_canvas/
│   ├── list_canvas/
│   ├── search_canvas/
│   ├── get_designthinking/
│   ├── list_designthinking/
│   ├── search_designthinking/
│   ├── get_item/
│   ├── list_item/
│   └── search_item/
│
├── delivery/http/
│   ├── user_handler.go              ← HTTP handlers + routes (User)
│   ├── business_handler.go          ← HTTP handlers + routes (Business)
│   ├── canvas_handler.go            ← HTTP handlers + routes (Canvas)
│   ├── designthinking_handler.go    ← HTTP handlers + routes (DesignThinking)
│   └── item_handler.go              ← HTTP handlers + routes (Item)
│
└── eventhandler/
    ├── user_handlers.go             ← Event handlers (side effects)
    ├── business_handlers.go
    ├── canvas_handlers.go
    ├── designthinking_handlers.go
    └── item_handlers.go
```

### `pkg/`
```
pkg/
├── commandbus/
│   └── commandbus.go        ← Command dispatcher, hooks, decorators
├── querybus/
│   └── querybus.go          ← Query dispatcher
├── eventbus/
│   └── eventbus.go          ← Event pub/sub interface (NATS + InMemory)
├── hooks/
│   └── command_hooks.go     ← Validation, logging hooks
└── middleware/
    └── middleware.go        ← HTTP middleware (logging, tracing, recovery, CORS)
```

### `migrations/`
```
migrations/
├── 001_create_users.sql
├── 002_create_businesses.sql
├── 003_create_value_proposition_canvases.sql
├── 004_create_design_thinkings.sql
└── 005_create_items.sql
```

### `docs/`
```
docs/
└── requirements/
    └── prd-entrepreneurship-api.md  ← Product Requirements Document
```

### `tests/` (Stub)
```
tests/
└── integration/
    └── (Integration tests to be implemented)
```

---

## File Count & Statistics

| Layer | Count | Purpose |
|-------|-------|---------|
| **Domain** | 10 files | Entities + Events (zero deps) |
| **Commands** | 15 files | Command handlers (3 files per entity) |
| **Queries** | 16 files | Query handlers (3 files per entity) |
| **HTTP Handlers** | 5 files | REST API delivery layer |
| **Infrastructure** | 6 files | Database, config, telemetry |
| **Core** | 6 files | CommandBus, QueryBus, EventBus, Middleware, Hooks |
| **Configuration** | 4 files | .env, Dockerfile, docker-compose.yml, Makefile |
| **Documentation** | 3 files | CLAUDE.md, PRD, PROJECT_STRUCTURE.md |
| **Total** | 65+ | Files |

---

## Entities Overview

### 1. User
- **Package:** `internal/domain/user`
- **Commands:** CreateUser, UpdateUser, DeleteUser (3)
- **Queries:** GetUser, ListUser, SearchUser (3)
- **Events:** UserCreated, UserUpdated, UserDeleted (3)

### 2. Business
- **Package:** `internal/domain/business`
- **Commands:** CreateBusiness, UpdateBusiness, DeleteBusiness (3)
- **Queries:** GetBusiness, ListBusiness, SearchBusiness (3)
- **Events:** BusinessCreated, BusinessUpdated, BusinessDeleted (3)

### 3. ValuePropositionCanvas
- **Package:** `internal/domain/valuepropositioncanvas`
- **Commands:** CreateCanvas, UpdateCanvas, DeleteCanvas (3)
- **Queries:** GetCanvas, ListCanvas, SearchCanvas (3)
- **Events:** CanvasCreated, CanvasUpdated, CanvasDeleted (3)

### 4. DesignThinking
- **Package:** `internal/domain/designthinking`
- **Commands:** CreateDT, UpdateDT, DeleteDT (3)
- **Queries:** GetDT, ListDT, SearchDT (3)
- **Events:** DTCreated, DTUpdated, DTDeleted (3)

### 5. Item
- **Package:** `internal/domain/item`
- **Commands:** CreateItem, UpdateItem, DeleteItem (3)
- **Queries:** GetItem, ListItem, SearchItem (3)
- **Events:** ItemCreated, ItemUpdated, ItemDeleted (3)

---

## Technology Stack Placement

| Technology | Location |
|-----------|----------|
| **Chi Router** | `cmd/api/main.go` → `RegisterRoutes()` |
| **Uber FX** | `cmd/api/main.go` → `fx.New()` |
| **PostgreSQL** | `infrastructure/database/` |
| **Redis** | `pkg/eventbus/` (caching ready) |
| **Watermill + NATS** | `pkg/eventbus/eventbus.go` |
| **OpenTelemetry** | `infrastructure/telemetry/` |
| **Prometheus** | `prometheus.yml` + `infrastructure/telemetry/metrics.go` |
| **zerolog** | All packages (structured logging) |
| **go-playground/validator** | `pkg/hooks/command_hooks.go` |

---

## API Routes Summary

All 5 entities follow the same REST pattern:

```
POST   /api/v1/{entities}              → Create
GET    /api/v1/{entities}              → List (paginated)
GET    /api/v1/{entities}/search       → Search by name
GET    /api/v1/{entities}/{id}         → Get by ID
PUT    /api/v1/{entities}/{id}         → Update
DELETE /api/v1/{entities}/{id}         → Delete
```

**Entity Endpoints:**
- `/api/v1/users` (user handler)
- `/api/v1/businesses` (business handler)
- `/api/v1/canvases` (canvas handler)
- `/api/v1/design-thinkings` (design thinking handler)
- `/api/v1/items` (item handler)

---

## Next Steps

1. **Initialize Go modules:**
   ```bash
   go mod download
   ```

2. **Start infrastructure:**
   ```bash
   make infra-up
   ```

3. **Run migrations:**
   ```bash
   make migrate-up
   ```

4. **Start server:**
   ```bash
   make dev
   ```

5. **Test API:**
   ```bash
   curl http://localhost:8080/health
   ```

---

## Architecture Flow

```
User Request
    ↓
HTTP Handler (thin layer, just dispatch)
    ↓
CommandBus / QueryBus (with OTel span + hooks)
    ↓
Command/Query Handler (business logic)
    ↓
Domain Layer (entities, validation)
    ↓
Repository (PostgreSQL write/read)
    ↓
EventBus (publish domain events)
    ↓
EventHandler (side effects)
    ↓
Response
```

---

## Generated By

**Go Project Init Skill** with Clean Architecture + CQRS + Event-Driven Design

**Date:** March 2026
**Version:** 1.0.0
