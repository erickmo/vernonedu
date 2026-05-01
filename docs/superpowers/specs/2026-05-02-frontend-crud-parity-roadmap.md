# Frontend CRUD Parity Roadmap

**Date:** 2026-05-02
**Type:** Roadmap spec (peta jalan, bukan spec implementasi)
**Status:** Draft → User Review

---

## §1 Purpose & Scope

### Tujuan
Roadmap untuk mencapai parity CRUD antara frontend (`/frontend`) dan backend (`/api`). Dokumen ini bersifat inventaris dan peta jalan — bukan spec implementasi. Setiap domain akan punya spec/plan tersendiri saat dieksekusi.

### In-scope
- 3 portal: Internal, Student, Franchise
- Semua domain backend yang sudah punya repository + command/query
- Status matrix per page (List / Detail / Create / Edit / Actions)
- Bucket grouping berdasarkan alur bisnis
- Build order dan fase
- Konvensi default: `StandardPageLayout` dengan policy variasi (wizard, kanban, calendar, dll)

### Out-of-scope
- Detail UI tiap page (akan dispek terpisah per domain)
- Endpoint baru di API (asumsi backend siap; gap dicatat saja)
- Redesign atau polish page yang sudah ada
- Auth / permission rework
- Performance, PWA, atau offline support

### Deliverable
File ini sendiri. Tidak ada code change langsung dari spec ini.

---

## §2 Domain Buckets

7 bucket bisnis. Build order = urutan bucket (1 → 7).

| # | Bucket | Domain |
|---|--------|--------|
| 1 | **Curriculum** | MasterCourse, CourseType, CourseVersion, CourseModule, CertificateTemplate, InternshipConfig, CharacterTestConfig |
| 2 | **Operations** | CourseBatch, BatchSchedule, Building, Room, Holiday, AttendanceRecord, Facilitator assignment |
| 3 | **Enrollment & Certificate** | Enrollment, Invoice (issuance), Certificate (issue/revoke), StudentAppAccess, Lead, CRM logs |
| 4 | **Accounting** | CoA, FinanceAccount, Transaction, JournalEntry, Payable, Invoice (AR), Reports (BS/PL/CF/GL/TB), BudgetVsActual, Commission |
| 5 | **BizDev** | Business Model Canvas, OKR/KPI, Investment Plan, Delegation, Approval queue, Branch, MOU, Project |
| 6 | **Marketing & CMS** | CMS Pages, CMS Articles, FAQ, Testimonials, Media, Marketing Posts, ClassDoc Posts, Referral Partner |
| 7 | **HR & Settings** | User, Facilitator levels, Commission config, Settings, Notification composer, TalentPool pipeline, Item inventory, DesignThinking, Canvas (entrepreneur tools) |

Critical path: kurikulum harus ada → batch jalan → enrollment → uang masuk → manajemen → growth → admin.

---

## §3 Status Matrix

Legend: ✅ ada · 🟡 sebagian · ❌ kosong · — N/A
Portal: **I**=Internal · **S**=Student · **F**=Franchise

### Bucket 1 — Curriculum
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| MasterCourse | I | ❌ | ❌ | ❌ | ❌ | archive |
| CourseType | I | ❌ | ❌ | ❌ | ❌ | toggle active |
| CourseVersion | I | ❌ | ❌ | ❌ | ❌ | promote, archive |
| CourseModule | I | ❌ | ❌ | ❌ | ❌ | reorder |
| CertificateTemplate | I | ❌ | ❌ | ❌ | ❌ | preview |
| InternshipConfig | I | ❌ | ❌ | ❌ | ❌ | — |
| CharacterTestConfig | I | ❌ | ❌ | ❌ | ❌ | — |
| Course (catalog) | I | ✅ | ✅ | ❌ | ❌ | — |
| Course catalog | S | ✅ | ✅ | — | — | enroll |

### Bucket 2 — Operations
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| CourseBatch | I | 🟡 (di Courses) | ❌ | ❌ | ❌ | assign facilitator, close |
| BatchSchedule | I | ❌ | ❌ | ❌ | ❌ | conflict check, calendar view 🟡 |
| Building | I | ❌ | ❌ | ❌ | ❌ | — |
| Room | I | ❌ | ❌ | ❌ | ❌ | availability check |
| Holiday | I | ❌ | — | ❌ | — | delete |
| Attendance | I | ❌ | ❌ | ❌ | — | mark present/absent |
| Attendance | S | ❌ | — | — | — | view own |
| Facilitator schedule | I | ❌ | ❌ | — | — | — |

### Bucket 3 — Enrollment & Certificate
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| Enrollment | I | ✅ | ✅ | ❌ | ❌ | grant/revoke app access |
| Enrollment | S | ✅ | — | — | — | — |
| Enrollment | F | ✅ | ❌ | — | — | — |
| Invoice (issue) | I | 🟡 (Payments) | ✅ | ❌ | ❌ | send, mark paid, cancel |
| Certificate | I | ❌ | ❌ | ❌ | — | issue, revoke (3-step approval) |
| Certificate | S | ✅ | ❌ | — | — | download |
| Lead | I | ❌ | ❌ | ❌ | ❌ | convert→student, CRM log |
| StudentAppAccess | I | ❌ | — | — | — | grant, revoke |

### Bucket 4 — Accounting
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| CoA | I | ❌ | ❌ | ❌ | ❌ | — |
| FinanceAccount (bank/cash) | I | ❌ | ❌ | ❌ | ❌ | — |
| Transaction | I | ❌ | ❌ | ❌ | ❌ | — |
| Journal Entry | I | ❌ | ❌ | ❌ | — | — |
| Payable | I | ❌ | ❌ | ❌ | — | approve, mark paid, cancel |
| BS / PL / CF / GL / TB | I | ❌ | — | — | — | export |
| Budget vs Actual | I | 🟡 (Budget) | ✅ | ❌ | ❌ | — |
| Commission | I | ❌ | ❌ | — | — | recalc, pay |
| Financial alerts/ratios/suggestions | I | ❌ | — | — | — | — |
| Royalty | F | ✅ | — | — | — | — |
| Payments | F | ✅ | — | — | — | — |

### Bucket 5 — BizDev
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| BMC | I | ❌ | ❌ | ❌ | ❌ | — |
| OKR Objective + KR | I | ❌ | ❌ | ❌ | ❌ | update progress |
| Investment Plan | I | ❌ | ❌ | ❌ | ❌ | — |
| Delegation | I | ❌ | ❌ | ❌ | — | accept, complete, cancel |
| Approval queue | I | ❌ | ❌ | ❌ | — | approve, reject, cancel (wizard) |
| Branch | I | ❌ | ❌ | ❌ | ❌ | — |
| MOU | I | ❌ | ❌ | ❌ | — | delete, expiry alerts |
| Project | I | ❌ | ❌ | ❌ | ❌ | budget link |

### Bucket 6 — Marketing & CMS
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| CMS Page | I | ❌ | ❌ | — | ❌ | — |
| CMS Article | I | ❌ | ❌ | ❌ | ❌ | publish |
| CMS FAQ | I | ❌ | — | ❌ | ❌ | — |
| CMS Testimonial | I | ❌ | — | ❌ | — | — |
| CMS Media | I | ❌ | — | ❌ | — | upload, delete |
| Marketing Post | I | ❌ | ❌ | ❌ | — | submit URL |
| ClassDoc Post | I | ❌ | ❌ | ❌ | — | — |
| Referral Partner | I | ❌ | ❌ | ❌ | — | — |

### Bucket 7 — HR & Settings
| Domain | Portal | List | Detail | Create | Edit | Actions |
|---|---|---|---|---|---|---|
| User | I | 🟡 (TeamMembers) | ✅ | ❌ | ❌ | register, role assign |
| Facilitator levels | I | ❌ | — | ❌ | ❌ | — |
| Commission config | I | ❌ | — | — | ❌ | — |
| Settings (general) | I | ❌ | — | — | ❌ | — |
| Notification composer | I | ✅ | ✅ | ❌ | — | broadcast |
| TalentPool | I | ❌ | ❌ | — | — | advance stage (kanban) |
| Item inventory | I | ❌ | ❌ | ❌ | ❌ | — |
| Canvas (entrepreneur) | S | ❌ | ❌ | ❌ | ❌ | — |
| DesignThinking | S | ❌ | ❌ | ❌ | ❌ | — |
| Profile | S | — | ✅ | — | ✅ | — |
| Dashboard | F | — | ✅ | — | — | — |
| TeamMembers | F | ✅ | — | — | — | — |

**Total gap kasar:** ~120 page baru + ~15 page partial yang perlu dilengkapi.

---

## §4 Build Order & Phasing

| Fase | Bucket | Domain count | Est PR | Blocker untuk |
|---|---|---|---|---|
| 1 | Curriculum | 8 | ~24 | Ops (butuh CourseVersion + Module) |
| 2 | Operations | 7 | ~22 | Enrollment (butuh Batch + Schedule) |
| 3 | Enrollment & Cert | 6 | ~18 | Accounting (butuh Invoice issue) |
| 4 | Accounting | 11 | ~30 | BizDev (butuh ledger utk projection) |
| 5 | BizDev | 8 | ~24 | — |
| 6 | Marketing & CMS | 8 | ~20 | — |
| 7 | HR & Settings | 13 | ~30 | — |

**Per-domain siklus:**
1. Tulis spec domain (`docs/superpowers/specs/YYYY-MM-DD-<bucket>-<domain>.md`)
2. Tulis plan implementasi (`docs/superpowers/plans/...`)
3. List page → PR
4. Detail page → PR
5. Create + Edit → PR
6. Actions / special UI → PR

**Parallelisasi:** Dalam 1 fase, domain yang independen boleh paralel (mis. Building & Room independen dari Holiday). Domain dependen sequential (CourseVersion butuh CourseType dulu).

**Definition of Done per domain:**
- Semua row matrix domain = ✅
- Form pakai react-hook-form + zod schema (lihat `frontend/src/schemas/`)
- Hook data pakai pola existing (cek `lib/`)
- Empty / loading / error state ada
- Permission check sesuai role matrix di CLAUDE.md
- Smoke test manual didokumentasi

---

## §5 Conventions & Variation Policy

### Default layout
`components/layout/StandardPageLayout` (rujuk commit `0be8a17a`). Pakai untuk semua Create / Edit / Detail.

### Pola Partner sebagai template
- `<Domain>Page.tsx` — list (table + filter + search + paginate)
- `detail/<Domain>Detail.tsx` — read-only, tombol Edit
- `<Domain>CreatePage.tsx` — form dengan StandardPageLayout
- `<Domain>EditPage.tsx` — form prefilled
- Route order: `/new` & `/edit` SEBELUM `/:id` (rujuk `ec440578`)

### File location
- Internal pages: `src/portals/internal/pages/`
- Detail pages: `src/portals/internal/pages/detail/`
- Domain overview: `src/portals/internal/pages/domains/`
- Schema: `src/schemas/<domain>.ts`
- Type: `src/types/<domain>.ts`
- API client / hook: `src/lib/api/<domain>.ts`

### Variasi diizinkan
StandardPageLayout sebagai shell, body bisa diganti.

| Variasi | Domain | Alasan |
|---|---|---|
| Wizard multi-step | Approval, Delegation, Certificate revocation | Step approval Director→Edu Leader→Dept |
| Kanban | TalentPool pipeline | Stage-based (Learning→Internship→Recommendation→Test→Pool) |
| Calendar | BatchSchedule | Time-based, conflict visual |
| Tree / hierarchy | OKR (Company→Dept→Team→Individual), CoA | Parent-child |
| Canvas grid | BMC (9 komponen) | Layout tetap |
| Table inline-edit | CoA, Facilitator levels, Holiday | Bulk admin tasks |
| Builder | CertificateTemplate, CMS Page | Visual edit |
| Report viewer | BS / PL / CF / GL / TB | Read-only + export |

### Stack reuse
- Form: react-hook-form + zod (existing)
- Table: shared `<DataTable>` (kalau belum ada → bikin di prerequisite)
- Modal: shadcn dialog (`components/ui/`)
- Toast: existing
- Icon: lucide-react

### Prerequisite sebelum fase 1
- Audit `<DataTable>` reusable. Kalau belum ada → bikin sebelum mulai (1 PR setup).
- Audit `<FormField>` wrapper untuk konsistensi.

---

## §6 Risks & Open Questions

### Risks
- **Drift backend↔frontend:** API berubah saat frontend nyusul. Mitigasi: re-verify endpoint per domain saat spec ditulis.
- **Permission complexity:** 11 staff role + 2 external. Tiap page perlu role gate. Mitigasi: helper `canAccess(role, action)` + matrix di tiap spec.
- **Approval chains:** 3-step (mis. revoke certificate). Mitigasi: 1 wizard component reuse.
- **Big-bang risk:** 7 fase × ~24 PR = ~168 PR. Mitigasi: tiap PR kecil (<400 LOC), CI hijau wajib.
- **Scope creep:** "redesign sambil jalan". Mitigasi: out-of-scope eksplisit di §1.

### Open questions
1. `<DataTable>` reusable sudah ada belum di `components/`? (audit pra-fase 1)
2. Pola hook data fetching: react-query? SWR? custom? → cek `lib/` saat audit
3. Permission helper sudah ada atau bikin baru?
4. CourseBatch CRUD penuh masuk fase 1 (Curriculum) atau fase 2 (Operations)? **Resolved:** fase 2, batch = artefak operasional bukan kurikulum.
5. Calendar page existing (`Calendar.tsx` 10.6K) — extend atau replace untuk BatchSchedule? → tentukan saat spec BatchSchedule (fase 2).

### Tindak lanjut
- Resolve OQ #1–3 saat brainstorm spec fase 1
- OQ #4 sudah dijawab di §4
- OQ #5 → spec BatchSchedule (fase 2)

---

## §7 Next Steps

1. User review spec ini
2. Setelah approved: invoke `superpowers:writing-plans` skill untuk plan **prerequisite** (audit `<DataTable>` + `<FormField>` + permission helper + hook pattern)
3. Setelah prerequisite selesai: brainstorm + spec **fase 1 Curriculum** (domain pertama: MasterCourse atau CourseType — TBD saat brainstorm fase 1)
