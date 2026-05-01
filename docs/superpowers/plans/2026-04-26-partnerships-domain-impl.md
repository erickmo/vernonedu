# Partnerships Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `backend/domains/partnerships` to full alignment with `docs/domains/partner/spec.md`, `docs/domains/partnership-agreement/spec.md`, `docs/domains/franchise/spec.md`.

**Architecture:** Single `partnerships` package owns Partner, PartnershipAgreement, PartnerDocument, Franchisee, FranchiseAgreement, BranchOtherRevenue, RoyaltyPaymentRecord. Layered. Background jobs: agreement expiry (daily), royalty overdue (monthly).

**Tech Stack:** Go 1.22, chi, pgx, sqlc, fx, decimal.

---

## Source-of-truth

- `docs/domains/partner/spec.md`, `docs/domains/partnership-agreement/spec.md`, `docs/domains/franchise/spec.md`
- `backend/migrations/000006_init_partnerships.up.sql`
- `backend/sqlc/partnerships.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/partnerships/model.go` | PartnerType, PartnerStatus, AgreementStatus, PaymentModel, FranchiseeStatus, RoyaltyStatus enums |
| `backend/domains/partnerships/repository.go` | sqlc CRUD |
| `backend/domains/partnerships/service.go` | Business rules + workers |
| `backend/domains/partnerships/handler.go` | HTTP routes |
| `backend/domains/partnerships/events.go` | Publishers |
| `backend/domains/partnerships/module.go` | fx wiring |

---

## Task 1: Audit gaps

- [ ] List entities/methods. Write `GAPS.md`. Commit.

---

## Task 2: Partner CRUD + status auto-transitions

**Files:**
- Modify: `service.go`
- Create: `service_partner_test.go`

- [ ] **Step 1: Failing tests**

- CreatePartner default status=lead
- Partner.status auto-transitions on agreement state:
  - First agreement activated → partner.status=active, fires `partner.status_changed`
  - All agreements expired/terminated → partner.status=inactive
- DuplicatePartner check by name not enforced (per spec — multiple "Lead" entries acceptable)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with reactive update inside agreement state-change methods.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): partner CRUD with status auto-transitions"
```

---

## Task 3: PartnershipAgreement state machine

**Files:**
- Modify: `service.go`
- Create: `service_agreement_test.go`

States: draft → active → expired/terminated.

- [ ] **Step 1: Failing tests**

- ActivateAgreement requires draft source
- ActivateAgreement enforces only-one-active-per-partner (DB unique partial index — surfaces as conflict)
- ActivateAgreement fires `partnership_agreement.activated`
- ExpireAgreement (manual or auto) fires `partnership_agreement.expired`
- TerminateAgreement requires `termination_reason`; fires `partnership_agreement.terminated`
- B2B enrollment cannot reference draft agreement (queryHelper for enrollment domain returns nil if draft)

- [ ] **Step 2: Migration if missing partial unique index**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_partner_active_agreement
  ON partnership_agreements (partner_id) WHERE status = 'active';
```

- [ ] **Step 3: FAIL**

- [ ] **Step 4: Implement state transitions + events**

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(partnerships): agreement state machine with unique active constraint"
```

---

## Task 4: Daily agreement expiry worker

**Files:**
- Modify: `service.go`, `cmd/worker/main.go`

- [ ] **Step 1: Failing test**

- ExpireOverdueAgreements: any active agreement with `end_date < today` → status=expired, fires event
- end_date=null → never expires (open-ended)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** + register worker tick (daily).

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): daily agreement expiry worker"
```

---

## Task 5: PartnerDocument upload

**Files:**
- Modify: `service.go`, `handler.go`
- Create: `service_document_test.go`

- [ ] **Step 1: Failing tests**

- UploadDocument returns PartnerDocument record
- File storage: stub interface (S3-compatible later); for now, store URL provided by caller
- Upload allowed at any agreement status

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with `Storage` interface stub (impl returns input URL untouched).

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): document upload"
```

---

## Task 6: Franchisee + FranchiseAgreement CRUD

**Files:**
- Modify: `service.go`
- Create: `service_franchisee_test.go`

- [ ] **Step 1: Failing tests**

- CreateFranchisee — admin only (handler enforces)
- CreateFranchiseAgreement: `revenue_royalty_pct ∈ [0, 100]`
- Set agreement.status=active; set franchisee.status=active

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): franchisee and franchise agreement CRUD"
```

---

## Task 7: BranchOtherRevenue + gross-revenue computation

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_branch_revenue_test.go`

- [ ] **Step 1: Failing tests**

- AddBranchOtherRevenue stores entry; computed in gross_revenue
- ComputeGrossRevenue(franchiseeID, period) = SUM(enrollments.final_price WHERE franchisee_id=X AND created_at IN period) + SUM(branch_other_revenue.amount WHERE same)
- Period = "2026-04" → date range [2026-04-01, 2026-04-30]

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with cross-domain SQL join into enrollments table.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): gross branch revenue computation"
```

---

## Task 8: RoyaltyPaymentRecord generation + payment

**Files:**
- Modify: `service.go`
- Create: `service_royalty_test.go`

- [ ] **Step 1: Failing tests**

- GenerateRoyaltyRecord(agreementID, period) computes:
  - gross_revenue = ComputeGrossRevenue(...)
  - revenue_royalty = gross_revenue × revenue_royalty_pct / 100
  - total_royalty = monthly_royalty + revenue_royalty
  - status=unpaid
- MarkRoyaltyPaid sets status=paid, paid_at=now()
- Idempotent: duplicate generate for same (agreement, period) returns existing

- [ ] **Step 2: Migration if missing**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_royalty_agreement_period
  ON royalty_payment_records (franchise_agreement_id, period);
```

- [ ] **Step 3: FAIL**

- [ ] **Step 4: Implement**

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(partnerships): royalty record generation and payment"
```

---

## Task 9: Royalty overdue worker (monthly, 15th)

**Files:**
- Modify: `service.go`, `cmd/worker/main.go`

- [ ] **Step 1: Failing test**

- MarkOverdueRoyalties: status=unpaid AND period_end_date < today - 14 days → status=overdue

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** + worker tick. (Schedule on 15th of month — for now, run daily and check date-based predicate.)

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): mark overdue royalties"
```

---

## Task 10: Partner meeting → Calendar integration

**Files:**
- Modify: `service.go`, `events.go`
- Create: `service_meeting_test.go`

- [ ] **Step 1: Failing tests**

- ScheduleMeeting(agreementID, start_at, end_at, agenda) fires `partnership_agreement.meeting_scheduled`
- Calendar listens (cross-domain, in platform plan) and creates CalendarEvent

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** publisher.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(partnerships): schedule partner meeting event"
```

---

## Task 11: Wire HTTP routes

**Files:**
- Modify: `handler.go`, `module.go`

- [ ] **Step 1: Mount routes**

```
POST   /partners                                         [admin]
PATCH  /partners/{id}                                    [admin]
GET    /partners/{id}                                    [admin, finance, ceo]
POST   /partners/{id}/agreements                         [admin]
POST   /agreements/{id}/activate                         [admin, ceo]
POST   /agreements/{id}/terminate                        [ceo]
POST   /agreements/{id}/documents                        [admin]
POST   /agreements/{id}/meetings                         [admin]

POST   /franchisees                                      [admin]
POST   /franchisees/{id}/agreements                      [admin, ceo]
POST   /franchisees/{id}/branch-other-revenue            [admin]
POST   /franchise-agreements/{id}/royalty/{period}       [admin]
POST   /royalty-records/{id}/mark-paid                   [admin]
GET    /franchisees/{id}/revenue-report                  [franchisee(own), admin, ceo, finance]
```

- [ ] **Step 2: Implement handlers**

- [ ] **Step 3: Smoke test**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(partnerships): mount HTTP routes"
```

---

## Task 12: Verify + lint

- [ ] `cd backend && go test -race ./domains/partnerships/...`
- [ ] `cd backend && golangci-lint run ./domains/partnerships/...`
- [ ] Remove `GAPS.md`. Commit.

---

## Verification

1. Create Partner (lead) → create agreement (draft) → activate → expect partner.status=active and `partnership_agreement.activated` event
2. Try to activate second agreement for same partner → expect 409
3. Set end_date past, run expiry worker → expect status=expired
4. Create franchisee + agreement; add BranchOtherRevenue
5. Generate royalty record for period → expect computed total_royalty correct vs enrollment amounts
6. Schedule partner meeting → expect Calendar event created (verified via platform domain)
