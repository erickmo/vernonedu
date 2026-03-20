# Entrepreneurship API

## Overview

Entrepreneurship API adalah backend REST API untuk platform entrepreneurship Vernon Edu. Service ini dibangun dengan Clean Architecture + CQRS + Event-Driven architecture untuk scalability dan maintainability maksimal.

**Status:** Production Ready (v1.0.0)
**Module:** `github.com/erickmo/vernonedu-entrepreneurship-api`
**PRD:** `docs/requirements/prd-entrepreneurship-api.md`

---

## Architecture

### Pattern
- **Clean Architecture** → Separation of concerns (Domain, Application, Infrastructure, Delivery)
- **CQRS** → Separate Read (Query) dan Write (Command) models
- **Event-Driven** → Domain events untuk async side effects & integration

### Tech Stack
| Layer | Technology |
|-------|-----------|
| **API Router** | Chi v5 |
| **Dependency Injection** | Uber FX |
| **Event Bus** | Watermill + NATS JetStream |
| **DB Write** | PostgreSQL + sqlx |
| **DB Read** | PostgreSQL + Redis cache |
| **Logging** | zerolog (structured) |
| **Observability** | OpenTelemetry (tracing + metrics) |
| **Validation** | go-playground/validator |
| **Testing** | testcontainers-go |

---

## Project Structure

```
cmd/api/                      ← Entry point, FX wiring
internal/
  domain/{entity}/           ← Entity + events + repo interfaces (ZERO external deps)
  command/{action}_{entity}/ ← Command handlers (1 folder per command)
  query/{action}_{entity}/   ← Query handlers (1 folder per query)
  eventhandler/              ← Domain event handlers (side effects)
  delivery/http/             ← HTTP handlers (thin layer)
infrastructure/
  database/                  ← PostgreSQL + sqlx repositories
  config/                    ← Configuration management
  telemetry/                 ← OTel + Prometheus setup
pkg/
  commandbus/                ← CQRS command dispatcher + hooks
  querybus/                  ← CQRS query dispatcher
  eventbus/                  ← Event pub/sub (NATS + InMemory fallback)
  hooks/                     ← Command validation + logging hooks
  middleware/                ← HTTP middleware (logging, tracing, recovery)
migrations/                  ← SQL migration files
tests/integration/           ← Integration tests (testcontainers)
```

---

## Entities & CRUD Operations

| Entity | Commands | Queries |
|--------|----------|---------|
| **User** | Create, Update, Delete | GetByID, List, Search |
| **Business** | Create, Update, Delete | GetByID, List, Search |
| **Value Proposition Canvas** | Create, Update, Delete | GetByID, List, Search |
| **Design Thinking** | Create, Update, Delete | GetByID, List, Search |
| **Item** | Create, Update, Delete | GetByID, List, Search |

---

## Key Architecture Rules (WAJIB)

1. **Domain Layer** → ZERO external dependencies (hanya stdlib + uuid)
2. **Command Handler** → Hanya depend ke WriteRepository + EventBus
3. **Query Handler** → Hanya depend ke ReadRepository + Redis
4. **HTTP Handler** → Hanya dispatch ke CommandBus/QueryBus (NO business logic)
5. **Repository Interfaces** → Defined di domain, implemented di infrastructure
6. **Event Publishing** → Setelah setiap command berhasil
7. **Tracing** → Setiap command/query auto-inject OTel span
8. **Validation** → Di CommandBus hook (SEBELUM handler execute)

---

## API Endpoints

### Users
```
POST   /api/v1/users                 → Create
GET    /api/v1/users                 → List (offset=0, limit=10)
GET    /api/v1/users/search?name=xxx → Search
GET    /api/v1/users/{id}            → GetByID
PUT    /api/v1/users/{id}            → Update
DELETE /api/v1/users/{id}            → Delete
```

### Businesses
```
POST   /api/v1/businesses            → Create
GET    /api/v1/businesses            → List
GET    /api/v1/businesses/search     → Search
GET    /api/v1/businesses/{id}       → GetByID
PUT    /api/v1/businesses/{id}       → Update
DELETE /api/v1/businesses/{id}       → Delete
```

### Value Proposition Canvases
```
POST   /api/v1/canvases              → Create
GET    /api/v1/canvases              → List
GET    /api/v1/canvases/search       → Search
GET    /api/v1/canvases/{id}         → GetByID
PUT    /api/v1/canvases/{id}         → Update
DELETE /api/v1/canvases/{id}         → Delete
```

### Design Thinkings
```
POST   /api/v1/design-thinkings      → Create
GET    /api/v1/design-thinkings      → List
GET    /api/v1/design-thinkings/search → Search
GET    /api/v1/design-thinkings/{id} → GetByID
PUT    /api/v1/design-thinkings/{id} → Update
DELETE /api/v1/design-thinkings/{id} → Delete
```

### Items
```
POST   /api/v1/items                 → Create
GET    /api/v1/items                 → List
GET    /api/v1/items/search          → Search
GET    /api/v1/items/{id}            → GetByID
PUT    /api/v1/items/{id}            → Update
DELETE /api/v1/items/{id}            → Delete
```

---

## Quick Start

### Prerequisites
- Go 1.23+
- Docker & Docker Compose
- PostgreSQL 16+
- Redis 7+
- NATS 2.10+

### Setup

1. **Clone repo & install dependencies:**
   ```bash
   git clone <repo>
   cd entrepreneurship-api
   go mod download
   ```

2. **Start infrastructure:**
   ```bash
   make infra-up
   ```
   Service siap di:
   - **API:** http://localhost:8080
   - **Jaeger:** http://localhost:16686
   - **Prometheus:** http://localhost:9090

3. **Copy .env:**
   ```bash
   cp .env.example .env
   ```

4. **Run migrations:**
   ```bash
   make migrate-up
   ```

5. **Start server:**
   ```bash
   make dev    # Hot reload
   # atau
   make build && ./bin/entrepreneurship-api
   ```

---

## Development Commands

```bash
# Build
make build

# Development (hot reload dengan air)
make dev

# Testing
make test              # Unit tests
make test-race         # With race detector
make test-integration  # Integration tests

# Linting
make lint

# Database migrations
make migrate-up
make migrate-down
make migrate-create name=add_new_field

# Infrastructure
make infra-up          # Start Docker services
make infra-down        # Stop Docker services

# Utility
make tidy              # Clean up go.mod
```

---

## Key Features

✅ **CQRS with Command & Query Buses**
- Separate write (command) dan read (query) paths
- Validation hooks di command pipeline
- Auto OTel tracing per command/query

✅ **Event-Driven Architecture**
- Domain events published setiap command berhasil
- Event handlers untuk side effects
- NATS JetStream untuk persistence

✅ **Production Observability**
- OpenTelemetry tracing (Jaeger backend)
- Prometheus metrics
- Structured logging (zerolog)
- Request/response latency tracking

✅ **Scalable Database**
- PostgreSQL write path
- Redis caching untuk query results
- Efficient pagination support

✅ **Clean Code**
- Layer separation (domain → command → infrastructure)
- Interface-based design
- Dependency injection via Uber FX

---

## Important Notes

⚠️ **Sebelum Development:**
1. Jalankan `make infra-up` DULU!
2. Tunggu semua service healthy (5-10 detik)
3. Check Jaeger UI untuk verifikasi tracing

⚠️ **Saat Membuat Command/Query Baru:**
1. Define domain entity (di `internal/domain/{entity}`)
2. Buat command handler (di `internal/command/{action}_{entity}`)
3. Buat query handler (di `internal/query/{action}_{entity}`)
4. Register di FX `cmd/api/main.go`
5. Buat HTTP handler (di `internal/delivery/http`)
6. Test dengan `make test-integration`

⚠️ **Database:**
- Migrations auto-run saat server start
- Gunakan `make migrate-create name=xxx` untuk new migrations
- Test selalu pakai real DB (testcontainers)

---

## Monitoring & Observability

**Jaeger Tracing:** http://localhost:16686
- Lihat request flow, latency, errors per span
- Search by service, operation, tags

**Prometheus:** http://localhost:9090
- Request count, latency percentiles
- Command/query execution time
- Error rates

**Logs:**
- Semua log via zerolog → stdout
- Structured JSON format
- Trace ID correlation included

---

## Troubleshooting

### Service tidak start?
```bash
# Check .env values
cat .env

# Check database connection
psql -h localhost -U postgres -d entrepreneurship_db

# Check logs
# Lihat output dari make dev
```

### Migrations failed?
```bash
# Manual check
migrate -path migrations -database "$DATABASE_URL" version

# Reset (development only!)
migrate -path migrations -database "$DATABASE_URL" drop
make migrate-up
```

### OTel not connected?
- Jaeger UI di http://localhost:16686
- Verify `OTEL_EXPORTER_OTLP_ENDPOINT` di .env
- Check `infra-up` all containers running

---

## Git Workflow

```bash
# Feature branch
git checkout -b feature/add-user-authentication

# Make changes → test locally
make test
make test-race

# Commit with good message
git commit -m "feat: add user authentication command"

# Create PR
git push origin feature/add-user-authentication
```

---

## Resources

- **API Docs:** (Akan ditambah Swagger/OpenAPI)
- **Postman Collection:** `docs/postman/entrepreneurship-api.json`
- **Architecture Decision Records:** `docs/adr/`
- **Technical Design:** `docs/design/`

---

## Support

Untuk bantuan development, lihat:
1. `docs/requirements/prd-entrepreneurship-api.md` → Feature spec
2. Architecture di `internal/domain` → Business rules
3. Tests di `tests/integration` → Usage examples

---

**Last Updated:** March 2026
**Maintained By:** AI-Generated (Based on Go Project Init Skill)
