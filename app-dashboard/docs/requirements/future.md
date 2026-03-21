# Future & Expanding Domains

> Specs for domains that are currently UI shells or newly defined.

---

## Project Management

**Route:** `/projects` → `ProjectPage`

Other than courses, VernonEdu can create **events or one-time projects**. Projects can collaborate with Partners.

### Key Concepts
- A Project is a non-recurring event or initiative (unlike Course which is repeatable via batches)
- Projects can be linked to one or more **Partners** (see Partner domain below)
- Projects have their own budgeting (feeds into Accounting, branch-based)
- Projects can have schedules, locations, and assigned staff

**Current status:** UI shell — "Fitur manajemen proyek akan segera hadir" placeholder
**No data/domain directories** — only `presentation/pages` + `presentation/widgets`
**To implement:** Full clean architecture stack.

---

## Partner & MOU Management

Partners are external organizations that collaborate with VernonEdu (e.g. for Kolaborasi, Inhouse Training, Projects).

### Features
- CRUD for partner data (company info, contacts, industry)
- **MOU tracking** — each partner can have one or more MOUs with expiry dates
- **MOU expiry reminder** — system sends notification **3 months before MOU expires**
- Partner can be linked to: Course Batches (Kolaborasi/Inhouse), Projects, TalentPool (hiring)

### Entities (planned)

| Entity | Key Fields |
|--------|------------|
| PartnerEntity | id, name, industry, address, contactName, contactEmail, contactPhone, website?, logoUrl?, isActive |
| MouEntity | id, partnerId, title, description, startDate, endDate, documentUrl?, status (active\|expired\|terminated), createdAt |

### API Endpoints (planned)

```
# Partners
GET    /partners              ?offset, limit, is_active?
GET    /partners/:id
POST   /partners              body: {name, industry, address, contactName, contactEmail, ...}
PUT    /partners/:id
DELETE /partners/:id

# MOUs
GET    /partners/:id/mous
POST   /partners/:id/mous     body: {title, startDate, endDate, documentUrl?}
PUT    /mous/:id
DELETE /mous/:id
GET    /mous/expiring          ?within_months=3  → MOUs expiring soon
```

**Current status:** `partner` role exists in system but no app access or management UI yet.
**To implement:** Full clean architecture stack + MOU reminder via Notification Center.

---

## Evaluation

**Route:** `/evaluations` → `EvaluationPage`
**Current status:** UI shell — "Fitur evaluasi course akan segera hadir" placeholder
**Directories exist:** `data/datasources`, `data/models`, `data/repositories`, `domain/entities`, `domain/repositories`, `domain/usecases`, `presentation/cubit` — all empty
**To implement:** Full cubit + datasource + entity + usecase stack

---

## Payment

**Route:** `/payments` → `PaymentPage`
**Current status:** UI shell — "Fitur laporan pembayaran akan segera hadir" placeholder
**Directories exist:** `data/datasources`, `data/models`, `data/repositories`, `domain/entities`, `domain/repositories`, `domain/usecases`, `presentation/cubit` — all empty
**To implement:** Full cubit + datasource + entity + usecase stack. Closely tied to Accounting domain (see [accounting.md](accounting.md)) — invoices, payment tracking, overdue alerts.

---

## CRM

**Route:** `/crm` → `CrmPage`
**Current status:** UI shell — "Fitur CRM akan segera hadir" placeholder
**No data/domain directories** — only `presentation/pages` + `presentation/widgets`
**To implement:** Full clean architecture stack. Marketing Team is the primary user. Integrates with Leads (see [operations.md](operations.md)).

---

## Dashboard (Home)

**Route:** `/dashboard` → `DashboardPage`
**Current:** No dedicated cubit — uses `AuthCubit` for user info + aggregated data from multiple domains.
**UI:** Summary stat cards + recent activity widgets.

### Role-Based Dashboard (v2)

Each user sees a dashboard tailored to their role(s):

| Role | Dashboard Content |
|------|------------------|
| Director | BMC summary, financial projections, OKR progress, delegation queue, consolidated metrics |
| Education Leader | Department metrics, course pipeline, pending approvals, OKR (education) |
| Dept Leader | Department detail, course status, batch overview, team KPIs, approvals |
| Course Owner | My courses, batch status, enrollment stats |
| Facilitator | Today's schedule, upcoming sessions, attendance summary |
| Operation Leader | Operational overview, batch pipeline, schedule conflicts, team tasks |
| Operation Admin | **Today prep view** + **7-day day-by-day schedule** (rooms, tools, materials per session) |
| Customer Service | Student inquiries, enrollment queue, payment status |
| Marketing | Leads pipeline, ads template status, campaign metrics |
| Accounting Leader | Financial overview, pending invoices, budget vs actual, commission summary |
| Accounting Staff | Transaction queue, invoice status, daily reconciliation |

See [operations.md](operations.md) for the operational dashboard detail and [business-development.md](business-development.md) for Director-level views.
