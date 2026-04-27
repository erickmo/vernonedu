package enrollment

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds enrollment business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs enrollment Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// EnrollInput carries enrollment creation parameters.
type EnrollInput struct {
	StudentID     uuid.UUID
	CourseBatchID uuid.UUID
	Format        EnrollmentFormat
	Mode          EnrollmentMode
	Payer         string
	PartnerID     *uuid.UUID
	FranchiseeID  *uuid.UUID
	Price         decimal.Decimal
	VoucherCode   string
	Source        string
}

// Enroll creates an enrollment, optionally applying a voucher.
func (s *Service) Enroll(ctx context.Context, in EnrollInput) (*Enrollment, error) {
	// Check duplicate
	existing, err := s.repo.GetEnrollmentByStudentAndBatch(ctx, in.StudentID, in.CourseBatchID)
	if err == nil && existing != nil {
		return nil, apperrors.Conflictf("student already enrolled in this batch")
	}

	finalPrice := in.Price
	var voucherID *uuid.UUID

	if in.VoucherCode != "" {
		voucher, err := s.repo.GetVoucherByCode(ctx, in.VoucherCode)
		if err != nil {
			return nil, apperrors.Validationf("voucher not found")
		}
		if !voucher.IsActive {
			return nil, apperrors.Validationf("voucher is not active")
		}
		if voucher.ValidUntil != nil && time.Now().After(*voucher.ValidUntil) {
			return nil, apperrors.Validationf("voucher has expired")
		}
		if voucher.MaxUses != nil && voucher.UsedCount >= *voucher.MaxUses {
			return nil, apperrors.Validationf("voucher usage limit reached")
		}

		finalPrice = applyDiscount(in.Price, voucher)
		voucherID = &voucher.ID
	}

	e := &Enrollment{
		ID:               uuid.New(),
		StudentID:        in.StudentID,
		CourseBatchID:    in.CourseBatchID,
		Format:           in.Format,
		Mode:             in.Mode,
		Payer:            in.Payer,
		PartnerID:        in.PartnerID,
		FranchiseeID:     in.FranchiseeID,
		Price:            in.Price,
		FinalPrice:       finalPrice,
		VoucherID:        voucherID,
		CreditApplied:    decimal.Zero,
		PaymentStatus:    PaymentPending,
		CompletionStatus: CompletionOngoing,
		Source:           in.Source,
	}

	if err := s.repo.CreateEnrollment(ctx, e); err != nil {
		return nil, err
	}

	if voucherID != nil {
		_ = s.repo.ConsumeVoucher(ctx, ConsumeVoucherParams{
			VoucherID:     *voucherID,
			EnrollmentID:  e.ID,
			StudentID:     in.StudentID,
			OriginalPrice: in.Price,
			FinalPrice:    finalPrice,
			CreatedBy:     in.StudentID,
		})
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.EnrollmentConfirmed,
		Payload: EnrollmentConfirmedPayload{EnrollmentID: e.ID, StudentID: e.StudentID, BatchID: e.CourseBatchID},
	})

	return e, nil
}

// CompleteEnrollment marks enrollment as completed.
func (s *Service) CompleteEnrollment(ctx context.Context, enrollmentID uuid.UUID) error {
	if err := s.repo.UpdateEnrollmentStatus(ctx, enrollmentID, PaymentPaid, CompletionCompleted); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.EnrollmentCompleted,
		Payload: EnrollmentCompletedPayload{EnrollmentID: enrollmentID},
	})
	return nil
}

// DropEnrollment marks enrollment as dropped.
func (s *Service) DropEnrollment(ctx context.Context, enrollmentID uuid.UUID) error {
	e, err := s.repo.GetEnrollmentByID(ctx, enrollmentID)
	if err != nil {
		return err
	}
	if e.CompletionStatus == CompletionDropped {
		return apperrors.Validationf("enrollment already dropped")
	}

	if err := s.repo.UpdateEnrollmentStatus(ctx, enrollmentID, e.PaymentStatus, CompletionDropped); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.EnrollmentDropped,
		Payload: EnrollmentDroppedPayload{EnrollmentID: enrollmentID},
	})
	return nil
}

// ConsumeVoucher atomically validates and applies a voucher for an enrollment.
func (s *Service) ConsumeVoucher(
	ctx context.Context,
	voucherID, enrollmentID, studentID, createdBy uuid.UUID,
	originalPrice, finalPrice decimal.Decimal,
) error {
	return s.repo.ConsumeVoucher(ctx, ConsumeVoucherParams{
		VoucherID:     voucherID,
		EnrollmentID:  enrollmentID,
		StudentID:     studentID,
		OriginalPrice: originalPrice,
		FinalPrice:    finalPrice,
		CreatedBy:     createdBy,
	})
}

// GetEnrollment fetches enrollment by ID.
func (s *Service) GetEnrollment(ctx context.Context, id uuid.UUID) (*Enrollment, error) {
	return s.repo.GetEnrollmentByID(ctx, id)
}

// ListByStudent returns all enrollments for a student.
func (s *Service) ListByStudent(ctx context.Context, studentID uuid.UUID) ([]*Enrollment, error) {
	return s.repo.ListEnrollmentsByStudent(ctx, studentID)
}

func applyDiscount(price decimal.Decimal, v *Voucher) decimal.Decimal {
	switch v.DiscountType {
	case DiscountFixed:
		result := price.Sub(v.DiscountValue)
		if result.IsNegative() {
			return decimal.Zero
		}
		return result
	case DiscountPercentage:
		pct := v.DiscountValue.Div(decimal.NewFromInt(100))
		discount := price.Mul(pct)
		return price.Sub(discount)
	case DiscountFinalPrice:
		return v.DiscountValue
	default:
		return price
	}
}
