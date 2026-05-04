# API Contract — OpenAPI 3.0 Spec Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate complete OpenAPI 3.0 spec for all ~165 VernonEdu API endpoints using swaggo/swag annotations.

**Architecture:** Add swaggo annotations to existing Go handlers. swag init generates `swagger.yaml` from annotations. Reusable response types defined once. Each handler file gets annotations per method.

**Tech Stack:** Go 1.25, swaggo/swag v1.16+, Chi v5, existing Clean Architecture codebase

**Design Spec:** `docs/superpowers/specs/2026-05-03-api-contract-design.md`

---

## File Structure

### New Files
- `api/docs/swagger/swagger.yaml` — generated OpenAPI spec (auto-generated, do not edit)
- `api/docs/swagger/docs.go` — generated Go embed file (auto-generated)
- `api/pkg/swagger/response.go` — reusable swag response types
- `api/internal/delivery/http/swagger_types.go` — request/response type definitions for swag

### Modified Files
- `api/go.mod` — add swaggo dependencies
- `api/Makefile` — add docs/docs-validate targets
- `api/internal/delivery/http/*_handler.go` — add annotations to each handler method (26 files)

---

## Task 1: Install swaggo and Configure

**Files:**
- Modify: `api/go.mod`
- Modify: `api/Makefile`

- [ ] **Step 1: Install swag CLI**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go install github.com/swaggo/swag/cmd/swag@latest
swag --version
```

Expected: version output (e.g., v1.16.x)

- [ ] **Step 2: Add swag dependencies to go.mod**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go get github.com/swaggo/swag
go get github.com/swaggo/http-swagger
```

- [ ] **Step 3: Update Makefile — add docs targets**

Append to `api/Makefile`:

```makefile
.PHONY: docs docs-validate docs-serve

docs:
	@echo "Generating API docs..."
	@mkdir -p docs/swagger
	swag init -g cmd/api/main.go -o docs/swagger --outputTypes yaml --parseDependency --parseInternal

docs-validate:
	@echo "Validating API docs..."
	swag fmt -g cmd/api/main.go -o docs/swagger --outputTypes yaml --parseDependency --parseInternal
	@echo "Docs generated. Validate at https://editor.swagger.io"

docs-serve:
	@echo "Serving docs at http://localhost:8082"
	@docker run --rm -p 8082:8080 -e SWAGGER_JSON=/docs/swagger.yaml -v $(PWD)/docs/swagger:/docs swaggerapi/swagger-ui
```

- [ ] **Step 4: Verify setup compiles**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go mod tidy
swag init -g cmd/api/main.go -o docs/swagger --outputTypes yaml --parseDependency --parseInternal 2>&1 || true
```

Expected: May show warnings about missing annotations — that's OK. No fatal errors.

- [ ] **Step 5: Commit**

```bash
git add api/go.mod api/go.sum api/Makefile
git commit -m "chore(docs): add swaggo/swag setup and Makefile docs targets"
```

---

## Task 2: Create Reusable Swagger Types

**Files:**
- Create: `api/internal/delivery/http/swagger_types.go`

This file defines request/response structs used only for swag documentation. Swaggo reads struct tags to generate schemas.

- [ ] **Step 1: Create swagger_types.go with common types**

```go
package http

// -- Common Responses --

// swag:response ErrorResponse
type swagErrorResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"invalid credentials"`
	}
}

// swag:response PaginatedResponse
type swagPaginatedResponse struct {
	// in: body
	Body struct {
		// Array of items
		Data []interface{} `json:"data"`
		// Total number of items
		Total int `json:"total" example:"42"`
		// Current offset
		Offset int `json:"offset" example:"0"`
		// Items per page
		Limit int `json:"limit" example:"10"`
	}
}

// swag:response NoContentResponse
type swagNoContentResponse struct {
	// in: body
	Body struct{}
}

// swag:response UnauthorizedResponse
type swagUnauthorizedResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"missing authorization header"`
	}
}

// swag:response ForbiddenResponse
type swagForbiddenResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"insufficient permissions"`
	}
}

// swag:response NotFoundResponse
type swagNotFoundResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"resource not found"`
	}
}

// swag:response BadRequestResponse
type swagBadRequestResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"invalid request body"`
	}
}

// swag:response ConflictResponse
type swagConflictResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"resource already exists"`
	}
}

// swag:response InternalServerErrorResponse
type swagInternalServerErrorResponse struct {
	// in: body
	Body struct {
		// The error message
		Error string `json:"error" example:"internal server error"`
	}
}
```

- [ ] **Step 2: Verify file compiles**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
go build ./internal/delivery/http/
```

Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/delivery/http/swagger_types.go
git commit -m "chore(docs): add reusable swagger type definitions"
```

---

## Task 3: Add General API Info Annotation

**Files:**
- Modify: `api/cmd/api/main.go`

- [ ] **Step 1: Add main swag annotation to main.go**

Add this comment block ABOVE the `package main` line in `api/cmd/api/main.go`:

```go
// @title        VernonEdu API
// @version      1.0.0
// @description  Platform pendidikan — kurikulum, kelas, enrollment, sertifikat, accounting.
// @description  Base URL: http://localhost:8081/api/v1
// @termsOfService  http://swagger.io/terms/

// @contact.name   VernonEdu Dev Team
// @contact.url    https://vernonedu.com

// @license.name  Proprietary

// @host      localhost:8081
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.

// @externalDocs.description  OpenAPI
// @externalDocs.url          https://swagger.io/resources/open-api/
package main
```

- [ ] **Step 2: Verify swag init picks it up**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
swag init -g cmd/api/main.go -o docs/swagger --outputTypes yaml --parseDependency --parseInternal 2>&1 | head -20
```

Expected: Output shows "Create docs/swagger/swagger.yaml..." and info fields populated.

- [ ] **Step 3: Commit**

```bash
git add api/cmd/api/main.go
git commit -m "docs(api): add swaggo main API info annotation"
```

---

## Task 4: Auth Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/auth_handler.go`

- [ ] **Step 1: Add annotations to Register method**

Add above `func (h *AuthHandler) Register(...)`:

```go
// Register godoc
// @Summary      Register a new user
// @Description  Creates a new user account with the provided details
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        body  body  object{email=string,password=string,name=string,roles=[]string}  true  "Registration data"
// @Success      201  {object}  map[string]interface{}  "User created with token"
// @Failure      400  {object}  map[string]string  "{"error": "invalid request body"}"
// @Failure      409  {object}  map[string]string  "{"error": "email already exists"}"
// @Router       /auth/register [post]
```

- [ ] **Step 2: Add annotations to Login method**

Add above `func (h *AuthHandler) Login(...)`:

```go
// Login godoc
// @Summary      Login user
// @Description  Authenticates user and returns JWT access token with user profile
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        body  body  object{email=string,password=string}  true  "Login credentials"
// @Success      200  {object}  map[string]interface{}  "access_token, refresh_token, user"
// @Failure      401  {object}  map[string]string  "{"error": "invalid credentials"}"
// @Failure      400  {object}  map[string]string  "{"error": "invalid request body"}"
// @Router       /auth/login [post]
```

- [ ] **Step 3: Add annotations to Me method**

Add above `func (h *AuthHandler) Me(...)`:

```go
// Me godoc
// @Summary      Get current user profile
// @Description  Returns the authenticated user's profile and roles
// @Tags         auth
// @Produce      json
// @Success      200  {object}  map[string]interface{}  "User profile with roles"
// @Failure      401  {object}  map[string]string  "{"error": "missing authorization header"}"
// @Security     BearerAuth
// @Router       /auth/me [get]
```

- [ ] **Step 4: Verify build**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
```

- [ ] **Step 5: Commit**

```bash
git add api/internal/delivery/http/auth_handler.go
git commit -m "docs(auth): add swaggo annotations for auth endpoints"
```

---

## Task 5: User Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/user_handler.go`

Handler methods: Create, GetByID, List, Search, Update, Delete

- [ ] **Step 1: Add annotations to all 6 methods**

**Create:**
```go
// Create godoc
// @Summary      Create a new user
// @Description  Creates a user with specified roles
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        body  body  object{name=string,email=string,password=string,roles=[]string,phone=string}  true  "User data"
// @Success      201  {object}  map[string]interface{}  "Created user"
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users [post]
```

**GetByID:**
```go
// GetByID godoc
// @Summary      Get user by ID
// @Description  Returns a single user's profile
// @Tags         users
// @Produce      json
// @Param        id   path      string  true  "User ID (UUID)"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/{id} [get]
```

**List:**
```go
// List godoc
// @Summary      List users
// @Description  Returns paginated list of users with optional role filter
// @Tags         users
// @Produce      json
// @Param        offset  query     int     false  "Page offset"  default(0)
// @Param        limit   query     int     false  "Page size"    default(10)
// @Param        role    query     string  false  "Filter by role key"
// @Success      200  {object}  map[string]interface{}  "Paginated user list"
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users [get]
```

**Search:**
```go
// Search godoc
// @Summary      Search users by name
// @Description  Returns users matching the search query
// @Tags         users
// @Produce      json
// @Param        name   query     string  true  "Search query"
// @Success      200  {array}   map[string]interface{}
// @Failure      401  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/search [get]
```

**Update:**
```go
// Update godoc
// @Summary      Update user
// @Description  Updates user profile fields
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        id    path      string  true  "User ID (UUID)"
// @Param        body  body      object{name=string,email=string,phone=string,roles=[]string}  true  "Update data"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/{id} [put]
```

**Delete:**
```go
// Delete godoc
// @Summary      Delete user
// @Description  Soft-deletes a user account
// @Tags         users
// @Produce      json
// @Param        id   path      string  true  "User ID (UUID)"
// @Success      200  {object}  map[string]string  "{"message": "deleted"}"
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /users/{id} [delete]
```

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/user_handler.go
git commit -m "docs(users): add swaggo annotations for user endpoints"
```

---

## Task 6: Department Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/department_handler.go`

Methods: Create, GetByID, List, Update, Delete, ListSummaries, GetBatches, GetCourses, GetStudents, GetTalentPool

- [ ] **Step 1: Add annotations to all 10 methods**

**Create:**
```go
// Create godoc
// @Summary      Create department
// @Description  Creates a new department under education leader
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        body  body  object{name=string,description=string,leader_id=string}  true  "Department data"
// @Success      201  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments [post]
```

**GetByID:**
```go
// GetByID godoc
// @Summary      Get department by ID
// @Description  Returns department details with leader info
// @Tags         departments
// @Produce      json
// @Param        id   path      string  true  "Department ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      404  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id} [get]
```

**List:**
```go
// List godoc
// @Summary      List departments
// @Description  Returns paginated list of departments
// @Tags         departments
// @Produce      json
// @Param        offset  query  int  false  "Page offset"  default(0)
// @Param        limit   query  int  false  "Page size"    default(10)
// @Success      200  {object}  map[string]interface{}
// @Security     BearerAuth
// @Router       /departments [get]
```

**Update:**
```go
// Update godoc
// @Summary      Update department
// @Description  Updates department name, description, or leader
// @Tags         departments
// @Accept       json
// @Produce      json
// @Param        id    path  string  true  "Department ID"
// @Param        body  body  object{name=string,description=string,leader_id=string}  true  "Update data"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id} [put]
```

**Delete:**
```go
// Delete godoc
// @Summary      Delete department
// @Description  Soft-deletes a department
// @Tags         departments
// @Produce      json
// @Param        id   path  string  true  "Department ID"
// @Success      200  {object}  map[string]string
// @Security     BearerAuth
// @Router       /departments/{id} [delete]
```

**ListSummaries:**
```go
// ListSummaries godoc
// @Summary      Get department summaries
// @Description  Returns lightweight department list for dropdowns
// @Tags         departments
// @Produce      json
// @Success      200  {array}   map[string]interface{}
// @Security     BearerAuth
// @Router       /departments/summaries [get]
```

**GetBatches:**
```go
// GetBatches godoc
// @Summary      Get department batches
// @Description  Returns batches belonging to this department's courses
// @Tags         departments
// @Produce      json
// @Param        id  path  string  true  "Department ID"
// @Success      200  {array}  map[string]interface{}
// @Security     BearerAuth
// @Router       /departments/{id}/batches [get]
```

**GetCourses:**
```go
// GetCourses godoc
// @Summary      Get department courses
// @Description  Returns courses belonging to this department
// @Tags         departments
// @Produce      json
// @Param        id  path  string  true  "Department ID"
// @Success      200  {array}  map[string]interface{}
// @Security     BearerAuth
// @Router       /departments/{id}/courses [get]
```

**GetStudents:**
```go
// GetStudents godoc
// @Summary      Get department students
// @Description  Returns students enrolled in this department's courses
// @Tags         departments
// @Produce      json
// @Param        id      path  string  true  "Department ID"
// @Param        status  query string  false  "Filter by enrollment status"
// @Success      200  {array}  map[string]interface{}
// @Security     BearerAuth
// @Router       /departments/{id}/students [get]
```

**GetTalentPool:**
```go
// GetTalentPool godoc
// @Summary      Get department talent pool
// @Description  Returns talent pool entries for this department's Program Karir
// @Tags         departments
// @Produce      json
// @Param        id  path  string  true  "Department ID"
// @Success      200  {array}  map[string]interface{}
// @Security     BearerAuth
// @Router       /departments/{id}/talentpool [get]
```

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/department_handler.go
git commit -m "docs(departments): add swaggo annotations for department endpoints"
```

---

## Task 7: Curriculum Handler Annotations (Courses, Types, Versions, Modules, Program Karir)

**Files:**
- Modify: `api/internal/delivery/http/course_handler.go`
- Modify: `api/internal/delivery/http/course_type_handler.go` (if exists)
- Modify: `api/internal/delivery/http/course_version_handler.go` (if exists)
- Modify: `api/internal/delivery/http/course_module_handler.go` (if exists)
- Modify: `api/internal/delivery/http/program_karir_handler.go` (if exists)

This task covers all curriculum endpoints (~28 endpoints). For each handler file, add swaggo annotations following the same pattern as Tasks 4-6. Key details:

**Course Handler** (5 methods: Create, GetByID, List, Update, Delete):
- Tag: `curriculum`
- Base route: `/curriculum/courses`
- List params: offset, limit, status, field, department_id

**Course Type Handler** (5 methods: Create, GetByID, List, Update, Toggle):
- Tag: `curriculum`
- Base route: `/curriculum/courses/{courseID}/types`
- Update body includes: pricing (normal_price, min_price), participant limits (min_participants, max_participants)

**Course Version Handler** (5 methods: Create, GetByID, List, Promote, Propose):
- Tag: `curriculum`
- Base route: `/curriculum/types/{typeID}/versions`
- Propose creates an approval

**Course Module Handler** (5 methods: Create, GetByID, List, Update, Delete):
- Tag: `curriculum`
- Base route: `/curriculum/versions/{versionID}/modules`

**Program Karir Handler** (6 methods):
- Tag: `curriculum`
- Routes: `/curriculum/versions/{versionID}/internship`, `/curriculum/versions/{versionID}/character-test`, `/curriculum/types/{typeID}/failure-config`

- [ ] **Step 1: Annotate course_handler.go (5 methods)**

Use pattern: `@Tags curriculum`, `@Security BearerAuth`, same error responses.

- [ ] **Step 2: Annotate course type, version, module handlers (15 methods)**

- [ ] **Step 3: Annotate program karir handler (6 methods)**

- [ ] **Step 4: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/course_handler.go api/internal/delivery/http/course_type_handler.go api/internal/delivery/http/course_version_handler.go api/internal/delivery/http/course_module_handler.go
git commit -m "docs(curriculum): add swaggo annotations for course, type, version, module endpoints"
```

---

## Task 8: Course Batch Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/course_batch_handler.go`

9 methods: Create, GetByID, List, Update, Delete, GetDetail, AssignFacilitator, CreateSchedule, ListSchedules

- [ ] **Step 1: Annotate all 9 methods**

**Create:**
```go
// @Tags         course-batches
// @Param        body  body  object{course_type_id=string,facilitator_id=string,price=float64,min_students=int,max_students=int,payment_method=string,website_visible=bool}  true  "Batch data"
// @Router       /course-batches [post]
```

**GetDetail:**
```go
// @Summary      Get batch detail
// @Description  Returns full batch detail with schedule, facilitator, and enrollment info
// @Tags         course-batches
// @Param        id   path  string  true  "Batch ID"
// @Router       /course-batches/{id}/detail [get]
```

**AssignFacilitator:**
```go
// @Summary      Assign facilitator to batch
// @Tags         course-batches
// @Param        id    path  string  true  "Batch ID"
// @Param        body  body  object{facilitator_id=string}  true  "Facilitator assignment"
// @Router       /course-batches/{id}/facilitator [put]
```

**CreateSchedule:**
```go
// @Summary      Add schedule to batch
// @Description  Adds a session schedule with module, room, and time slot
// @Tags         course-batches
// @Param        id    path  string  true  "Batch ID"
// @Param        body  body  object{module_id=string,room_id=string,date=string,start_time=string,duration=int}  true  "Schedule data"
// @Router       /course-batches/{id}/schedules [post]
```

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/course_batch_handler.go
git commit -m "docs(course-batches): add swaggo annotations for batch endpoints"
```

---

## Task 9: Student Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/student_handler.go`

Methods: Create, GetByID, List, Update, Delete, GetEnrollmentHistory, GetRecommendations, GetNotes, AddNote, GetCrmLogs, AddCrmLog

- [ ] **Step 1: Annotate all 11 methods**

Tag: `students`. Base route: `/students`. Sub-routes: `/{id}/enrollment-history`, `/{id}/recommendations`, `/{id}/notes`, `/{id}/crm-logs`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/student_handler.go
git commit -m "docs(students): add swaggo annotations for student endpoints"
```

---

## Task 10: Enrollment Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/enrollment_handler.go`

Methods: EnrollStudent, GetByID, List, ListBatchSummary, UpdateStatus, UpdatePaymentStatus, GrantAppAccess, RevokeAppAccess

- [ ] **Step 1: Annotate all methods**

Tag: `enrollments`. Key endpoints:
- POST `/enrollments` — triggers auto-invoice
- GET `/enrollments/summary` — batch summary
- PUT `/enrollments/{id}/status` — status transitions
- PUT `/enrollments/{id}/payment-status` — payment updates
- POST `/enrollments/{id}/grant-app` — grant supporting app access
- POST `/enrollments/{id}/revoke-app` — revoke access

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/enrollment_handler.go
git commit -m "docs(enrollments): add swaggo annotations for enrollment endpoints"
```

---

## Task 11: Finance Handler Annotations (Invoices, Payables, Transactions, COA, Reports, Analysis)

**Files:**
- Modify: `api/internal/delivery/http/finance_handler.go`
- Modify: `api/internal/delivery/http/finance_report_handler.go`
- Modify: `api/internal/delivery/http/payable_handler.go`
- Modify: `api/internal/delivery/http/accounting_handler.go`
- Modify: `api/internal/delivery/http/accounting_bank_handler.go`

~27 endpoints across 5 handler files.

- [ ] **Step 1: Annotate finance_handler.go (invoices + transactions)**

Tags: `finance`. Routes under `/finance/invoices`, `/finance/transactions`, `/finance/journal`.

- [ ] **Step 2: Annotate finance_report_handler.go (5 report endpoints)**

Routes: `/finance/reports/balance-sheet`, `/finance/reports/profit-loss`, `/finance/reports/cash-flow`, `/finance/reports/ledger`, `/finance/reports/trial-balance`. Query params: period, branch_id.

- [ ] **Step 3: Annotate accounting_handler.go (analysis + accounting ops)**

Routes: `/finance/analysis/*` (ratios, revenue, costs, batch-profit, cash-forecast, alerts, suggestions), `/finance/coa/*`.

- [ ] **Step 4: Annotate payable_handler.go (3 endpoints)**

Routes: `/finance/payables/*`.

- [ ] **Step 5: Annotate accounting_bank_handler.go (7 endpoints)**

Routes: `/accounting/banks/*`, bank CRUD + transaction management.

- [ ] **Step 6: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/finance_handler.go api/internal/delivery/http/finance_report_handler.go api/internal/delivery/http/payable_handler.go api/internal/delivery/http/accounting_handler.go api/internal/delivery/http/accounting_bank_handler.go
git commit -m "docs(finance): add swaggo annotations for finance, accounting, reports endpoints"
```

---

## Task 12: CMS Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/cms_handler.go`

21 endpoints: Pages (3), Testimonials (4), FAQ (4), Articles (5), Media (3), SEO (2).

- [ ] **Step 1: Annotate all 21 methods**

Tag: `cms`. Routes under `/cms/pages`, `/cms/testimonials`, `/cms/faq`, `/cms/articles`, `/cms/media`, `/cms/seo`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/cms_handler.go
git commit -m "docs(cms): add swaggo annotations for CMS endpoints"
```

---

## Task 13: Marketing Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/marketing_handler.go`

15 endpoints: Posts (6), PR (4), Referral Partners (5).

- [ ] **Step 1: Annotate all 15 methods**

Tag: `marketing`. Routes: `/marketing/posts`, `/marketing/pr`, `/marketing/referral-partners`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/marketing_handler.go
git commit -m "docs(marketing): add swaggo annotations for marketing endpoints"
```

---

## Task 14: Partner Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/partner_handler.go`

13 endpoints: Partners CRUD (6), MOUs (4), Partner Groups (3).

- [ ] **Step 1: Annotate all 13 methods**

Tags: `partners`. Routes: `/partners`, `/partners/{id}/mous`, `/mous/{id}`, `/mous/expiring`, `/partner-groups`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/partner_handler.go
git commit -m "docs(partners): add swaggo annotations for partner and MOU endpoints"
```

---

## Task 15: Certificate Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/certificate_handler.go`

5 endpoints: Create, GetByID, List, Revoke, Verify (public).

- [ ] **Step 1: Annotate all 5 methods**

Tag: `certificates`. Routes: `/certificates`, `/certificates/{id}/revoke`. Public: `/certificates/verify/{code}` — no `@Security`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/certificate_handler.go
git commit -m "docs(certificates): add swaggo annotations for certificate endpoints"
```

---

## Task 16: Settings Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/settings_handler.go`

9 endpoints: Commission (2), Facilitator Levels (2), Branches (3), Holidays (2).

- [ ] **Step 1: Annotate all 9 methods**

Tag: `settings`. Routes: `/settings/commission`, `/settings/facilitator-levels`, `/settings/branches`, `/settings/holidays`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/settings_handler.go
git commit -m "docs(settings): add swaggo annotations for settings endpoints"
```

---

## Task 17: Lead Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/lead_handler.go`

8 endpoints: CRUD (5) + Convert, GetCrmLogs, AddCrmLog.

- [ ] **Step 1: Annotate all 8 methods**

Tag: `leads`. Routes: `/leads`, `/leads/{id}/convert`, `/leads/{id}/crm-logs`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/lead_handler.go
git commit -m "docs(leads): add swaggo annotations for lead endpoints"
```

---

## Task 18: Building & Room Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/location_handler.go` (or building_handler.go, room_handler.go)

11 endpoints: Buildings CRUD (5), Rooms CRUD (5), Room Availability (1).

- [ ] **Step 1: Annotate all 11 methods**

Tags: `locations`. Routes: `/buildings`, `/rooms`, `/rooms/{id}/availability`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/location_handler.go
git commit -m "docs(locations): add swaggo annotations for building and room endpoints"
```

---

## Task 19: Approval Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/approval_handler.go`

6 endpoints: List, GetByID, Create, Approve, Reject, Cancel.

- [ ] **Step 1: Annotate all 6 methods**

Tag: `approvals`. Routes: `/approvals`, `/approvals/{id}/approve`, `/approvals/{id}/reject`, `/approvals/{id}/cancel`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/approval_handler.go
git commit -m "docs(approvals): add swaggo annotations for approval endpoints"
```

---

## Task 20: Notification Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/notification_handler.go`

4 endpoints: List, GetUnreadCount, MarkAsRead, MarkAllAsRead.

- [ ] **Step 1: Annotate all 4 methods**

Tag: `notifications`. Routes: `/notifications`, `/notifications/unread-count`, `/notifications/{id}/read`, `/notifications/read-all`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/notification_handler.go
git commit -m "docs(notifications): add swaggo annotations for notification endpoints"
```

---

## Task 21: Talent Pool Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/talentpool_handler.go`

7 endpoints: List, GetByID, UpdateStatus, Professions CRUD.

- [ ] **Step 1: Annotate all 7 methods**

Tag: `talentpool`. Routes: `/talentpool`, `/talentpool/{id}/status`, `/talentpool/professions`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/talentpool_handler.go
git commit -m "docs(talentpool): add swaggo annotations for talent pool endpoints"
```

---

## Task 22: Entrepreneurship Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/business_handler.go`
- Modify: `api/internal/delivery/http/canvas_handler.go`
- Modify: `api/internal/delivery/http/design_thinking_handler.go`
- Modify: `api/internal/delivery/http/item_handler.go`

21 endpoints: Business (6), Canvas (5), Design Thinking (5), Items (5).

- [ ] **Step 1: Annotate all 4 handler files**

Tags: `entrepreneurship`. Each entity has standard CRUD + Search.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/business_handler.go api/internal/delivery/http/canvas_handler.go api/internal/delivery/http/design_thinking_handler.go api/internal/delivery/http/item_handler.go
git commit -m "docs(entrepreneurship): add swaggo annotations for business, canvas, design-thinking, item endpoints"
```

---

## Task 23: Delegation Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/delegation_handler.go`

7 endpoints: List, GetByID, Create, Update, Accept, Complete, Cancel.

- [ ] **Step 1: Annotate all 7 methods**

Tag: `delegations`. Routes: `/delegations`, `/delegations/{id}/accept`, `/delegations/{id}/complete`, `/delegations/{id}/cancel`.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/delegation_handler.go
git commit -m "docs(delegations): add swaggo annotations for delegation endpoints"
```

---

## Task 24: OKR, Investment, BMC Handler Annotations

**Files:**
- Modify: `api/internal/delivery/http/okr_handler.go`
- Modify: `api/internal/delivery/http/investment_handler.go`
- Modify: `api/internal/delivery/http/bmc_handler.go`

14 endpoints: OKR (8), Investment (4), BMC (2).

- [ ] **Step 1: Annotate okr_handler.go**

Tag: `okr`. Routes: `/okr/objectives`, `/okr/key-results`.

- [ ] **Step 2: Annotate investment_handler.go**

Tag: `investment`. Routes: `/investment/plans`.

- [ ] **Step 3: Annotate bmc_handler.go**

Tag: `bmc`. Routes: `/bmc`.

- [ ] **Step 4: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/okr_handler.go api/internal/delivery/http/investment_handler.go api/internal/delivery/http/bmc_handler.go
git commit -m "docs(bizdev): add swaggo annotations for OKR, investment, BMC endpoints"
```

---

## Task 25: Public Endpoint Annotations

**Files:**
- Modify: `api/internal/delivery/http/public_handler.go`

13 endpoints: Courses, CourseDetail, BatchDetail, Page, Testimonials, FAQ, Articles, Article, Stats, Enrollment, Contact, Certificate.

- [ ] **Step 1: Annotate all 13 methods**

Tag: `public`. Routes: `/public/*`. No `@Security` for any public endpoint.

- [ ] **Step 2: Verify build and commit**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api && go build ./...
git add api/internal/delivery/http/public_handler.go
git commit -m "docs(public): add swaggo annotations for public endpoints"
```

---

## Task 26: Generate and Validate Full Spec

**Files:**
- Generate: `api/docs/swagger/swagger.yaml`
- Generate: `api/docs/swagger/docs.go`

- [ ] **Step 1: Generate the spec**

```bash
cd /Users/erickmo/Desktop/Project/vernonedu2/api
make docs
```

Expected: `swagger.yaml` generated with all ~165 endpoints.

- [ ] **Step 2: Count endpoints in generated spec**

```bash
grep -c "^  /" api/docs/swagger/swagger.yaml
```

Expected: ~165 paths

- [ ] **Step 3: Validate spec structure**

```bash
# Check required OpenAPI fields
head -20 api/docs/swagger/swagger.yaml
# Verify paths exist
grep "paths:" api/docs/swagger/swagger.yaml
# Verify security scheme exists
grep "BearerAuth" api/docs/swagger/swagger.yaml | head -5
```

- [ ] **Step 4: Manual validation at Swagger Editor**

```bash
# Copy spec content and paste at https://editor.swagger.io
cat api/docs/swagger/swagger.yaml | pbcopy
echo "Paste at https://editor.swagger.io to validate"
```

Expected: No errors in Swagger Editor.

- [ ] **Step 5: Commit generated spec**

```bash
git add api/docs/swagger/
git commit -m "docs(api): generate OpenAPI 3.0 spec from swaggo annotations"
```

---

## Task 27: Update CLAUDE.md with API Contract Reference

**Files:**
- Modify: `api/CLAUDE.md`

- [ ] **Step 1: Add OpenAPI spec reference section to api/CLAUDE.md**

Append section:

```markdown
## API Documentation (OpenAPI 3.0)

Spec location: `api/docs/swagger/swagger.yaml`

### Commands
- `make docs` — regenerate spec from handler annotations
- `make docs-validate` — validate spec
- `make docs-serve` — serve Swagger UI at localhost:8082

### Annotation Pattern
Every handler method MUST have swaggo annotations:
```go
// MethodName godoc
// @Summary      Short description
// @Description  Detailed description
// @Tags         domain-name
// @Accept       json
// @Produce      json
// @Param        id   path      string  true  "Resource ID"
// @Success      200  {object}  map[string]interface{}
// @Failure      400  {object}  map[string]string
// @Security     BearerAuth
// @Router       /path [method]
```

### When Adding New Endpoints
1. Add handler method with swaggo annotations
2. Run `make docs` to regenerate spec
3. Verify at https://editor.swagger.io
4. Commit both handler changes and regenerated spec
```

- [ ] **Step 2: Commit**

```bash
git add api/CLAUDE.md
git commit -m "docs(claude): add OpenAPI spec reference to CLAUDE.md"
```

---

## Summary

| Task | Domain | Endpoints | Handler File |
|------|--------|-----------|-------------|
| 1 | Setup | — | go.mod, Makefile |
| 2 | Common Types | — | swagger_types.go |
| 3 | API Info | — | main.go |
| 4 | Auth | 3 | auth_handler.go |
| 5 | Users | 6 | user_handler.go |
| 6 | Departments | 10 | department_handler.go |
| 7 | Curriculum | 28 | course*.go, program_karir*.go |
| 8 | Course Batches | 9 | course_batch_handler.go |
| 9 | Students | 11 | student_handler.go |
| 10 | Enrollments | 8 | enrollment_handler.go |
| 11 | Finance | 27 | finance*.go, accounting*.go, payable*.go |
| 12 | CMS | 21 | cms_handler.go |
| 13 | Marketing | 15 | marketing_handler.go |
| 14 | Partners | 13 | partner_handler.go |
| 15 | Certificates | 5 | certificate_handler.go |
| 16 | Settings | 9 | settings_handler.go |
| 17 | Leads | 8 | lead_handler.go |
| 18 | Locations | 11 | location_handler.go |
| 19 | Approvals | 6 | approval_handler.go |
| 20 | Notifications | 4 | notification_handler.go |
| 21 | Talent Pool | 7 | talentpool_handler.go |
| 22 | Entrepreneurship | 21 | business,canvas,design_thinking,item |
| 23 | Delegations | 7 | delegation_handler.go |
| 24 | BizDev | 14 | okr,investment,bmc handlers |
| 25 | Public | 13 | public_handler.go |
| 26 | Generate | — | swagger.yaml |
| 27 | CLAUDE.md | — | CLAUDE.md |
| **Total** | | **~165** | **26 handler files** |
