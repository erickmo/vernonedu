package voucher

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds voucher business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs a voucher Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// CreateInput carries parameters for voucher creation (admin only).
type CreateInput struct {
	Code          string
	DiscountType  DiscountType
	DiscountValue decimal.Decimal
	AssignedTo    *uuid.UUID
	CourseID      *uuid.UUID
	CourseBatchID *uuid.UUID
	ValidFrom     time.Time
	ValidUntil    *time.Time
	MaxUses       *int
	CreatedBy     uuid.UUID
}

// ApplyInput carries parameters for redeeming a voucher against an enrollment.
type ApplyInput struct {
	VoucherCode   string
	EnrollmentID  uuid.UUID
	OriginalPrice decimal.Decimal
	StudentID     *uuid.UUID // set if caller is a student (for assigned_to check)
	CourseBatchID *uuid.UUID // set so batch-scoped check can be performed
	CourseID      *uuid.UUID // set so course-scoped check can be performed
	CallerUserID  uuid.UUID
}

// CreateVoucher validates and persists a new voucher.
func (s *Service) CreateVoucher(ctx context.Context, in CreateInput) (*Voucher, error) {
	if err := validateCreateInput(in); err != nil {
		return nil, err
	}

	v := &Voucher{
		ID:            uuid.New(),
		Code:          in.Code,
		DiscountType:  in.DiscountType,
		DiscountValue: in.DiscountValue,
		AssignedTo:    in.AssignedTo,
		CourseID:      in.CourseID,
		CourseBatchID: in.CourseBatchID,
		ValidFrom:     in.ValidFrom,
		ValidUntil:    in.ValidUntil,
		MaxUses:       in.MaxUses,
		IsActive:      true,
		CreatedBy:     in.CreatedBy,
	}

	if err := s.repo.CreateVoucher(ctx, v); err != nil {
		return nil, err
	}
	return v, nil
}

// GetVoucher fetches a single voucher by ID.
func (s *Service) GetVoucher(ctx context.Context, id uuid.UUID) (*Voucher, error) {
	return s.repo.GetVoucherByID(ctx, id)
}

// ListVouchers returns vouchers matching the given filter.
func (s *Service) ListVouchers(ctx context.Context, f ListFilter) ([]*Voucher, error) {
	return s.repo.ListVouchers(ctx, f)
}

// DeactivateVoucher marks a voucher as inactive.
func (s *Service) DeactivateVoucher(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeactivateVoucher(ctx, id)
}

// ListMyVouchers returns vouchers assigned to the given student.
func (s *Service) ListMyVouchers(ctx context.Context, studentID uuid.UUID) ([]*Voucher, error) {
	return s.repo.ListByAssignedStudent(ctx, studentID)
}

// ApplyVoucher validates eligibility, calculates final price, and creates VoucherUsage atomically.
func (s *Service) ApplyVoucher(ctx context.Context, in ApplyInput) (*VoucherUsage, error) {
	v, err := s.repo.GetVoucherByCode(ctx, in.VoucherCode)
	if err != nil {
		return nil, apperrors.Validationf("voucher not found")
	}

	if err := checkEligibility(v, in, time.Now()); err != nil {
		return nil, err
	}

	finalPrice := calculateFinalPrice(in.OriginalPrice, v)

	vu := &VoucherUsage{
		ID:            uuid.New(),
		VoucherID:     v.ID,
		EnrollmentID:  in.EnrollmentID,
		OriginalPrice: in.OriginalPrice,
		FinalPrice:    finalPrice,
		CreatedBy:     in.CallerUserID,
	}

	result, err := s.repo.ApplyVoucher(ctx, vu)
	if err != nil {
		return nil, err
	}
	return result, nil
}

// validateCreateInput performs business-rule checks before creation.
func validateCreateInput(in CreateInput) error {
	if in.Code == "" {
		return apperrors.Validationf("voucher code is required")
	}
	if in.DiscountType == DiscountPercentage {
		if in.DiscountValue.LessThan(decimal.Zero) || in.DiscountValue.GreaterThan(decimal.NewFromInt(100)) {
			return apperrors.Validationf("percentage discount_value must be between 0 and 100")
		}
	}
	if in.DiscountValue.LessThan(decimal.Zero) {
		return apperrors.Validationf("discount_value must not be negative")
	}
	return nil
}

// checkEligibility enforces assignment, scope, active, and expiry rules before the atomic apply.
func checkEligibility(v *Voucher, in ApplyInput, now time.Time) error {
	if !v.IsActive {
		return apperrors.Validationf("voucher is not active")
	}
	if v.ValidUntil != nil && now.After(*v.ValidUntil) {
		return apperrors.Validationf("voucher has expired")
	}
	if v.AssignedTo != nil && (in.StudentID == nil || *in.StudentID != *v.AssignedTo) {
		return apperrors.ErrForbidden
	}
	if v.CourseBatchID != nil && (in.CourseBatchID == nil || *in.CourseBatchID != *v.CourseBatchID) {
		return apperrors.Validationf("voucher is not valid for this course batch")
	}
	if v.CourseID != nil && (in.CourseID == nil || *in.CourseID != *v.CourseID) {
		return apperrors.Validationf("voucher is not valid for this course")
	}
	return nil
}

// calculateFinalPrice applies the voucher discount, floored at zero.
func calculateFinalPrice(original decimal.Decimal, v *Voucher) decimal.Decimal {
	var result decimal.Decimal
	switch v.DiscountType {
	case DiscountFixed:
		result = original.Sub(v.DiscountValue)
	case DiscountPercentage:
		pct := v.DiscountValue.Div(decimal.NewFromInt(100))
		result = original.Sub(original.Mul(pct))
	case DiscountFinalPrice:
		return v.DiscountValue
	default:
		return original
	}
	if result.IsNegative() {
		return decimal.Zero
	}
	return result
}
