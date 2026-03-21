# Entrepreneurship API

## Overview

Backend REST API untuk platform VernonEdu. Mengelola seluruh domain: user management, kurikulum, batch kelas, absensi, siswa, enrollment, talent pool, dan entrepreneurship tools.

**Port:** `8081`
**Module:** `github.com/erickmo/vernonedu-entrepreneurship-api`

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

### Core / Auth
| Entity | Commands | Queries |
|--------|----------|---------|
| **User** | Create, Update, Delete | GetByID, List, Search |

### Entrepreneurship
| Entity | Commands | Queries |
|--------|----------|---------|
| **Business** | Create, Update, Delete | GetByID, List, Search |
| **Value Proposition Canvas** | Create, Update, Delete | GetByID, List, Search |
| **Design Thinking** | Create, Update, Delete | GetByID, List, Search |
| **Item** | Create, Update, Delete | GetByID, List, Search |

### Curriculum System
| Entity | Commands | Queries |
|--------|----------|---------|
| **Department** | Create, Update, Delete | GetByID, List |
| **MasterCourse** | Create, Update, Delete, Archive | GetByID, List |
| **CourseType** | Create, Update, Toggle | GetByID, List |
| **CourseVersion** | Create, Promote | GetByID, List |
| **CourseModule** | Create, Update, Delete | GetByID, List |
| **InternshipConfig** | Upsert | Get |
| **CharacterTestConfig** | Upsert | Get |

### Batch & Student Management
| Entity | Commands | Queries |
|--------|----------|---------|
| **CourseBatch** | Create, Update, Delete, UpdateFacilitator | GetByID, GetDetail, List, ListMy |
| **Student** | Create, Update, Delete | GetByID, List |
| **Enrollment** | Create | GetByID, List, ListSummary |

### Attendance
| Entity | Commands | Queries |
|--------|----------|---------|
| **Session** | SubmitTestResult | GetSessions (per batch), GetMySchedule |
| **Attendance Record** | SubmitAttendance | GetAttendanceRecords |

### Talent Pool & Program Karir
| Entity | Commands | Queries |
|--------|----------|---------|
| **TalentPool** | UpdateStatus | GetByID, List |
| **FailureConfig** | Update | — |

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

### Auth (Public)
```
POST   /api/v1/auth/register            → Register user
POST   /api/v1/auth/login               → Login, return JWT
GET    /api/v1/auth/me                  → Current user info (protected)
```

### Users
```
POST   /api/v1/users                    → Create
GET    /api/v1/users                    → List (offset, limit, role?)
GET    /api/v1/users/search?name=xxx    → Search
GET    /api/v1/users/{id}               → GetByID
PUT    /api/v1/users/{id}               → Update
DELETE /api/v1/users/{id}               → Delete
```

### Departments
```
POST   /api/v1/departments                          → Create
GET    /api/v1/departments?offset&limit             → List
GET    /api/v1/departments/summaries                → List summaries
GET    /api/v1/departments/{id}                     → GetByID
PUT    /api/v1/departments/{id}                     → Update
DELETE /api/v1/departments/{id}                     → Delete
GET    /api/v1/departments/{id}/batches             → Batches in department
GET    /api/v1/departments/{id}/courses             → Courses in department
GET    /api/v1/departments/{id}/students?status=active|alumni → Students in department
GET    /api/v1/departments/{id}/talentpool          → Talent pool in department
```

### Curriculum - Master Courses
```
POST   /api/v1/curriculum/courses                   → Create
GET    /api/v1/curriculum/courses?offset&limit&status&field → List
GET    /api/v1/curriculum/courses/{id}              → GetByID
PUT    /api/v1/curriculum/courses/{id}              → Update
POST   /api/v1/curriculum/courses/{id}/archive      → Archive
DELETE /api/v1/curriculum/courses/{id}              → Delete
GET    /api/v1/curriculum/courses/{id}/batches      → Batches using this master course
GET    /api/v1/curriculum/courses/{id}/students     → Students enrolled via this master course
```

### Curriculum - Course Types
```
POST   /api/v1/curriculum/courses/{courseID}/types  → Create type under master course
GET    /api/v1/curriculum/courses/{courseID}/types  → List types under master course
GET    /api/v1/curriculum/types/{typeID}            → GetByID
PUT    /api/v1/curriculum/types/{typeID}            → Update
POST   /api/v1/curriculum/types/{typeID}/toggle     → Toggle active/inactive
```

### Curriculum - Course Versions
```
POST   /api/v1/curriculum/types/{typeID}/versions   → Create version under course type
GET    /api/v1/curriculum/types/{typeID}/versions   → List versions under course type
GET    /api/v1/curriculum/versions/{versionID}      → GetByID
POST   /api/v1/curriculum/versions/{versionID}/promote → Promote to active
```

### Curriculum - Course Modules
```
POST   /api/v1/curriculum/versions/{versionID}/modules  → Create module under version
GET    /api/v1/curriculum/versions/{versionID}/modules  → List modules under version
GET    /api/v1/curriculum/modules/{moduleID}            → GetByID
PUT    /api/v1/curriculum/modules/{moduleID}            → Update
DELETE /api/v1/curriculum/modules/{moduleID}            → Delete
```

### Program Karir
```
PUT    /api/v1/curriculum/versions/{versionID}/internship      → Upsert internship config
GET    /api/v1/curriculum/versions/{versionID}/internship      → Get internship config
PUT    /api/v1/curriculum/versions/{versionID}/character-test  → Upsert character test config
GET    /api/v1/curriculum/versions/{versionID}/character-test  → Get character test config
PUT    /api/v1/curriculum/types/{typeID}/failure-config        → Update failure config
POST   /api/v1/curriculum/versions/{versionID}/submit-test-result → Submit test result
```

### Course Batches
```
POST   /api/v1/course-batches                          → Create
GET    /api/v1/course-batches?offset&limit             → List
GET    /api/v1/course-batches/{id}                     → GetByID
GET    /api/v1/course-batches/{id}/detail              → Full detail (students, modules, sessions)
PUT    /api/v1/course-batches/{id}                     → Update
DELETE /api/v1/course-batches/{id}                     → Delete
PUT    /api/v1/course-batches/{id}/facilitator         → Assign/update facilitator
GET    /api/v1/course-batches/{id}/sessions            → List sessions
```

### Sessions & Attendance
```
GET    /api/v1/sessions/my                                              → My schedule (from=, to=)
GET    /api/v1/course-batches/{batchId}/sessions/{sessionId}/attendance → Get records
POST   /api/v1/course-batches/{batchId}/sessions/{sessionId}/attendance → Submit attendance
```

### Students
```
POST   /api/v1/students                               → Create
GET    /api/v1/students?offset&limit                  → List
GET    /api/v1/students/{id}                          → GetByID
PUT    /api/v1/students/{id}                          → Update
DELETE /api/v1/students/{id}                          → Delete
GET    /api/v1/students/{id}/enrollment-history       → Enrollment history
GET    /api/v1/students/{id}/recommendations          → Department recommendations
GET    /api/v1/students/{id}/notes                    → Student notes
POST   /api/v1/students/{id}/notes                    → Add student note
```

### Enrollments
```
POST   /api/v1/enrollments                            → Create
GET    /api/v1/enrollments?offset&limit               → List (student_id?, course_batch_id?)
GET    /api/v1/enrollments/{id}                       → GetByID
GET    /api/v1/enrollments/summary                    → Summary per batch
```

### Talent Pool
```
GET    /api/v1/talentpool?offset&limit&status&master_course_id → List
GET    /api/v1/talentpool/{id}                        → GetByID
PUT    /api/v1/talentpool/{id}/status                 → Update status
```

### Businesses
```
POST   /api/v1/businesses               → Create
GET    /api/v1/businesses               → List
GET    /api/v1/businesses/search        → Search
GET    /api/v1/businesses/{id}          → GetByID
PUT    /api/v1/businesses/{id}          → Update
DELETE /api/v1/businesses/{id}          → Delete
```

### Value Proposition Canvases
```
POST   /api/v1/canvases                 → Create
GET    /api/v1/canvases                 → List
GET    /api/v1/canvases/search          → Search
GET    /api/v1/canvases/{id}            → GetByID
PUT    /api/v1/canvases/{id}            → Update
DELETE /api/v1/canvases/{id}            → Delete
```

### Design Thinkings
```
POST   /api/v1/design-thinkings         → Create
GET    /api/v1/design-thinkings         → List
GET    /api/v1/design-thinkings/search  → Search
GET    /api/v1/design-thinkings/{id}    → GetByID
PUT    /api/v1/design-thinkings/{id}    → Update
DELETE /api/v1/design-thinkings/{id}    → Delete
```

### Items
```
POST   /api/v1/items                    → Create
GET    /api/v1/items                    → List (worksheet_id required)
GET    /api/v1/items/{id}               → GetByID
PUT    /api/v1/items/{id}               → Update
DELETE /api/v1/items/{id}               → Delete
```

---

## Role System

| Role | Deskripsi |
|------|-----------|
| `admin` | Full access |
| `director` | Course ownership, assign facilitator |
| `course_owner` | Manage courses & batches, assign facilitator |
| `dept_leader` | Department-level access, assign facilitator |
| `facilitator` | Take attendance, view batches |
| `mentor` | Take attendance, view batches |
| `student` | Student-facing features |

---

## Quick Start

### Setup

```bash
cd api
cp .env.example .env    # Edit .env
make infra-up           # Start PostgreSQL, Redis, NATS, Jaeger, Prometheus
make migrate-up         # Run migrations
make dev                # Hot reload (port 8081)
```

---

## Development Commands

```bash
make build              # Build binary
make dev                # Development (hot reload via air)
make test               # Unit tests
make test-race          # With race detector
make test-integration   # Integration tests (testcontainers)
make lint               # Linting
make migrate-up         # Run migrations
make migrate-down       # Rollback migrations
make migrate-create name=xxx  # Create new migration
make infra-up           # Start Docker services
make infra-down         # Stop Docker services
make tidy               # Clean up go.mod
```

---

## Key Architecture Rules

### Adding a New Command

```
1. internal/domain/{entity}/  → struct + constructor + events + repository interface
2. internal/command/{action}_{entity}/ → command.go + handler.go
3. infrastructure/database/{entity}_repository.go → WriteRepository impl
4. internal/delivery/http/{entity}_handler.go → HTTP handler
5. cmd/api/main.go → FX wire
6. migrations/ → SQL migration if new table
```

### Adding a New Query

```
1. internal/query/get_{entity}/ → query.go + handler.go
2. internal/query/list_{entity}/ → query.go + handler.go
3. infrastructure/database/{entity}_repository.go → ReadRepository impl
```

---

## Important Notes

⚠️ **Sebelum Development:**
1. Jalankan `make infra-up` DULU!
2. Tunggu semua service healthy (5-10 detik)

⚠️ **Database:**
- Migrations ada di `migrations/` (001–024)
- Gunakan `make migrate-create name=xxx` untuk migration baru
- Test selalu pakai real DB (testcontainers)

⚠️ **Event Publishing:**
- Setiap command WAJIB publish domain event setelah berhasil
- InMemory fallback aktif jika NATS tidak tersedia

---

## Monitoring

| Service | URL |
|---------|-----|
| API | http://localhost:8081 |
| Jaeger | http://localhost:16686 |
| Prometheus | http://localhost:9090 |

---

**Last Updated:** Maret 2026
