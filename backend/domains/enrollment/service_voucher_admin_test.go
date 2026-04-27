package enrollment

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
)

func validCreateVoucherInput() CreateVoucherInput {
	return CreateVoucherInput{
		Code:          "ADMIN-" + uuid.NewString()[:8],
		DiscountType:  DiscountFixed,
		DiscountValue: decimal.NewFromInt(50),
		ValidFrom:     time.Now().Add(-time.Hour),
		CreatedBy:     uuid.New(),
	}
}

func assertValidation(t *testing.T, err error) {
	t.Helper()
	if err == nil {
		t.Fatalf("expected validation error, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestCreateVoucher_PercentageOutOfRange_Rejected(t *testing.T) {
	s, _ := newEnrollmentSvc(t)
	in := validCreateVoucherInput()
	in.DiscountType = DiscountPercentage
	in.DiscountValue = decimal.NewFromInt(120)

	_, err := s.CreateVoucher(context.Background(), in)
	assertValidation(t, err)
}

func TestCreateVoucher_PercentageNegative_Rejected(t *testing.T) {
	s, _ := newEnrollmentSvc(t)
	in := validCreateVoucherInput()
	in.DiscountType = DiscountPercentage
	in.DiscountValue = decimal.NewFromInt(-5)

	_, err := s.CreateVoucher(context.Background(), in)
	assertValidation(t, err)
}

func TestCreateVoucher_ValidUntilBeforeValidFrom_Rejected(t *testing.T) {
	s, _ := newEnrollmentSvc(t)
	in := validCreateVoucherInput()
	in.ValidFrom = time.Now()
	earlier := time.Now().Add(-24 * time.Hour)
	in.ValidUntil = &earlier

	_, err := s.CreateVoucher(context.Background(), in)
	assertValidation(t, err)
}

func TestCreateVoucher_OK(t *testing.T) {
	s, _ := newEnrollmentSvc(t)
	in := validCreateVoucherInput()

	v, err := s.CreateVoucher(context.Background(), in)
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if v == nil {
		t.Fatalf("expected voucher, got nil")
	}
	if v.Code != in.Code {
		t.Fatalf("code mismatch: got %s, want %s", v.Code, in.Code)
	}
	if !v.IsActive {
		t.Fatalf("expected is_active=true")
	}
	if v.UsedCount != 0 {
		t.Fatalf("expected used_count=0, got %d", v.UsedCount)
	}
}

func TestAssignVoucher_SetsAssignedTo(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	v.AssignedTo = nil
	r.SeedVoucher(v)

	student := uuid.New()
	if err := s.AssignVoucher(context.Background(), v.ID, student); err != nil {
		t.Fatalf("assign failed: %v", err)
	}

	r.mu.Lock()
	got := r.vouchers[v.ID].AssignedTo
	r.mu.Unlock()
	if got == nil || *got != student {
		t.Fatalf("expected assigned_to=%s, got %v", student, got)
	}
}

func TestAssignVoucher_AlreadyAssigned_Rejected(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	other := uuid.New()
	r.SeedVoucherAssigned(v, other)

	err := s.AssignVoucher(context.Background(), v.ID, uuid.New())
	assertValidation(t, err)
}

func TestDeactivateVoucher_SetsFlagFalse(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	v.IsActive = true
	r.SeedVoucher(v)

	if err := s.DeactivateVoucher(context.Background(), v.ID); err != nil {
		t.Fatalf("deactivate failed: %v", err)
	}

	r.mu.Lock()
	got := r.vouchers[v.ID].IsActive
	r.mu.Unlock()
	if got {
		t.Fatalf("expected is_active=false")
	}
}
