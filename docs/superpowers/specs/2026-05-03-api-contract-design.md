# API Contract — OpenAPI 3.0 Spec

> **Status:** Design approved
> **Date:** 2026-05-03
> **Scope:** Full coverage (~160 endpoints across 20+ domains)

---

## Decision Summary

| Aspek | Keputusan |
|-------|-----------|
| Tujuan | Single source of truth untuk developer manusia + AI (Claude) |
| Format | OpenAPI 3.0.3 (YAML) |
| Scope | Semua endpoint yang ada |
| Pembuatan | Hybrid — auto-generate via swaggo/swag + manual review |
| Struktur file | Multi-file per domain, root openapi.yaml menggunakan `$ref` |
| Tool | swaggo/swag v1.16+ |

---

## Architecture

### File Structure

```
api/
├── docs/
│   ├── openapi.yaml                    ← Root spec (info, servers, security, $ref paths)
│   ├── schemas/
│   │   ├── _index.yaml                 ← Reusable components (Pagination, ErrorResponse, etc.)
│   │   ├── auth.yaml
│   │   ├── user.yaml
│   │   ├── department.yaml
│   │   ├── master-course.yaml
│   │   ├── course-type.yaml
│   │   ├── course-version.yaml
│   │   ├── course-module.yaml
│   │   ├── course-batch.yaml
│   │   ├── student.yaml
│   │   ├── enrollment.yaml
│   │   ├── talentpool.yaml
│   │   ├── building.yaml
│   │   ├── room.yaml
│   │   ├── approval.yaml
│   │   ├── notification.yaml
│   │   ├── certificate.yaml
│   │   ├── invoice.yaml
│   │   ├── payable.yaml
│   │   ├── transaction.yaml
│   │   ├── coa.yaml
│   │   ├── finance-report.yaml
│   │   ├── settings.yaml
│   │   ├── lead.yaml
│   │   ├── marketing.yaml
│   │   ├── partner.yaml
│   │   ├── cms.yaml
│   │   ├── business.yaml
│   │   ├── canvas.yaml
│   │   ├── design-thinking.yaml
│   │   ├── delegation.yaml
│   │   ├── okr.yaml
│   │   ├── investment.yaml
│   │   └── bmc.yaml
│   └── paths/
│       ├── _index.yaml                 ← Reusable path items
│       ├── auth.yaml
│       ├── users.yaml
│       ├── departments.yaml
│       ├── curriculum.yaml             ← courses + types + versions + modules + program-karir
│       ├── course-batches.yaml
│       ├── students.yaml
│       ├── enrollments.yaml
│       ├── talentpool.yaml
│       ├── buildings.yaml
│       ├── rooms.yaml
│       ├── approvals.yaml
│       ├── notifications.yaml
│       ├── certificates.yaml
│       ├── invoices.yaml
│       ├── payables.yaml
│       ├── transactions.yaml
│       ├── coa.yaml
│       ├── finance-reports.yaml
│       ├── finance-analysis.yaml
│       ├── settings.yaml
│       ├── leads.yaml
│       ├── marketing.yaml
│       ├── partners.yaml
│       ├── cms.yaml
│       ├── entrepreneurship.yaml       ← businesses + canvases + design-thinking + items
│       ├── delegations.yaml
│       ├── okr.yaml
│       ├── investment.yaml
│       ├── bmc.yaml
│       └── public.yaml
├── internal/
│   └── delivery/http/
│       └── *_handler.go                ← Swaggo annotations added here
└── Makefile                            ← make docs / make docs-validate
```

### Root openapi.yaml

```yaml
openapi: "3.0.3"
info:
  title: VernonEdu API
  description: Platform pendidikan — kurikulum, kelas, enrollment, sertifikat, accounting
  version: "1.0.0"
  contact:
    name: VernonEdu Dev Team

servers:
  - url: http://localhost:8081/api/v1
    description: Local development

security:
  - BearerAuth: []

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

paths:
  $ref: "./paths/_index.yaml"
components:
  schemas:
    $ref: "./schemas/_index.yaml"
```

---

## Domain Inventory

### Endpoints per Domain

| Domain | Prefix | Endpoint Count | Auth Required |
|--------|--------|---------------|---------------|
| Health | `/health` | 1 | No |
| Public | `/api/v1/public` | 13 | No |
| Auth | `/api/v1/auth` | 3 | Mixed |
| Users | `/api/v1/users` | 6 | Yes |
| Departments | `/api/v1/departments` | 10 | Yes |
| Master Courses | `/api/v1/curriculum/courses` | 8 | Yes |
| Course Types | `/api/v1/curriculum/courses/{id}/types` | 5 | Yes |
| Course Versions | `/api/v1/curriculum/types/{id}/versions` | 5 | Yes |
| Course Modules | `/api/v1/curriculum/versions/{id}/modules` | 4 | Yes |
| Program Karir | `/api/v1/curriculum/versions/{id}/...` | 6 | Yes |
| Course Batches | `/api/v1/course-batches` | 12 | Yes |
| Students | `/api/v1/students` | 11 | Yes |
| Enrollments | `/api/v1/enrollments` | 4 | Yes |
| Talent Pool | `/api/v1/talentpool` | 7 | Yes |
| Buildings | `/api/v1/buildings` | 5 | Yes |
| Rooms | `/api/v1/rooms` | 6 | Yes |
| Approvals | `/api/v1/approvals` | 6 | Yes |
| Notifications | `/api/v1/notifications` | 4 | Yes |
| Certificates | `/api/v1/certificates` | 5 | Mixed |
| Invoices | `/api/v1/finance/invoices` | 5 | Yes |
| Payables | `/api/v1/finance/payables` | 3 | Yes |
| Transactions | `/api/v1/finance/transactions` | 2 | Yes |
| COA | `/api/v1/finance/coa` | 4 | Yes |
| Finance Reports | `/api/v1/finance/reports` | 5 | Yes |
| Finance Analysis | `/api/v1/finance/analysis` | 7 | Yes |
| Settings | `/api/v1/settings` | 9 | Yes |
| Leads | `/api/v1/leads` | 8 | Yes |
| Marketing Posts | `/api/v1/marketing/posts` | 6 | Yes |
| Marketing PR | `/api/v1/marketing/pr` | 4 | Yes |
| Marketing Referral | `/api/v1/marketing/referral-partners` | 5 | Yes |
| Partners | `/api/v1/partners` | 6 | Yes |
| MOUs | `/api/v1/partners/{id}/mous` | 4 | Yes |
| Partner Groups | `/api/v1/partner-groups` | 3 | Yes |
| CMS Pages | `/api/v1/cms/pages` | 3 | Yes |
| CMS Testimonials | `/api/v1/cms/testimonials` | 4 | Yes |
| CMS FAQ | `/api/v1/cms/faq` | 4 | Yes |
| CMS Articles | `/api/v1/cms/articles` | 5 | Yes |
| CMS Media | `/api/v1/cms/media` | 3 | Yes |
| CMS SEO | `/api/v1/cms/seo` | 2 | Yes |
| Businesses | `/api/v1/businesses` | 6 | Yes |
| Canvases | `/api/v1/canvases` | 5 | Yes |
| Design Thinking | `/api/v1/design-thinkings` | 5 | Yes |
| Items | `/api/v1/items` | 5 | Yes |
| Delegations | `/api/v1/delegations` | 7 | Yes |
| OKR | `/api/v1/okr` | 8 | Yes |
| Investment | `/api/v1/investment` | 4 | Yes |
| BMC | `/api/v1/bmc` | 2 | Yes |
| Journal | `/api/v1/finance/journal` | 1 | Yes |
| Accounting Banks | `/api/v1/accounting/banks` | 7 | Yes |
| Accounting | `/api/v1/accounting` | 20+ | Yes |
| **Total** | | **~165** | |

---

## Reusable Schemas

### ErrorResponse

```yaml
ErrorResponse:
  type: object
  required: [error]
  properties:
    error:
      type: string
      example: "invalid credentials"
```

### Pagination (List Result)

```yaml
PaginatedResponse:
  type: object
  required: [data, total, offset, limit]
  properties:
    data:
      type: array
      items: {}
    total:
      type: integer
      example: 42
    offset:
      type: integer
      example: 0
    limit:
      type: integer
      example: 10
```

### Common Query Parameters

```yaml
PaginationParams:
  offset:
    name: offset
    in: query
    schema:
      type: integer
      default: 0
  limit:
    name: limit
    in: query
    schema:
      type: integer
      default: 10
```

---

## Annotation Strategy (swaggo/swag)

### Installation

```bash
cd api
go install github.com/swaggo/swag/cmd/swag@latest
swag init -g internal/delivery/http/router.go -o docs/swagger --outputTypes yaml
```

### Annotation Pattern per Handler

```go
// CreateDepartment godoc
// @Summary      Create a new department
// @Description  Creates a department under education leader's organization
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        body  body  CreateDepartmentRequest  true  "Department data"
// @Success      201   {object}  DepartmentReadModel
// @Failure      400   {object}  ErrorResponse
// @Failure      401   {object}  ErrorResponse
// @Router       /departments [post]
// @Security     BearerAuth
```

### Custom swag.yaml Config

```yaml
# swag.yaml
outputTypes:
  - yaml
parseInternal: true
parseDependency: true
parseDepth: 3
```

### Make Targets

```makefile
.PHONY: docs docs-validate

docs:
	swag init -g internal/delivery/http/router.go -o docs/swagger --outputTypes yaml

docs-validate:
	swag fmt
	swag init -g internal/delivery/http/router.go -o docs/swagger --outputTypes yaml
	@echo "Validate at https://editor.swagger.io"
```

---

## CI Integration

### Pre-commit Hook (Optional)

Validate spec tidak stale:

```yaml
# .github/workflows/api-spec.yaml
name: API Spec Validation
on:
  push:
    paths:
      - 'api/internal/**'
      - 'api/docs/**'
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
      - run: go install github.com/swaggo/swag/cmd/swag@latest
      - run: cd api && make docs
      - run: git diff --exit-code api/docs/swagger/
```

---

## Domain Priority Order (Implementation Sequence)

Batch urutan kerja — dari yang paling banyak dipakai Flutter apps:

1. **Auth** — foundation, 3 endpoints
2. **Users** — dependency auth, 6 endpoints
3. **Departments** — org structure, 10 endpoints
4. **Curriculum** — courses + types + versions + modules + program karir, 28 endpoints
5. **Course Batches** — core business, 12 endpoints
6. **Students** — customer entity, 11 endpoints
7. **Enrollments** — core flow, 4 endpoints
8. **Finance** — invoices + payables + transactions + COA + reports + analysis, 26 endpoints
9. **Accounting** — banks + accounting ops, 27 endpoints
10. **CMS** — pages + testimonials + FAQ + articles + media + SEO, 21 endpoints
11. **Marketing** — posts + PR + referral, 15 endpoints
12. **Partners** — partners + MOUs + groups, 13 endpoints
13. **Certificates** — create + verify + revoke, 5 endpoints
14. **Settings** — commission + facilitator + branches + holidays, 9 endpoints
15. **Leads** — CRM pipeline, 8 endpoints
16. **Buildings & Rooms** — location, 11 endpoints
17. **Approvals** — workflow, 6 endpoints
18. **Notifications** — in-app, 4 endpoints
19. **Talent Pool** — pipeline, 7 endpoints
20. **Entrepreneurship** — businesses + canvases + design-thinking + items, 21 endpoints
21. **Delegations** — task mgmt, 7 endpoints
22. **OKR** — objectives, 8 endpoints
23. **Investment** — planning, 4 endpoints
24. **BMC** — business canvas, 2 endpoints
25. **Public** — no-auth endpoints, 13 endpoints
26. **Health** — 1 endpoint

---

## Flutter Integration

### AI Usage Pattern

Claude membaca `api/docs/swagger/swagger.yaml` sebagai context saat generate Flutter code:

1. Baca schema → generate Dart model classes
2. Baca paths → generate Dio API client methods
3. Baca error responses → generate error handling

### Human Usage

Developer bisa:
- Buka `swagger.yaml` di editor untuk quick reference
- Upload ke https://editor.swagger.io untuk interactive docs
- Generate Postman collection dari spec

---

## Acceptance Criteria

- [ ] Semua ~165 endpoint terdokumentasi di OpenAPI spec
- [ ] Setiap endpoint punya: summary, description, parameters, request body, response schemas, error responses
- [ ] Spec bisa dibuka di Swagger Editor tanpa error
- [ ] `make docs` menghasilkan spec yang up-to-date dari annotations
- [ ] Spec mencakup security schemes (Bearer JWT)
- [ ] Pagination pattern konsisten di semua list endpoints
- [ ] Error response format konsisten (`{"error": "message"}`)
