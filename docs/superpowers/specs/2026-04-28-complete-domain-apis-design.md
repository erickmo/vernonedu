# Complete All Domain APIs — Design Spec

**Date:** 2026-04-28  
**Status:** Approved  
**Scope:** Fix service stubs + add handler RBAC tests for all incomplete domains

---

## Goal

Bring all 12 incomplete backend domains to the same "done" standard already established by `identity`, `module`, and `budget`:
- No invalid service stubs
- HTTP handler tests covering 401 / 403 / 2xx per endpoint

---

## Reference Standard

Completed domains to copy patterns from:
- `backend/domains/module/handler_test.go` — RBAC test pattern
- `backend/domains/budget/handler_test.go` — alternate RBAC pattern
- `backend/domains/identity/handler_student_test.go` — student-specific RBAC

---

## Architecture

### Per-Domain Work Pattern

**Step 1 — Audit & fix service stubs**

Identify all `return nil, nil` or bare `return nil` that represent unimplemented logic (not valid early-returns). Implement correct logic or publish missing events.

Known stubs requiring fixes:
- `platform/service.go` — `Send()` returns `nil, nil` (notification never delivered)
- `partnerships/service.go` — `TerminateAgreement()` returns `nil` without any state change
- `calendar/service.go` — several event handler methods return `nil` mid-logic

**Step 2 — Write handler_test.go**

For every endpoint registered in `module.go`, write three test cases:
1. Unauthenticated request → `401 Unauthorized`
2. Wrong role → `403 Forbidden`
3. Correct role + valid payload → `2xx`

Use shared `buildRouter` helper (same pattern as `module` domain).

### Branch Strategy

One branch per domain: `feat/complete-<domain>-api`  
Merge to `main` after each domain passes all tests and linter.

---

## Domain Work Order

Priority based on business risk (active bugs first, then coverage gaps):

| # | Domain | Fix Stubs | Handler Tests | Routes | Notes |
|---|--------|-----------|---------------|--------|-------|
| 1 | platform | `Send()` nil,nil | 2 | platform.ListMyNotifications, platform.MarkRead | Active bug — notifications never sent |
| 2 | notification | minor returns | 9 | Full notification CRUD + templates | Zero coverage |
| 3 | partnerships | `TerminateAgreement` | 6 | Partners + agreements | State mutation stub |
| 4 | calendar | event handler stubs | 12 | Most routes in project | Complex event integration |
| 5 | credentialing | none expected | 6 | Credentials + verification | Audit first |
| 6 | enrollment | none expected | 5 | Enrollment lifecycle | Audit first |
| 7 | franchise | none expected | 9 | Franchisee + royalty | Audit first |
| 8 | voucher | none expected | 6 | Voucher CRUD + apply | Audit first |
| 9 | profit_split | none expected | 12 | Split config + batch costs | Audit first |
| 10 | team_member | none expected | 8 | Team + proposals | Audit first |
| 11 | catalog | TBD (audit) | TBD | Audit required | |
| 12 | finance | TBD (audit) | TBD | Audit required | |

---

## Definition of Done (per domain)

- [ ] All `return nil` stubs replaced with correct implementation or explicit TODO with tracked issue
- [ ] `handler_test.go` covers every registered endpoint: 401 + 403 + 2xx
- [ ] `go test ./domains/<domain>/...` — all pass
- [ ] `golangci-lint run ./domains/<domain>/...` — clean
- [ ] Branch merged to main

---

## Out of Scope

- New endpoints not already defined in `module.go`
- Frontend API integration
- Performance optimization
- Database schema changes
