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

func newVoucher() *Voucher {
	maxUses := 10
	return &Voucher{
		ID:            uuid.New(),
		Code:          "TEST-" + uuid.NewString()[:8],
		DiscountType:  DiscountFixed,
		DiscountValue: decimal.NewFromInt(100),
		IsActive:      true,
		ValidFrom:     time.Now().Add(-24 * time.Hour),
		MaxUses:       &maxUses,
		UsedCount:     0,
		CreatedBy:     uuid.New(),
	}
}

func newEnrollmentSvc(t *testing.T) (*Service, *fakeEnrollmentRepo) {
	t.Helper()
	r := newFakeEnrollmentRepo()
	s := NewService(r, newFakeBus(), testLogger(), newFakeCatalogReader(), newFakePartnershipsReader(), nil)
	return s, r
}

func TestConsumeVoucher_AssignedToOtherStudent_Rejected(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	other := uuid.New()
	v := newVoucher()
	v.AssignedTo = &other
	r.SeedVoucher(v)

	caller := uuid.New()
	err := s.ConsumeVoucher(context.Background(), v.ID, uuid.New(), caller, caller,
		decimal.NewFromInt(1000), decimal.NewFromInt(900))
	if !errors.Is(err, apperrors.ErrForbidden) {
		t.Fatalf("expected ErrForbidden, got %v", err)
	}
}

func TestConsumeVoucher_AssignedNil_OK(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	v.AssignedTo = nil
	r.SeedVoucher(v)

	student := uuid.New()
	err := s.ConsumeVoucher(context.Background(), v.ID, uuid.New(), student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900))
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
}

func TestConsumeVoucher_Expired_Rejected(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	yesterday := time.Now().Add(-24 * time.Hour)
	v.ValidUntil = &yesterday
	r.SeedVoucher(v)

	student := uuid.New()
	err := s.ConsumeVoucher(context.Background(), v.ID, uuid.New(), student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900))
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestConsumeVoucher_Inactive_Rejected(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	v.IsActive = false
	r.SeedVoucher(v)

	student := uuid.New()
	err := s.ConsumeVoucher(context.Background(), v.ID, uuid.New(), student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900))
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestConsumeVoucher_MaxUsesReached_Rejected(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	max := 3
	v.MaxUses = &max
	v.UsedCount = 3
	r.SeedVoucher(v)

	student := uuid.New()
	err := s.ConsumeVoucher(context.Background(), v.ID, uuid.New(), student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900))
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "VALIDATION_ERROR" {
		t.Fatalf("expected VALIDATION_ERROR, got %v", err)
	}
}

func TestConsumeVoucher_DuplicateOnSameEnrollment_Rejected(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	r.SeedVoucher(v)

	student := uuid.New()
	enrollmentID := uuid.New()

	if err := s.ConsumeVoucher(context.Background(), v.ID, enrollmentID, student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900)); err != nil {
		t.Fatalf("first consume failed: %v", err)
	}

	err := s.ConsumeVoucher(context.Background(), v.ID, enrollmentID, student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900))
	if err == nil {
		t.Fatalf("expected conflict, got nil")
	}
	var ae *apperrors.AppError
	if !errors.As(err, &ae) || ae.Code != "CONFLICT" {
		t.Fatalf("expected CONFLICT, got %v", err)
	}
}

func TestConsumeVoucher_Success_IncrementsUsedCountAndCreatesUsage(t *testing.T) {
	s, r := newEnrollmentSvc(t)
	v := newVoucher()
	r.SeedVoucher(v)

	student := uuid.New()
	enrollmentID := uuid.New()

	if err := s.ConsumeVoucher(context.Background(), v.ID, enrollmentID, student, student,
		decimal.NewFromInt(1000), decimal.NewFromInt(900)); err != nil {
		t.Fatalf("consume failed: %v", err)
	}

	r.mu.Lock()
	got := r.vouchers[v.ID].UsedCount
	usage, hasUsage := r.usagesByEnroll[enrollmentID]
	r.mu.Unlock()

	if got != 1 {
		t.Fatalf("expected used_count=1, got %d", got)
	}
	if !hasUsage {
		t.Fatalf("expected voucher_usage row for enrollment")
	}
	if usage.VoucherID != v.ID {
		t.Fatalf("usage voucher mismatch: got %s, want %s", usage.VoucherID, v.ID)
	}
	if !usage.OriginalPrice.Equal(decimal.NewFromInt(1000)) {
		t.Fatalf("usage original_price mismatch: got %s", usage.OriginalPrice.String())
	}
	if !usage.FinalPrice.Equal(decimal.NewFromInt(900)) {
		t.Fatalf("usage final_price mismatch: got %s", usage.FinalPrice.String())
	}
}
