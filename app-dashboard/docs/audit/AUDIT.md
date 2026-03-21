# Code Quality & Audit — app-dashboard

> Code quality standards, lint rules, known tech debt, and pattern compliance.

---

## Lint Rules

Flutter analyze must pass with **zero warnings** before any PR.

Key rules enforced:
- `prefer_function_declarations_over_variables` — use `String fmt(int v) {...}` not `final fmt = (int v) {...}`
- `prefer_const_constructors` — use `const` wherever possible
- `avoid_print` — use proper logging, not `print()`
- `always_use_package_imports` — no relative imports

---

## Architecture Compliance

### Required patterns (all domains)

| Rule | Correct | Violation |
|------|---------|-----------|
| State management | Cubit + Equatable states | FutureBuilder, setState for async data |
| Data access | Repository → UseCase → Cubit | Direct `ApiClient.dio` calls from widgets |
| Error handling | `Either<Failure, T>` from repository | Try/catch in presentation layer |
| DI | get_it registered in `injection.dart` | Manual instantiation in widgets |
| Constants | `AppColors`, `AppStrings`, `AppDimensions` | Hardcoded values |
| Business logic | In UseCase or Cubit | In `build()` method |

---

## Known Tech Debt

### Critical

| Domain | Issue | Priority |
|--------|-------|----------|
| Certificate | Uses `ApiClient.dio` directly + `FutureBuilder` — violates cubit pattern | High |
| Certificate | Issuance is local state only, no API write | High |
| Accounting | Full UI with **mock data**, no `data/` or `domain/` layers | High |
| Auth | Single role per user — needs multi-role support | High |
| Mentor role | `mentor` role still in system — should be removed (merged into `facilitator`) | Medium |

### Moderate

| Domain | Issue | Priority |
|--------|-------|----------|
| Evaluation | Empty shell — directories exist but no implementation | Medium |
| Payment | Empty shell — directories exist but no implementation | Medium |
| CRM | Shell only — no `data/` or `domain/` directories | Low |
| Project Management | Shell only — no `data/` or `domain/` directories | Low |

### Error Pattern Inconsistency

Two patterns coexist:
1. **Standard:** `DioException` propagates from datasource → caught in repository impl (most domains)
2. **SDM variant:** Datasource throws `ServerFailure` → repository catches `ServerFailure`

**Recommendation:** Standardize on pattern #1 across all domains.

---

## New Roles Not Yet Implemented

The following roles exist in the org chart but not in the codebase:
- `education_leader`
- `operation_leader`
- `operation_admin`
- `marketing`
- `accounting_leader`
- `accounting_staff`

---

## New Domains Not Yet Implemented

- Approval workflow engine
- Notification center
- Location management (Building/Room with facilities)
- Ads template system
- Batch budgeting
- Invoice auto-generation
- Certificate template system + QR verification
- Competency test system
- Partner & MOU management
- Leads management
- Business Development (BMC, Branch/Franchise, OKR/KPI, Investment, Projections, Delegation)
- Role-based dashboard views

---

## Audit Checklist (per PR)

- [ ] `make analyze` passes with zero warnings
- [ ] `make test` passes
- [ ] No hardcoded strings/colors/dimensions
- [ ] Repository returns `Either<Failure, T>`
- [ ] All UI states handled: loading / success / error / empty
- [ ] No business logic in `build()`
- [ ] DI registered in `injection.dart`
- [ ] Code generation run if models changed (`make gen`)
- [ ] No direct `ApiClient.dio` usage in presentation layer
- [ ] New domain follows clean architecture folder structure
