# Student Management Design

**Date:** 2026-04-28
**Domain:** `identity`
**Approach:** Split per-subdomain files within `identity` domain

---

## Overview

Complete student management within the `identity` domain. Covers CRUD, profile management, advanced search/filter, and role-based access for both admin and student self-service.

---

## API Endpoints

### Admin (JWT + role: `ceo` | `vernonedu_admin` | `admin`)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/students` | List students with advanced filter (upgrade existing) |
| `GET` | `/api/v1/students/{id}` | Get student by ID (existing) |
| `PUT` | `/api/v1/students/{id}` | Update student core fields |
| `GET` | `/api/v1/students/{id}/profile` | Get student profile |
| `PUT` | `/api/v1/students/{id}/profile` | Update any student profile |

### Student Self-Service (JWT + role: `student`, own record only)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/me/student` | Get own student record |
| `PUT` | `/api/v1/me/student/profile` | Update own profile |

---

## Data Layer

### StudentFilter

```go
type StudentFilter struct {
    Source          *StudentSource
    PartnerID       *uuid.UUID
    Search          string     // ILIKE on name OR email
    ProfileComplete *bool
    SortBy          string     // "name" | "email" | "created_at" (default)
    SortDir         string     // "asc" | "desc" (default: "desc")
    Limit           int
    Offset          int
}
```

### Repository Methods (repository_student.go)

Moved from `repository.go`:
- `CreateStudent(ctx, s *Student) error`
- `GetStudentByID(ctx, id uuid.UUID) (*Student, error)`
- `GetStudentByUserID(ctx, userID uuid.UUID) (*Student, error)`

Replaced:
- `ListStudents` → `ListStudentsFiltered(ctx, filter StudentFilter) ([]*Student, error)`

New:
- `CountStudentsFiltered(ctx, filter StudentFilter) (int, error)`
- `UpdateStudent(ctx, s *Student) error`
- `CreateStudentProfile(ctx, p *StudentProfile) error`
- `GetStudentProfile(ctx, studentID uuid.UUID) (*StudentProfile, error)`
- `UpdateStudentProfile(ctx, p *StudentProfile) error`

---

## File Structure

```
identity/
  handler.go              ← auth, me, user, department (student handlers removed)
  handler_student.go      ← student HTTP handlers (new)
  service.go              ← Register, Login, GetMe, etc. (student methods removed)
  service_student.go      ← student service methods (new)
  repository.go           ← repo interface + auth/user/team methods (student methods removed)
  repository_student.go   ← student repo interface extension + impl (new)
```

---

## Register Flow Change

`Register` in `service.go`: after `CreateStudent`, auto-create empty `student_profiles` row in same transaction.

```
CreateUser → if role=student → CreateStudent → CreateStudentProfile (empty)
```

---

## Profile Completion

`profile_complete` flag on `student_profiles` is set to `true` by service layer when all required fields are non-null: `date_of_birth`, `gender`, `id_type`, `id_number`, `address`, `city`, `province`, `postal_code`.

---

## RBAC Rules

| Action | Admin | Student (own) | Student (other) |
|--------|-------|---------------|-----------------|
| List students | ✓ | ✗ | ✗ |
| Get student | ✓ | via `/me/student` | ✗ |
| Update student core | ✓ | ✗ | ✗ |
| Get profile | ✓ | via `/me/student` | ✗ |
| Update profile | ✓ | via `/me/student/profile` | ✗ |

Admin roles: `ceo`, `vernonedu_admin`, `admin`.

---

## Testing

### Integration Tests (`service_student_integration_test.go`)

- Register → `student_profiles` row auto-created
- `ListStudentsFiltered` → filter by `source`
- `ListStudentsFiltered` → filter by `partner_id`
- `ListStudentsFiltered` → search by `name` (ILIKE)
- `ListStudentsFiltered` → search by `email` (ILIKE)
- `ListStudentsFiltered` → filter by `profile_complete`
- `ListStudentsFiltered` → sort by `name` asc/desc
- `CountStudentsFiltered` → returns correct count
- `UpdateStudent` → admin updates core fields
- `GetStudentProfile` → returns profile by `student_id`
- `UpdateStudentProfile` → student updates own profile
- `UpdateStudentProfile` → sets `profile_complete=true` when all fields filled

### HTTP Layer Tests (`handler_student_test.go`)

- `PUT /api/v1/students/{id}` → 403 if `role=student`
- `PUT /api/v1/students/{id}/profile` → 403 if `role=student`
- `PUT /api/v1/me/student/profile` → 403 if `role=admin`
- `PUT /api/v1/me/student/profile` → 403 if student targets other student's profile

---

## Out of Scope

- Hard delete (soft delete only via existing `DeactivateUser`)
- Partner-scoped student visibility (future: partnerships domain)
- Student document upload
