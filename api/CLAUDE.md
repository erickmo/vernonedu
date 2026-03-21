# VernonEdu API — CLAUDE.md

> Backend REST API. Go + Clean Architecture + CQRS + Event-Driven.
> **Port:** `8081`
> **Module:** `github.com/erickmo/vernonedu-entrepreneurship-api`
> **Domain specs:** See `docs/` for detailed specs per domain.

---

## Architecture

**Pattern:** Clean Architecture + CQRS + Event-Driven

```
HTTP Request → HTTP Handler (thin) → CommandBus/QueryBus → Handler → Repository → DB
                                      ↓ (after success)
                                   EventBus → Event Handlers (async side effects)
```

### Tech Stack

| Layer | Technology |
|---|---|
| Router | Chi v5 |
| DI | Uber FX |
| Event Bus | Watermill + NATS JetStream |
| DB Write | PostgreSQL + sqlx |
| DB Read | PostgreSQL + Redis cache |
| Logging | zerolog (structured) |
| Observability | OpenTelemetry → Jaeger + Prometheus |
| Validation | go-playground/validator |
| Testing | testcontainers-go |

---

## Project Structure

```
cmd/api/                      ← Entry point, FX wiring
internal/
  domain/{entity}/           ← Entity + events + repo interfaces (ZERO external deps)
  command/{action}_{entity}/ ← Command handlers (1 folder per command)
  query/{action}_{entity}/   ← Query handlers (1 folder per query)
  eventhandler/              ← Domain event handlers (side effects + finance hooks)
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
  middleware/                ← HTTP middleware (auth, logging, tracing, recovery)
migrations/                  ← SQL migrations
tests/integration/           ← Integration tests (testcontainers)
```

---

## Role System

### Staff Roles

| Key | Description |
|---|---|
| `director` | Full access |
| `education_leader` | All education domains |
| `dept_leader` | Department scope |
| `course_owner` | Course + batch + enrollment |
| `facilitator` | Assigned batches + attendance |
| `operation_leader` | Operations domains |
| `operation_admin` | Batch creation, scheduling, location |
| `customer_service` | Students + enrollment + payment |
| `marketing` | CRM + ads + leads + referral |
| `accounting_leader` | All financial |
| `accounting_staff` | Accounting operations |

### External Roles

| Key | Description |
|---|---|
| `student` | Student features (app-student + supporting apps) |
| `partner` | External partner (no app access yet) |

> **Note:** A single user can hold multiple roles.
> **Removed:** `admin` (replaced by `director`), `mentor` (merged into `facilitator`)

---

## API Endpoints

### Auth (Public)
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login               → returns JWT + user (with roles[])
GET    /api/v1/auth/me
```

### Users
```
POST   /api/v1/users
GET    /api/v1/users                     ?offset, limit, role?
GET    /api/v1/users/search?name=xxx
GET    /api/v1/users/{id}
PUT    /api/v1/users/{id}
DELETE /api/v1/users/{id}
```

### Departments
```
POST   /api/v1/departments
GET    /api/v1/departments               ?offset, limit
GET    /api/v1/departments/summaries
GET    /api/v1/departments/{id}
PUT    /api/v1/departments/{id}
DELETE /api/v1/departments/{id}
GET    /api/v1/departments/{id}/batches
GET    /api/v1/departments/{id}/courses
GET    /api/v1/departments/{id}/students ?status=active|alumni
GET    /api/v1/departments/{id}/talentpool
```

### Curriculum — Master Courses
```
POST   /api/v1/curriculum/courses
GET    /api/v1/curriculum/courses        ?offset, limit, status, field, department_id
GET    /api/v1/curriculum/courses/{id}
PUT    /api/v1/curriculum/courses/{id}
POST   /api/v1/curriculum/courses/{id}/archive
DELETE /api/v1/curriculum/courses/{id}
GET    /api/v1/curriculum/courses/{id}/batches
GET    /api/v1/curriculum/courses/{id}/students
```

### Curriculum — Course Types
```
POST   /api/v1/curriculum/courses/{courseID}/types
GET    /api/v1/curriculum/courses/{courseID}/types
GET    /api/v1/curriculum/types/{typeID}
PUT    /api/v1/curriculum/types/{typeID}      body includes: normalPrice, minPrice, minParticipants, maxParticipants
POST   /api/v1/curriculum/types/{typeID}/toggle
```

### Curriculum — Course Versions
```
POST   /api/v1/curriculum/types/{typeID}/versions
GET    /api/v1/curriculum/types/{typeID}/versions
GET    /api/v1/curriculum/versions/{versionID}
POST   /api/v1/curriculum/versions/{versionID}/promote
POST   /api/v1/curriculum/versions/propose      body: {courseTypeId, modules[]}  → creates approval
```

### Curriculum — Course Modules
```
POST   /api/v1/curriculum/versions/{versionID}/modules    body includes: tools[], requirements[]
GET    /api/v1/curriculum/versions/{versionID}/modules
GET    /api/v1/curriculum/modules/{moduleID}
PUT    /api/v1/curriculum/modules/{moduleID}
DELETE /api/v1/curriculum/modules/{moduleID}
```

### Program Karir
```
PUT    /api/v1/curriculum/versions/{versionID}/internship
GET    /api/v1/curriculum/versions/{versionID}/internship
PUT    /api/v1/curriculum/versions/{versionID}/character-test
GET    /api/v1/curriculum/versions/{versionID}/character-test
PUT    /api/v1/curriculum/types/{typeID}/failure-config
POST   /api/v1/curriculum/versions/{versionID}/submit-test-result
```

### Course Batches
```
POST   /api/v1/course-batches                 body includes: pricing, paymentMethod, minStudents, maxStudents, websiteVisible
GET    /api/v1/course-batches                 ?offset, limit, status?, course_id?
GET    /api/v1/course-batches/{id}
GET    /api/v1/course-batches/{id}/detail
PUT    /api/v1/course-batches/{id}
DELETE /api/v1/course-batches/{id}
PUT    /api/v1/course-batches/{id}/facilitator
GET    /api/v1/course-batches/{id}/sessions
GET    /api/v1/course-batches/{id}/schedules
POST   /api/v1/course-batches/{id}/schedules  body: {moduleId, roomId, scheduledAt, duration}
GET    /api/v1/course-batches/{id}/budget
```

### Sessions & Attendance
```
GET    /api/v1/sessions/my                    ?from=YYYY-MM-DD&to=YYYY-MM-DD
GET    /api/v1/course-batches/{batchId}/sessions/{sessionId}/attendance
POST   /api/v1/course-batches/{batchId}/sessions/{sessionId}/attendance
```

### Students
```
POST   /api/v1/students
GET    /api/v1/students                       ?offset, limit
GET    /api/v1/students/{id}
PUT    /api/v1/students/{id}
DELETE /api/v1/students/{id}
GET    /api/v1/students/{id}/enrollment-history
GET    /api/v1/students/{id}/recommendations
GET    /api/v1/students/{id}/notes
POST   /api/v1/students/{id}/notes
GET    /api/v1/students/{id}/crm-logs
POST   /api/v1/students/{id}/crm-logs
```

### Enrollments
```
POST   /api/v1/enrollments                    → triggers auto-invoice + referral commission
GET    /api/v1/enrollments                    ?offset, limit, student_id?, course_batch_id?
GET    /api/v1/enrollments/{id}
GET    /api/v1/enrollments/summary
```

### Talent Pool
```
GET    /api/v1/talentpool                     ?offset, limit, status, master_course_id, participant_id
GET    /api/v1/talentpool/{id}
PUT    /api/v1/talentpool/{id}/status
GET    /api/v1/talentpool/professions
POST   /api/v1/talentpool/professions
PUT    /api/v1/talentpool/professions/{id}
DELETE /api/v1/talentpool/professions/{id}
```

### Location (Buildings & Rooms)
```
GET    /api/v1/buildings                      ?offset, limit
GET    /api/v1/buildings/{id}
POST   /api/v1/buildings
PUT    /api/v1/buildings/{id}
DELETE /api/v1/buildings/{id}
GET    /api/v1/rooms                          ?building_id
GET    /api/v1/rooms/{id}
POST   /api/v1/rooms                          body includes: facilities[]
PUT    /api/v1/rooms/{id}
DELETE /api/v1/rooms/{id}
GET    /api/v1/rooms/{id}/availability        ?from, to
```

### Approvals
```
GET    /api/v1/approvals                      ?status=pending&approver_id=me
GET    /api/v1/approvals/{id}
POST   /api/v1/approvals
PUT    /api/v1/approvals/{id}/approve
PUT    /api/v1/approvals/{id}/reject
PUT    /api/v1/approvals/{id}/cancel
```

### Notifications
```
GET    /api/v1/notifications                  ?offset, limit, read?, type?
GET    /api/v1/notifications/unread-count
PUT    /api/v1/notifications/{id}/read
PUT    /api/v1/notifications/read-all
```

### Certificates
```
POST   /api/v1/certificates
GET    /api/v1/certificates                   ?student_id?, batch_id?, type?
GET    /api/v1/certificates/{id}
POST   /api/v1/certificates/{id}/revoke
GET    /api/v1/certificates/verify/{code}     ← public, no auth
```

### Finance — Invoices
```
GET    /api/v1/finance/invoices               ?status, batch_id, student_id
GET    /api/v1/finance/invoices/{id}
POST   /api/v1/finance/invoices               (manual)
PUT    /api/v1/finance/invoices/{id}/pay
PUT    /api/v1/finance/invoices/{id}/cancel
```

### Finance — Payables
```
GET    /api/v1/finance/payables               ?type, status, batch_id
GET    /api/v1/finance/payables/{id}
PUT    /api/v1/finance/payables/{id}/pay
```

### Finance — Transactions & Journal
```
GET    /api/v1/finance/transactions           ?type, account, branch_id, source
POST   /api/v1/finance/transactions
GET    /api/v1/finance/journal                ?account, source, date_range
```

### Finance — Chart of Accounts
```
GET    /api/v1/finance/coa                    → tree
GET    /api/v1/finance/coa/{id}
POST   /api/v1/finance/coa
PUT    /api/v1/finance/coa/{id}
```

### Finance — Reports
```
GET    /api/v1/finance/reports/balance-sheet   ?period, branch_id
GET    /api/v1/finance/reports/profit-loss     ?period, branch_id
GET    /api/v1/finance/reports/cash-flow       ?period, branch_id
GET    /api/v1/finance/reports/ledger          ?account, period
GET    /api/v1/finance/reports/trial-balance   ?period, branch_id
```

### Finance — Analysis
```
GET    /api/v1/finance/analysis/ratios         ?period, branch_id
GET    /api/v1/finance/analysis/revenue        ?period, branch_id, group_by
GET    /api/v1/finance/analysis/costs          ?period, branch_id, group_by
GET    /api/v1/finance/analysis/batch-profit   ?period, branch_id, sort, limit
GET    /api/v1/finance/analysis/cash-forecast  ?months, branch_id
GET    /api/v1/finance/analysis/alerts
GET    /api/v1/finance/analysis/suggestions
```

### Company Settings (Director)
```
GET    /api/v1/settings/commission
PUT    /api/v1/settings/commission
GET    /api/v1/settings/facilitator-levels
PUT    /api/v1/settings/facilitator-levels
GET    /api/v1/settings/branches
POST   /api/v1/settings/branches
PUT    /api/v1/settings/branches/{id}
GET    /api/v1/settings/holidays               ?year
POST   /api/v1/settings/holidays
DELETE /api/v1/settings/holidays/{id}
```

### Leads
```
GET    /api/v1/leads                           ?offset, limit, status, source, interest
GET    /api/v1/leads/{id}
POST   /api/v1/leads
PUT    /api/v1/leads/{id}
DELETE /api/v1/leads/{id}
POST   /api/v1/leads/{id}/convert              → creates student
GET    /api/v1/leads/{id}/crm-logs
POST   /api/v1/leads/{id}/crm-logs
```

### Marketing
```
GET    /api/v1/marketing/posts                 ?platform, status, month
GET    /api/v1/marketing/posts/{id}
POST   /api/v1/marketing/posts
PUT    /api/v1/marketing/posts/{id}
PUT    /api/v1/marketing/posts/{id}/submit-url
DELETE /api/v1/marketing/posts/{id}
GET    /api/v1/marketing/class-docs            → auto-scheduled documentation posts
GET    /api/v1/marketing/pr                    ?status, type
POST   /api/v1/marketing/pr
PUT    /api/v1/marketing/pr/{id}
DELETE /api/v1/marketing/pr/{id}
GET    /api/v1/marketing/referral-partners     ?status
GET    /api/v1/marketing/referral-partners/{id}
POST   /api/v1/marketing/referral-partners
PUT    /api/v1/marketing/referral-partners/{id}
GET    /api/v1/marketing/referral-partners/{id}/referrals
```

### Partners & MOU
```
GET    /api/v1/partners                        ?offset, limit, is_active, group_id
GET    /api/v1/partners/{id}
POST   /api/v1/partners
PUT    /api/v1/partners/{id}
DELETE /api/v1/partners/{id}
GET    /api/v1/partners/{id}/mous
POST   /api/v1/partners/{id}/mous
PUT    /api/v1/mous/{id}
DELETE /api/v1/mous/{id}
GET    /api/v1/mous/expiring                   ?within_months=3
GET    /api/v1/partner-groups
POST   /api/v1/partner-groups
PUT    /api/v1/partner-groups/{id}
```

### CMS (Website Content Management)
```
# Pages (home, program pages, segment pages)
GET    /api/v1/cms/pages                       ?type
GET    /api/v1/cms/pages/{slug}
PUT    /api/v1/cms/pages/{slug}                body: {title, subtitle, content JSON, seo{}}

# Testimonials
GET    /api/v1/cms/testimonials                ?course_id, is_featured
POST   /api/v1/cms/testimonials
PUT    /api/v1/cms/testimonials/{id}
DELETE /api/v1/cms/testimonials/{id}

# FAQ
GET    /api/v1/cms/faq                         ?category, page_slug
POST   /api/v1/cms/faq
PUT    /api/v1/cms/faq/{id}
DELETE /api/v1/cms/faq/{id}

# Blog / Articles
GET    /api/v1/cms/articles                    ?offset, limit, category, status
GET    /api/v1/cms/articles/{slug}
POST   /api/v1/cms/articles
PUT    /api/v1/cms/articles/{id}
DELETE /api/v1/cms/articles/{id}

# Media (images, files)
POST   /api/v1/cms/media/upload
GET    /api/v1/cms/media                       ?type
DELETE /api/v1/cms/media/{id}

# SEO settings
GET    /api/v1/cms/seo/{page_slug}
PUT    /api/v1/cms/seo/{page_slug}

# Public endpoints (no auth — consumed by app-website)
GET    /api/v1/public/courses                  → visible courses with types + pricing
GET    /api/v1/public/courses/{id}             → course detail + available batches
GET    /api/v1/public/batches/{id}             → batch detail + schedule
GET    /api/v1/public/pages/{slug}             → page content
GET    /api/v1/public/testimonials             ?course_id, limit
GET    /api/v1/public/faq                      ?category
GET    /api/v1/public/articles                 ?offset, limit, category
GET    /api/v1/public/articles/{slug}
GET    /api/v1/public/stats                    → aggregate stats (student count, course count, etc.)
POST   /api/v1/public/enrollment               → public enrollment (creates student + enrollment)
POST   /api/v1/public/contact                  → contact form submission
GET    /api/v1/public/certificates/{code}      → certificate verification
```

### Entrepreneurship Tools
```
POST   /api/v1/businesses               → Create
GET    /api/v1/businesses               → List
GET    /api/v1/businesses/search        → Search
GET    /api/v1/businesses/{id}          → GetByID
PUT    /api/v1/businesses/{id}          → Update
DELETE /api/v1/businesses/{id}          → Delete

POST   /api/v1/canvases                 → (same CRUD pattern)
GET    /api/v1/canvases...
POST   /api/v1/design-thinkings        → (same CRUD pattern)
GET    /api/v1/design-thinkings...
POST   /api/v1/items                   → (same CRUD pattern)
GET    /api/v1/items...
```

### HRM
```
GET    /api/v1/hrm/sdm                 → employee list
GET    /api/v1/hrm/sdm/{id}            → employee detail
```

### Delegations
```
GET    /api/v1/delegations              ?type, status, assigned_to
POST   /api/v1/delegations
PUT    /api/v1/delegations/{id}
PUT    /api/v1/delegations/{id}/accept
PUT    /api/v1/delegations/{id}/complete
PUT    /api/v1/delegations/{id}/cancel
```

---

## Event-Driven Hooks (Finance Automation)

| Event | Side Effect |
|---|---|
| `EnrollmentCreatedEvent` | Auto-create invoice(s) + journal entry. If referral → create marketing partner AP |
| `AttendanceSubmittedEvent` | Create facilitator AP. If per_session → create student invoice |
| `BatchCompletedEvent` | Create commission APs (course creator, dept leader, op leader) + journal entries |
| `InvoicePaidEvent` | Journal entry (cash/bank debit, piutang credit) |
| `PayablePaidEvent` | Journal entry (hutang debit, cash/bank credit) |
| `SessionCompletedEvent` | Auto-schedule class documentation post (2 days later, +1 if holiday) |
| `MouExpiringEvent` (cron) | Notification 3 months before MOU expiry |
| `InvoiceOverdueEvent` (cron) | Notification + revoke supporting app access if scheduled payment |

---

## Key Architecture Rules (WAJIB)

1. Domain Layer → ZERO external dependencies
2. Command Handler → only WriteRepository + EventBus
3. Query Handler → only ReadRepository + Redis
4. HTTP Handler → only dispatch to Bus (NO business logic)
5. Repository interfaces in domain, implementations in infrastructure
6. Event publishing after every successful command
7. Tracing → every command/query auto-inject OTel span
8. Validation → in CommandBus hook (BEFORE handler executes)

---

## Quick Start

```bash
cd api
cp .env.example .env
make infra-up            # PostgreSQL, Redis, NATS, Jaeger, Prometheus
make migrate-up          # Run all migrations + seed CoA
make dev                 # Hot reload (port 8081)
```

## Commands

```bash
make build               make dev                make test
make test-race           make test-integration   make lint
make migrate-up          make migrate-down       make migrate-create name=xxx
make infra-up            make infra-down         make tidy
```

## Monitoring

| Service | URL |
|---|---|
| API | http://localhost:8081 |
| Jaeger | http://localhost:16686 |
| Prometheus | http://localhost:9090 |

---

## Docs Index

| Doc | Path | Content |
|---|---|---|
| Curriculum System | `docs/curriculum-system.md` | Hierarchy, versioning, program karir flow |
| Entrepreneurship PRD | `docs/requirements/prd-entrepreneurship-api.md` | Original PRD |
| API Audit | `docs/audit/` | Code quality audits |

---

**Last Updated:** Maret 2026
