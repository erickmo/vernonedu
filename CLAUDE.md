# VernonEdu — System CLAUDE.md

> Root-level guide. Dibaca otomatis oleh Claude Code di setiap sesi.
> Per-project detail ada di masing-masing subfolder `CLAUDE.md`.

---

## Apa itu VernonEdu?

Platform pendidikan yang mengelola:
1. **Kurikulum** — MasterCourse → CourseType → CourseVersion → CourseModule
2. **Kelas (Batch)** — Jadwal, lokasi, fasilitator, siswa, sesi, absensi, budgeting
3. **Enrollment & Payment** — Pendaftaran siswa, 5 metode pembayaran, auto-invoice
4. **Sertifikat** — Certificate of Participant & Competency, template A4, QR verification, revocation
5. **Talent Pool** — Pipeline Program Karir: learning → internship → recommendation → test → talent pool
6. **Entrepreneurship Tools** — Business Canvas, Design Thinking, Block Coding
7. **Accounting** — Bank/cash transactions, budgeting per batch, financial reports
8. **Notification Center** — In-app, push, email, WhatsApp/SMS

---

## Monorepo Structure

```
vernonedu/
├── api/                  ← Backend REST API (Go) — port 8081
├── app-entrepreneur/     ← Flutter Web PWA (Siswa — entrepreneurship) — port 3000
├── app-dashboard/        ← Flutter Web (Admin, staff internal) — port 3001
├── app-blockcoding/      ← Flutter Web (Block Coding IDE) — port 3002
├── app-mentors/          ← Flutter Mobile (Fasilitator) — port N/A
├── app-student/          ← Flutter Mobile (Siswa — base app) — port N/A
├── app-mcb-junior/       ← Flutter (MCB Junior)
├── app-website/          ← Flutter Web (Website publik + certificate verification)
└── docs/                 ← Dokumentasi developer lengkap
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **API** | Go, Chi v5, Clean Architecture + CQRS + Event-Driven |
| **DI (API)** | Uber FX |
| **DB** | PostgreSQL (write) + Redis (read cache) |
| **Events** | NATS JetStream (Watermill) |
| **Observability** | OpenTelemetry → Jaeger, Prometheus, zerolog |
| **Flutter Apps** | Flutter/Dart, BLoC/Cubit, go_router, get_it, Dio, dartz |
| **Auth** | JWT (Bearer token) |
| **Storage (Flutter)** | shared_preferences (web + mobile compat) |
| **Notifications** | In-app, Push (FCM), Email, WhatsApp/SMS |

---

## Organization Chart

```
Director
├── Education Leader
│   └── Department Leader          ← assigned by Education Leader, approved by Director
│       └── Course Owner / Creator
│           └── Facilitator
├── Operation Leader
│   ├── Operation Administrator
│   ├── Customer Service
│   └── Marketing Team
└── Accounting Leader
    └── Accounting Staff
```

> **Note:** A single employee can hold multiple roles.

---

## Role System

### Staff Roles (app-dashboard)

| Role Key | Label | Reports To | Scope |
|----------|-------|------------|-------|
| `director` | Direktur | — | Full access |
| `education_leader` | Education Leader | Director | All education domains |
| `dept_leader` | Kepala Departemen | Education Leader | Department scope |
| `course_owner` | Course Owner | Dept Leader | Course + batch + enrollment |
| `facilitator` | Fasilitator | Course Owner | Assigned batches + attendance |
| `operation_leader` | Operation Leader | Director | Operations domains |
| `operation_admin` | Operation Administrator | Operation Leader | Batch creation, scheduling, location |
| `customer_service` | Customer Service | Operation Leader | Students + enrollment + payment |
| `marketing` | Marketing Team | Operation Leader | CRM + ads templates |
| `accounting_leader` | Accounting Leader | Director | All accounting/financial |
| `accounting_staff` | Accounting Staff | Accounting Leader | Accounting operations |

### External Roles (non-staff)

| Role Key | Label | App |
|----------|-------|-----|
| `student` | Siswa (Customer) | app-student + supporting apps (conditional) |
| `partner` | Partner | None yet |

---

## Domain Model

```
Organization (Franchise Model — all financials are branch-based)
  Director → Education Leader → Department Leader → Course Owner → Facilitator
  Director → Operation Leader → Op Admin, CS, Marketing
  Director → Accounting Leader → Accounting Staff

Department
  └──< MasterCourse (template kurikulum)
         └──< CourseType (Program Karir, Reguler, Privat, Kolaborasi Sekolah/Univ, Inhouse)
         │      ├── pricing: normal_price + min_price
         │      ├── min/max participants
         │      └──< CourseVersion (versi silabus, approved by Dept Leader)
         │             └──< CourseModule (unit pembelajaran)
         │                    ├── tools[] (tools needed for session)
         │                    └── requirements[] (prerequisites)
         ├── InternshipConfig (for Program Karir)
         ├── CharacterTestConfig (for Program Karir)
         ├── CertificateTemplate (A4, auto-generate)
         └── SupportingApp? (e.g. app-entrepreneur, app-blockcoding)

CourseBatch (kelas nyata)
  ├── course_type → CourseType
  ├── facilitator → User (level-based fee per session, max 2hr)
  ├── pricing (within normal–min range, overridable by Dept Leader)
  ├── payment_method (upfront | scheduled | monthly | batch_lump | per_session)
  ├── min/max students (overridable by Dept Leader)
  ├── website_visible (toggle, default: true)
  ├── budget (spending + earning tracking → Accounting)
  ├── commission (auto-calc for Op Leader, Dept Leader, Course Creator, Facilitator)
  ├──< Schedule
  │      ├── module → CourseModule (tools + requirements)
  │      ├── room → Room (facility matching + conflict detection)
  │      └── time slot
  ├──< Enrollment → Student
  │      └── Invoice (auto-generated per payment method → Accounting)
  └──< AttendanceRecord (facilitator scans student app)

Location
  Building
    └──< Room
           ├── facilities[] (projector, whiteboard, AC, computers, etc.)
           └──< Schedule (no overlap unless Op Leader approves)

Student (Customer)
  ├── app-student (permanent access)
  ├── supporting app access (granted on enrollment, revoked on completion/withdrawal/payment failure)
  ├──< Enrollment → CourseBatch
  ├──< Certificate (Participant + Competency)
  └──< TalentPool (Program Karir pipeline)

Certificate
  ├── Certificate of Participant (auto on course completion)
  ├── Certificate of Competency (requires test pass, open to non-enrolled if criteria met)
  ├── QR code → online verification (app-website)
  └── Revocation (Dept Leader → Education Leader → Director approval)

TalentPool Pipeline (Program Karir only)
  Learning → Internship → Dept Leader Recommendation → Character/Mindset Test → TalentPool

Partner & MOU
  Partner (external company)
    └──< MOU (with expiry tracking, 3-month advance reminder)
  Linked to: Kolaborasi batches, Inhouse Training, Projects, TalentPool (hiring)

Project (Event / One-Time)
  ├── Non-recurring events and initiatives
  ├── Can collaborate with Partners
  └── Own budgeting → Accounting

Leads
  └── Potential customers input by Operation team
      → Cross-referenced when new course/batch created

Notification Center
  └── Distributes to: app-dashboard, app-mentors, app-student, supporting apps
      Channels: in-app, push (FCM), email, WhatsApp/SMS

Accounting (Branch-Based)
  ├── Preset Chart of Accounts (seeded on app init)
  ├── Bank & cash transactions (manual input, per branch)
  ├── Auto-invoices (from enrollment + payment method)
  ├── Batch budgeting (spending vs earning)
  ├── Commission auto-calculation + journal posting
  └── Financial reports (per branch + consolidated)

Company Settings (Director access)
  ├── Commission config (Op Leader, Dept Leader, Course Creator — % of profit or revenue)
  ├── Facilitator levels + fee per session
  ├── Certificate template config + verification domain
  └── Branch management

Business Development (Director-level)
  ├── Business Model Canvas (9 components, live partner tracking)
  ├── Branch & Franchise management
  ├── OKR & KPI (company → department → team → individual)
  ├── Investment Plan (proposals, ROI tracking)
  ├── Financial Projections (monthly cash, revenue, P&L — per branch + consolidated)
  └── Delegation (request course/project, assign tasks to teams)

Dashboard (role-based)
  └── Each user sees content tailored to their role(s)
      ├── Director: BMC, projections, OKR, delegation, consolidated reports
      ├── Operation team: today prep + 7-day schedule (day-by-day layout)
      ├── Education/Dept: department metrics, course status, approvals
      └── Accounting: transactions, invoices, budget vs actual
```

---

## Approval Workflows

| # | Flow | Initiator | Approver(s) |
|---|------|-----------|-------------|
| 1 | Assign Dept Leader | Education Leader | Director |
| 2 | Propose Course | Dept Leader / Course Creator | Education Leader |
| 3 | Course Version Change | Course Owner | Dept Leader |
| 4 | Create Batch (from operation) | Op Administrator | Course Creator → Op Leader → Dept Leader |
| 5 | Create Batch (from course creator) | Course Creator | Op Leader (schedule) + Dept Leader (final) |
| 6 | Batch pricing (within range) | Op Leader | — (self, within normal–min range) |
| 7 | Batch pricing override (outside range) | Dept Leader | — (self-approved) |
| 8 | Batch min/max student override | Op Leader | Dept Leader |
| 9 | Schedule location overlap | Op Admin / Course Creator | Op Leader |
| 10 | Revoke Certificate | Dept Leader | Education Leader → Director |

---

## Infrastructure Ports

| Service | Port |
|---------|------|
| API | 8081 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| NATS | 4222 |
| Jaeger | 16686 |
| Prometheus | 9090 |
| app-entrepreneur | 3000 |
| app-dashboard | 3001 |
| app-blockcoding | 3002 |

---

## Quick Start

```bash
cd api && make infra-up && make migrate-up   # Infrastructure + DB
cd api && make dev                            # API (port 8081)
cd app-dashboard && make run-dev              # Dashboard (port 3001)
cd app-entrepreneur && make run-dev           # Entrepreneur (port 3000)
cd app-mentors && flutter run --dart-define=BASE_URL=http://localhost:8081/api/v1
```

---

## Key Development Rules

1. **SEMUA code ditulis oleh AI** — developer tidak menulis code manual
2. **DILARANG push ke `main`** — selalu via feature branch + PR
3. **Fitur WAJIB diimplementasi di kedua sisi** — API (Go) + Flutter secara bersamaan
4. **WAJIB unit test** untuk setiap fungsi/widget baru
5. **Commit format:** `type(scope): deskripsi` — e.g., `feat(attendance): add weekly summary`
6. **Design uniformity** — All apps MUST share consistent VernonEdu brand identity: fonts, colors, spacing, component styles. Use `AppColors`, `AppDimensions`, `AppStrings` consistently across all Flutter apps.

---

## Docs Index

| Dokumen | Path | Isi |
|---------|------|-----|
| Developer Guide | `docs/DEVELOPER_GUIDE.md` | Setup, workflow, coding standards |
| API Reference | `docs/API_REFERENCE.md` | Semua endpoint lengkap dengan contoh |
| Architecture | `docs/ARCHITECTURE.md` | Diagram sistem, DB schema, event flow |
| Contributing | `docs/CONTRIBUTING.md` | Cara menambah fitur baru (step-by-step) |
| Environment Setup | `docs/ENVIRONMENT_SETUP.md` | Setup lokal, troubleshooting |
| API CLAUDE.md | `api/CLAUDE.md` | Go coding guide + semua endpoints |
| Dashboard CLAUDE.md | `app-dashboard/CLAUDE.md` | Stack, arch, routes, domain index |
| Dashboard Requirements | `app-dashboard/docs/requirements/` | Per-domain specs |
| Dashboard Testing | `app-dashboard/docs/testing/TESTING.md` | Test conventions |
| Dashboard Audit | `app-dashboard/docs/audit/AUDIT.md` | Code quality, tech debt |
| Mentors CLAUDE.md | `app-mentors/CLAUDE.md` | Roles, routes, fitur mobile |

---

**Last Updated:** Maret 2026
