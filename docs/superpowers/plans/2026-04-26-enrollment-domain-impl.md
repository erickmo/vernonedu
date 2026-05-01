# Enrollment Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `backend/domains/enrollment` to full alignment with `docs/domains/enrollment/spec.md` + `docs/domains/voucher/spec.md`.

**Architecture:** Single `enrollment` package owns Enrollment, Voucher, VoucherUsage. Layered model→repo→service→handler→events. Emits `enrollment.confirmed`, `enrollment.completed`, `enrollment.dropped`. Listens to `enrollment.confirmed` (own) → mark voucher used. Cross-domain: reads CourseBatch, CourseFormatConfig from catalog; PartnershipAgreement from partnerships; StudentCredit from finance.

**Tech Stack:** Go 1.22, chi, pgx, sqlc, fx, decimal.

---

## Source-of-truth

- `docs/domains/enrollment/spec.md`, `docs/domains/voucher/spec.md`
- `backend/migrations/000003_init_enrollment.up.sql`
- `backend/sqlc/enrollment.sql`

## File Structure

| File | Responsibility |
|---|---|
| `backend/domains/enrollment/model.go` | Format, Mode, Payer, Source, PaymentStatus, CompletionStatus, DiscountType enums + DTOs |
| `backend/domains/enrollment/repository.go` | sqlc CRUD + atomic voucher consume |
| `backend/domains/enrollment/service.go` | Validation, pricing resolution, voucher application, credit application, completion, drop |
| `backend/domains/enrollment/handler.go` | HTTP routes |
| `backend/domains/enrollment/events.go` | Publishers + own-event listener |
| `backend/domains/enrollment/module.go` | fx wiring |

---

## Task 1: Audit gaps

- [ ] List existing types/methods, compare with spec, write `GAPS.md`. Commit.

```bash
git commit -m "chore(enrollment): audit gaps vs spec"
```

---

## Task 2: Pricing resolver (pure function, no IO)

**Files:**
- Create: `backend/domains/enrollment/pricing.go`
- Create: `backend/domains/enrollment/pricing_test.go`

- [ ] **Step 1: Failing tests** covering each branch of spec "Pricing Resolution":

```
B2B payer=partner with batch_bulk_price → batch_bulk_price
B2B payer=partner without batch_bulk_price, with agreement.bulk_price → agreement.bulk_price
B2B payer=partner without either → batch.price
B2B payer=student → same fallback chain; voucher applies; invoice billed to student
B2C without voucher → batch.price
B2C with fixed_amount voucher → max(0, price - voucher.value)
B2C with percentage voucher → price × (1 - value/100)
B2C with fixed_final_price voucher → voucher.value (may be < min_price; allowed)
```

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement pure function**

```go
type ResolveInput struct {
	BatchPrice            decimal.Decimal
	BatchBulkPrice        *decimal.Decimal
	AgreementBulkPrice    *decimal.Decimal
	IsB2B                 bool
	Payer                 Payer
	Voucher               *Voucher
}

type ResolveOutput struct {
	Price      decimal.Decimal // pre-voucher
	FinalPrice decimal.Decimal // after voucher
}

func ResolvePrice(in ResolveInput) ResolveOutput {
	price := in.BatchPrice
	if in.IsB2B {
		switch {
		case in.BatchBulkPrice != nil:
			price = *in.BatchBulkPrice
		case in.AgreementBulkPrice != nil:
			price = *in.AgreementBulkPrice
		}
	}
	final := price
	if in.Voucher != nil && (!in.IsB2B || in.Payer == PayerStudent) {
		final = applyVoucher(price, *in.Voucher)
	}
	return ResolveOutput{Price: price, FinalPrice: final}
}

func applyVoucher(price decimal.Decimal, v Voucher) decimal.Decimal {
	switch v.DiscountType {
	case DiscountFixedAmount:
		out := price.Sub(v.DiscountValue)
		if out.IsNegative() {
			return decimal.Zero
		}
		return out
	case DiscountPercentage:
		factor := decimal.NewFromInt(1).Sub(v.DiscountValue.Div(decimal.NewFromInt(100)))
		return price.Mul(factor)
	case DiscountFixedFinalPrice:
		return v.DiscountValue
	}
	return price
}
```

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(enrollment): pricing resolver"
```

---

## Task 3: Voucher consume (atomic)

**Files:**
- Modify: `repository.go`, `service.go`
- Create: `service_voucher_test.go`

Spec: `docs/domains/voucher/spec.md` rules 6, 12.

- [ ] **Step 1: Failing tests**

- ConsumeVoucher with `assigned_to=null` succeeds; `assigned_to=other student` rejected
- ConsumeVoucher with expired (`valid_until < today`) rejected
- ConsumeVoucher with `is_active=false` rejected
- ConsumeVoucher race: two concurrent consumes for same enrollment → exactly one succeeds (verified via go-routine + DB unique constraint on `voucher_usage(enrollment_id)`)
- ConsumeVoucher when `used_count = max_uses` rejected

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** with single SQL transaction:

```sql
-- name: ConsumeVoucher :one
WITH locked AS (
  SELECT id FROM vouchers
  WHERE id = $1
    AND is_active = true
    AND (valid_until IS NULL OR valid_until >= current_date)
    AND (max_uses IS NULL OR used_count < max_uses)
  FOR UPDATE
)
UPDATE vouchers SET used_count = used_count + 1 WHERE id = (SELECT id FROM locked) RETURNING *;
```

Followed by `INSERT INTO voucher_usages(...) ON CONFLICT (enrollment_id) DO NOTHING RETURNING id`. If no row inserted, return `apperrors.Conflict("voucher already used for this enrollment")`.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(enrollment): atomic voucher consume"
```

---

## Task 4: Create enrollment (B2C, B2B partner-payer, B2B student-payer)

**Files:**
- Modify: `service.go`
- Create: `service_create_test.go`

- [ ] **Step 1: Failing tests**

- B2C web self-enroll requires batch.web_registration_open=true
- Outside `[registration_open_at, registration_close_at]` blocked
- Format not in CourseFormatConfig → rejected
- `inhouse_training` and `inschool_program` rejected if `source=b2c`
- max_students reached → rejected
- Duplicate `(student, course_batch)` → rejected (DB unique)
- Successful create fires `enrollment.confirmed` with `{enrollment_id, student_id, course_batch_id, source}`
- B2B with bulk price uses agreement bulk price (verified via stub agreement repo)
- B2B payer=student → invoice billed to student (verified by checking event payload)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement `Create` method**

```go
func (s *Service) Create(ctx context.Context, in CreateInput) (*Enrollment, error) {
	batch, err := s.catalog.GetBatch(ctx, in.BatchID)
	if err != nil {
		return nil, err
	}
	if err := s.validateBatchOpen(in, batch); err != nil {
		return nil, err
	}
	formatCfg, err := s.catalog.GetFormatConfig(ctx, batch.CourseID, in.Format)
	if err != nil || !formatCfg.IsEnabled {
		return nil, apperrors.Validationf("format not enabled")
	}
	if formatCfg.MaxStudents != nil {
		count, _ := s.repo.CountEnrollments(ctx, batch.ID, in.Format)
		if count >= *formatCfg.MaxStudents {
			return nil, apperrors.Validationf("batch full for format %s", in.Format)
		}
	}
	priceIn := ResolveInput{ BatchPrice: batch.Price, BatchBulkPrice: batch.BatchBulkPrice }
	if in.PartnerID != nil {
		ag, _ := s.partnerships.GetActiveAgreement(ctx, *in.PartnerID)
		if ag != nil {
			priceIn.AgreementBulkPrice = ag.BulkPrice
			priceIn.IsB2B = true
			priceIn.Payer = ag.Payer
		}
	}
	if in.VoucherID != nil {
		v, err := s.repo.GetVoucherForUse(ctx, *in.VoucherID, in.StudentID, batch)
		if err != nil {
			return nil, err
		}
		priceIn.Voucher = v
	}
	resolved := ResolvePrice(priceIn)
	en, err := s.repo.CreateEnrollment(ctx, CreateParams{
		StudentID: in.StudentID, CourseBatchID: batch.ID, Format: in.Format, Mode: in.Mode,
		Payer: priceIn.Payer, PartnerID: in.PartnerID, Price: resolved.Price, FinalPrice: resolved.FinalPrice,
		VoucherID: in.VoucherID, Source: in.Source,
	})
	if err != nil {
		return nil, err
	}
	if in.VoucherID != nil {
		_, _ = s.repo.ConsumeVoucher(ctx, *in.VoucherID, en.ID, resolved.Price, resolved.FinalPrice, in.StudentID)
	}
	s.bus.Publish(ctx, events.Event{
		Name: "enrollment.confirmed",
		Payload: map[string]any{"enrollment_id": en.ID, "student_id": en.StudentID, "course_batch_id": en.CourseBatchID, "source": en.Source},
	})
	return en, nil
}
```

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(enrollment): Create with pricing, voucher, and validation"
```

---

## Task 5: Apply student credit at enrollment

**Files:**
- Modify: `service.go`
- Create: `service_credit_test.go`

Spec rule: credit reduces payment amount, NOT final_price on Enrollment.

- [ ] **Step 1: Failing tests**

- ApplyCredit during create: `credit_applied` set; `final_price` unchanged
- Credit > final_price → cap at final_price
- Credit on dropped enrollment refund returns to balance (verified via finance domain integration)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement** — pass `credit_applied` to repo, set `student_credit_id`. Voucher applied first (changes price→final_price), credit applied second (reduces what's owed).

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(enrollment): apply student credit"
```

---

## Task 6: Mark complete / drop

**Files:**
- Modify: `service.go`
- Create: `service_lifecycle_test.go`

- [ ] **Step 1: Failing tests**

- MarkCompleted fires `enrollment.completed`
- MarkCompleted from `dropped` rejected
- Drop fires `enrollment.dropped`
- Drop from `completed` allowed but logged (admin override; per spec rule 12 of certificate)

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement state methods** with allowed-transition map.

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(enrollment): completion and drop lifecycle"
```

---

## Task 7: Voucher CRUD (admin only)

**Files:**
- Modify: `service.go`, `repository.go`
- Create: `service_voucher_admin_test.go`

- [ ] **Step 1: Failing tests**

- CreateVoucher rejects `discount_type=percentage` with value outside [0,100]
- CreateVoucher rejects `valid_until < valid_from`
- AssignVoucher to student sets `assigned_to`

- [ ] **Step 2: FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(enrollment): voucher admin CRUD"
```

---

## Task 8: Wire HTTP routes

**Files:**
- Modify: `handler.go`, `module.go`

- [ ] **Step 1: Mount routes**

```
POST   /enrollments              [student (b2c self), admin (b2b)]
PATCH  /enrollments/{id}/complete [admin]
PATCH  /enrollments/{id}/drop     [admin]
GET    /enrollments/me            [student (own)]
POST   /vouchers                  [admin, vernonedu_admin]
PATCH  /vouchers/{id}/assign      [admin]
GET    /vouchers/me               [student]
POST   /vouchers/redeem           [student]  # validate code
```

- [ ] **Step 2: Implement handlers**

- [ ] **Step 3: Smoke test**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(enrollment): mount HTTP routes"
```

---

## Task 9: Verify + lint

- [ ] `cd backend && go test -race ./domains/enrollment/...`
- [ ] `cd backend && golangci-lint run ./domains/enrollment/...`
- [ ] Remove `GAPS.md`. Commit.

---

## Verification

1. Create batch + voucher
2. Self-enroll as student via `/enrollments` with voucher code → expect 201, `final_price` reduced, `enrollment.confirmed` fired, voucher.used_count incremented
3. Concurrent enroll using same voucher (race) → only one succeeds
4. Complete enrollment → expect `enrollment.completed`
5. Drop → expect `enrollment.dropped`
