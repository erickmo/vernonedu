# Finance Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `backend/domains/finance` to full alignment with `docs/domains/payment/spec.md`, `docs/domains/invoice/spec.md`, `docs/domains/profit-split/spec.md`, `docs/domains/budget/spec.md`.

**Architecture:** Single `finance` package owns Payment, PaymentTerm, PaymentTransaction, Refund, StudentCredit, Invoice, InvoiceLineItem, BatchCostLineItem, ExtraRevenue, PeriodBonus, BatchBudgetItem, BudgetRealization. Layered. Listens `enrollment.confirmed`, `payment.confirmed`, `course.batch.closed`, `enrollment.confirmed` (B2B for partner_split), `facilitator.approved` (facilitator_fee). Emits `payment.confirmed`, `payment.term.due`, `payment.term.overdue`, `invoice.sent`, `invoice.overdue`, `profit_split.calculated`. Background workers (already wired in `cmd/worker/main.go`): MarkOverdueTerms, MarkOverdueInvoices.

**Tech Stack:** Go 1.22, chi, pgx, sqlc, fx, decimal.

---

## Source-of-truth

- `docs/domains/payment/spec.md`, `docs/domains/invoice/spec.md`, `docs/domains/profit-split/spec.md`, `docs/domains/budget/spec.md`
- `backend/migrations/000004_init_finance.up.sql`
- `backend/sqlc/finance.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/finance/model.go` | All payment/invoice/profitsplit/budget enums + DTOs |
| `backend/domains/finance/repository.go` | sqlc CRUD; idempotent operations |
| `backend/domains/finance/service.go` | Business rules + workers |
| `backend/domains/finance/handler.go` | HTTP routes |
| `backend/domains/finance/events.go` | Cross-domain pub/sub |
| `backend/domains/finance/module.go` | fx wiring |

---

## Task 1: Audit gaps

- [ ] Existing service has `MarkOverdueTerms`, `MarkOverdueInvoices`. Audit other methods. Write `GAPS.md`. Commit.

---

## Task 2: Auto-create Payment + Term on enrollment.confirmed

**Files:**
- Modify: `events.go`, `service.go`
- Create: `events_payment_test.go`

- [ ] **Step 1: Failing test**

```go
func TestOnEnrollmentConfirmed_CreatesPaymentAndTerm(t *testing.T) {
	// publish enrollment.confirmed via fakeBus with final_price=500
	// expect Payment created (full, total_amount=500), 1 PaymentTerm with amount=500
}
```

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement listener** — single transaction, idempotent on `(enrollment_id)`. Skip if Payment already exists for enrollment.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): auto-create Payment+Term on enrollment.confirmed"
```

---

## Task 3: Convert to installment

**Files:**
- Modify: `service.go`
- Create: `service_installment_test.go`

- [ ] **Step 1: Failing tests**

- ConvertToInstallment requires `payment_type=full` source
- Sum of new term amounts must equal `total_amount`
- Original full term replaced by N new terms in single transaction
- If credit was applied: credit allocation preserved on first term(s)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with transactional rewrite of payment terms.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): convert payment to installment"
```

---

## Task 4: Gateway webhook handling (idempotent)

**Files:**
- Modify: `handler.go`, `service.go`
- Create: `service_webhook_test.go`

Spec: idempotent webhook; pending > 24h cancelled; webhook for dropped enrollment rejected.

- [ ] **Step 1: Failing tests**

- Webhook for unknown gateway_ref → 404
- First webhook → tx.status=confirmed, term updated, payment.paid_amount updated
- Duplicate webhook (already confirmed) → 200, no double-confirmation
- Webhook for tx of dropped enrollment → tx.status=cancelled, payment unchanged
- Webhook firing payment fully paid → fires `payment.confirmed`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** in service. Use SQL `INSERT ... ON CONFLICT DO NOTHING` semantics or row-level lock + status check.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): idempotent gateway webhook handling"
```

---

## Task 5: Bank transfer admin confirmation

**Files:**
- Modify: `service.go`, `handler.go`

- [ ] **Step 1: Failing tests**

- StudentUploadProof sets `proof_url` on tx (status remains pending)
- AdminConfirmTransaction → tx.status=confirmed, sets confirmed_by, confirmed_at
- AdminConfirmTransaction on already-confirmed → no-op (idempotent)
- Admin reject → tx.status=cancelled (logged reason)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): bank transfer confirm flow"
```

---

## Task 6: Refund + StudentCredit

**Files:**
- Modify: `service.go`
- Create: `service_refund_test.go`

- [ ] **Step 1: Failing tests** for each refund_type:

- `full` → Refund created, refund_amount = paid_amount
- `partial` → custom amount; admin sets
- `no_refund` → record only
- `credit` → StudentCredit created with `amount = credit_amount`, `remaining_amount = credit_amount`
- StudentCredit applied at next enrollment reduces outstanding (covered cross-domain)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): refund processing with credit creation"
```

---

## Task 7: Invoice auto-create (B2B) on enrollment.confirmed

**Files:**
- Modify: `events.go`
- Create: `events_invoice_test.go`

Spec rule 0: B2B (`payer=partner`) auto-creates draft invoice; B2C is manual.

- [ ] **Step 1: Failing tests**

- enrollment.confirmed with payer=partner → Invoice created status=draft, billed_to=partner
- enrollment.confirmed with payer=student (B2C or B2B-student-payer) → no invoice auto-created
- Idempotent: duplicate event does not create second invoice (DB partial unique constraint enforces)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement listener** + ensure migration has:

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_invoice_enrollment_active
  ON invoices (enrollment_id) WHERE status != 'cancelled';
```

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): auto-create draft invoice for B2B"
```

---

## Task 8: Invoice line items + status transitions

**Files:**
- Modify: `service.go`
- Create: `service_invoice_test.go`

- [ ] **Step 1: Failing tests**

- AddLineItem allowed only when status=draft
- AddLineItem on sent/paid → rejected
- TotalAmount computed = sum of line item amounts (negative items deduct)
- SendInvoice (draft → sent) fires `invoice.sent`
- payment.confirmed listener: invoice with linked payment → status=paid (auto)
- CancelInvoice from draft/sent allowed; from paid rejected

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): invoice line items and state transitions"
```

---

## Task 9: Background overdue checks

**Files:**
- Verify existing in `service.go`: `MarkOverdueTerms`, `MarkOverdueInvoices`
- Create: `service_overdue_test.go`

- [ ] **Step 1: Failing tests**

- MarkOverdueTerms transitions PaymentTerm `unpaid` AND `due_date < today` → `overdue`; fires `payment.term.overdue`
- MarkOverdueInvoices transitions Invoice `sent` AND `due_date < today` → `overdue`; fires `invoice.overdue`
- Already-overdue rows skipped (no event re-fired)

- [ ] **Step 2: FAIL** (or PASS if already implemented — verify event firing)

- [ ] **Step 3: Implement / fix**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): overdue checks fire events"
```

---

## Task 10: Transaction timeout job

**Files:**
- Modify: `service.go`, `cmd/worker/main.go`

- [ ] **Step 1: Failing test**

- TimeoutPendingTransactions cancels PaymentTransaction `pending` AND `created_at < now() - 24h`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** + register worker tick in `cmd/worker/main.go`.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): cancel stale pending transactions"
```

---

## Task 11: Profit-split calculation on course.batch.closed

**Files:**
- Modify: `events.go`, `service.go`
- Create: `service_profitsplit_test.go`

Spec: `docs/domains/profit-split/spec.md`.

- [ ] **Step 1: Failing tests**

- On `course.batch.closed`: net_profit = revenue - costs; split per `course.profit_split_override` or globals; sum of pcts = 100; fire `profit_split.calculated`
- Negative net_profit recorded, not blocked
- ExtraRevenue with `approval_status=approved` included; pending excluded
- BatchCostLineItem with `is_removed=true` excluded
- `cost_type=percentage_of_revenue` calculated against gross revenue
- Idempotent: re-firing event does not double-record (use unique on `(batch_id)` for split record)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** calculator + listener.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): profit-split calculation on batch close"
```

---

## Task 12: Auto-create cost line items (partner_split, facilitator_fee)

**Files:**
- Modify: `events.go`
- Create: `events_cost_autogen_test.go`

- [ ] **Step 1: Failing tests**

- enrollment.confirmed with payer=partner → BatchCostLineItem(reference_type=partner_split, reference_id=agreement_id, amount=resolved per payment_model)
- facilitator.approved → BatchCostLineItem(reference_type=facilitator_fee, reference_id=proposal_id, amount=fee per fee_basis)
- Re-firing same event → no duplicate (unique on (course_batch_id, reference_type, reference_id))

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Migration if missing**

```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_batch_cost_ref
  ON batch_cost_line_items (course_batch_id, reference_type, reference_id)
  WHERE reference_type != 'manual' AND reference_id IS NOT NULL;
```

- [ ] **Step 4: Implement listeners**

- [ ] **Step 5: PASS**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(finance): auto-create partner_split and facilitator_fee cost items"
```

---

## Task 13: ExtraRevenue with CEO approval

**Files:**
- Modify: `service.go`, `handler.go`

- [ ] **Step 1: Failing tests**

- AddExtraRevenue by Finance role → status=pending
- Approve by CEO → status=approved; counted in revenue
- Reject by CEO → status=rejected; not counted

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): extra revenue with CEO approval"
```

---

## Task 14: Period Bonus rollup (monthly)

**Files:**
- Modify: `service.go`, `cmd/worker/main.go`

- [ ] **Step 1: Failing tests**

- CalculatePeriodBonus(period="2026-04") aggregates all batches closed in period
- Status=draft until admin Finalize
- Per-creator and per-dept-leader aggregations correct
- Negative net_profit reduces totals

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** + admin endpoint to trigger; worker schedules monthly.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): period bonus rollup"
```

---

## Task 15: Budget realization

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_budget_test.go`

Spec: `docs/domains/budget/spec.md`.

- [ ] **Step 1: Failing tests**

- BatchBudgetItem inherited from CourseBudgetTemplate on batch creation (already in catalog plan? — verify here)
- BatchBudgetItem.planned_amount editable only if `overridable=true`
- BudgetRealization rejected when class doesn't match item's class (if class-mapped)
- Multiple realizations per item allowed; total = SUM
- Variance computed = planned - SUM(actual)
- Over-budget allowed (no block)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** budget item mutation rules + realization CRUD.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(finance): budget realization tracking"
```

---

## Task 16: Wire HTTP routes

**Files:**
- Modify: `handler.go`, `module.go`

- [ ] **Step 1: Mount routes**

```
POST   /payments/{id}/installments        [admin]
POST   /payments/transactions/webhook     [public — gateway]
POST   /payments/transactions/{id}/proof  [student (own)]
POST   /payments/transactions/{id}/confirm [admin]
POST   /enrollments/{id}/refund           [admin]
POST   /invoices                          [admin]
POST   /invoices/{id}/line-items          [admin]
POST   /invoices/{id}/send                [admin]
POST   /invoices/{id}/cancel              [admin]
POST   /extra-revenue                     [finance]
POST   /extra-revenue/{id}/approve        [ceo]
POST   /period-bonus/calculate            [admin]
POST   /period-bonus/{id}/finalize        [admin]
POST   /batches/{id}/budget-realizations  [admin]
GET    /batches/{id}/budget-summary       [admin, dept_leader, course_creator(own)]
```

- [ ] **Step 2: Implement handlers**

- [ ] **Step 3: Smoke test** including webhook idempotency (curl twice)

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(finance): mount HTTP routes"
```

---

## Task 17: Verify + lint

- [ ] `cd backend && go test -race ./domains/finance/...`
- [ ] `cd backend && golangci-lint run ./domains/finance/...`
- [ ] Remove `GAPS.md`. Commit.

---

## Verification

1. Trigger enrollment.confirmed → expect Payment+Term created
2. Send gateway webhook (twice) → expect single confirmation, payment.confirmed fired
3. Drop enrollment, refund as credit → expect StudentCredit row created
4. Send invoice → invoice.sent event; mark overdue manually past due → invoice.overdue event
5. Close batch → profit-split calculated event; period bonus rollup includes it
6. Worker process: simulate 24h-old pending tx → cancelled
