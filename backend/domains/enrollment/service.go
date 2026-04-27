package enrollment

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	"go.uber.org/zap"
)

// Service holds enrollment business logic.
type Service struct {
	repo         Repository
	bus          events.Bus
	log          *zap.Logger
	catalog      CatalogReader
	partnerships PartnershipsReader
	finance      FinanceReader
}

// NewService constructs enrollment Service.
//
// catalog is required for the Enroll workflow (batch lookup + format
// validation). partnerships and finance may be nil — the service treats
// a nil partnerships reader as "no active agreement available" (falls back
// to B2C pricing) and a nil finance reader as "no credit application".
func NewService(
	repo Repository,
	bus events.Bus,
	log *zap.Logger,
	catalog CatalogReader,
	partnerships PartnershipsReader,
	finance FinanceReader,
) *Service {
	return &Service{
		repo:         repo,
		bus:          bus,
		log:          log,
		catalog:      catalog,
		partnerships: partnerships,
		finance:      finance,
	}
}

// EnrollInput carries enrollment creation parameters.
type EnrollInput struct {
	StudentID     uuid.UUID
	CourseBatchID uuid.UUID
	Format        EnrollmentFormat
	Mode          EnrollmentMode
	PartnerID     *uuid.UUID
	FranchiseeID  *uuid.UUID
	VoucherCode   string
	Source        string
	// StudentCreditID, when set, requests application of a finance-domain
	// student credit balance against the resolved final price.
	StudentCreditID *uuid.UUID
}

// Enroll creates an enrollment using cross-domain reads for batch + format
// validation and pricing. Voucher is optional.
func (s *Service) Enroll(ctx context.Context, in EnrollInput) (*Enrollment, error) {
	if s.catalog == nil {
		return nil, apperrors.Validationf("catalog reader not configured")
	}

	batch, err := s.catalog.GetBatch(ctx, in.CourseBatchID)
	if err != nil {
		return nil, err
	}
	if err := s.validateBatchOpen(batch, in.Source); err != nil {
		return nil, err
	}
	if err := s.validateFormat(ctx, in, batch); err != nil {
		return nil, err
	}

	existing, err := s.repo.GetEnrollmentByStudentAndBatch(ctx, in.StudentID, in.CourseBatchID)
	if err == nil && existing != nil {
		return nil, apperrors.Conflictf("student already enrolled in this batch")
	}

	resolved, voucher, payer, err := s.resolvePricing(ctx, in, batch)
	if err != nil {
		return nil, err
	}

	creditApplied, creditID := s.resolveCredit(ctx, in, resolved.FinalPrice)

	e := &Enrollment{
		ID:               uuid.New(),
		StudentID:        in.StudentID,
		CourseBatchID:    in.CourseBatchID,
		Format:           in.Format,
		Mode:             in.Mode,
		Payer:            string(payer),
		PartnerID:        in.PartnerID,
		FranchiseeID:     in.FranchiseeID,
		Price:            resolved.Price,
		FinalPrice:       resolved.FinalPrice,
		CreditApplied:    creditApplied,
		StudentCreditID:  creditID,
		PaymentStatus:    PaymentPending,
		CompletionStatus: CompletionOngoing,
		Source:           in.Source,
	}
	if voucher != nil {
		e.VoucherID = &voucher.ID
	}

	if err := s.repo.CreateEnrollment(ctx, e); err != nil {
		return nil, err
	}

	if creditID != nil && s.finance != nil {
		if err := s.finance.DebitStudentCredit(ctx, *creditID, creditApplied, e.ID); err != nil {
			s.log.Warn("debit student credit failed", zap.Error(err))
		}
	}

	if voucher != nil {
		if err := s.repo.ConsumeVoucher(ctx, ConsumeVoucherParams{
			VoucherID:     voucher.ID,
			EnrollmentID:  e.ID,
			StudentID:     in.StudentID,
			OriginalPrice: resolved.Price,
			FinalPrice:    resolved.FinalPrice,
			CreatedBy:     in.StudentID,
		}); err != nil {
			s.log.Warn("voucher consume failed", zap.Error(err))
		}
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type: events.EnrollmentConfirmed,
		Payload: events.EnrollmentConfirmedPayload{
			EnrollmentID: e.ID,
			StudentID:    e.StudentID,
			BatchID:      e.CourseBatchID,
			CourseTitle:  batch.CourseTitle,
		},
	})

	return e, nil
}

// validateBatchOpen ensures the batch is in an enrollable state and that
// the registration window/web flag permits the requested source.
func (s *Service) validateBatchOpen(batch *CatalogBatch, source string) error {
	if batch.Status != BatchStatusOpen && batch.Status != BatchStatusOngoing {
		return apperrors.Validationf("batch not open for enrollment")
	}
	if source == SourceB2C && !batch.WebRegistrationOpen {
		return apperrors.Validationf("web registration closed for this batch")
	}
	now := time.Now()
	if batch.RegistrationOpenAt != nil && now.Before(*batch.RegistrationOpenAt) {
		return apperrors.Validationf("registration not yet open")
	}
	if batch.RegistrationCloseAt != nil && now.After(*batch.RegistrationCloseAt) {
		return apperrors.Validationf("registration closed")
	}
	return nil
}

// validateFormat enforces source/format compatibility, format toggle, and
// per-format capacity limits.
func (s *Service) validateFormat(ctx context.Context, in EnrollInput, batch *CatalogBatch) error {
	if (in.Format == FormatInhouseTraining || in.Format == FormatInschoolProgram) && in.Source == SourceB2C {
		return apperrors.Validationf("format not available for B2C")
	}

	cfg, err := s.catalog.GetFormatConfig(ctx, batch.CourseID, in.Format)
	if err != nil {
		return apperrors.Validationf("format not enabled")
	}
	if cfg == nil || !cfg.IsEnabled {
		return apperrors.Validationf("format not enabled")
	}
	if cfg.MaxStudents != nil {
		count, err := s.repo.CountEnrollmentsByBatchAndFormat(ctx, in.CourseBatchID, in.Format)
		if err != nil {
			return err
		}
		if count >= *cfg.MaxStudents {
			return apperrors.Validationf("batch full for format")
		}
	}
	return nil
}

// resolvePricing loads voucher (if requested) + active agreement (if partner)
// and runs ResolvePrice. Returns resolved prices, optional voucher, and the
// effective payer.
func (s *Service) resolvePricing(
	ctx context.Context,
	in EnrollInput,
	batch *CatalogBatch,
) (ResolveOutput, *Voucher, Payer, error) {
	priceIn := ResolveInput{
		BatchPrice:     batch.Price,
		BatchBulkPrice: batch.BatchBulkPrice,
	}
	payer := PayerStudent

	if in.PartnerID != nil && s.partnerships != nil {
		ag, err := s.partnerships.GetActiveAgreement(ctx, *in.PartnerID)
		if err == nil && ag != nil && ag.IsActive {
			priceIn.IsB2B = true
			priceIn.Payer = ag.Payer
			priceIn.AgreementBulkPrice = ag.BulkPrice
			payer = ag.Payer
		}
	}

	var voucher *Voucher
	if in.VoucherCode != "" {
		v, err := s.repo.GetVoucherByCode(ctx, in.VoucherCode)
		if err != nil {
			return ResolveOutput{}, nil, payer, apperrors.Validationf("voucher not found")
		}
		if !v.IsActive {
			return ResolveOutput{}, nil, payer, apperrors.Validationf("voucher is not active")
		}
		if v.ValidUntil != nil && time.Now().After(*v.ValidUntil) {
			return ResolveOutput{}, nil, payer, apperrors.Validationf("voucher has expired")
		}
		if v.MaxUses != nil && v.UsedCount >= *v.MaxUses {
			return ResolveOutput{}, nil, payer, apperrors.Validationf("voucher usage limit reached")
		}
		priceIn.Voucher = v
		voucher = v
	}

	return ResolvePrice(priceIn), voucher, payer, nil
}

// resolveCredit looks up the requested student credit (if any) and returns
// the amount to apply (capped at finalPrice) plus the credit ID. Returns
// zero/nil when credit cannot or should not be applied.
func (s *Service) resolveCredit(
	ctx context.Context,
	in EnrollInput,
	finalPrice decimal.Decimal,
) (decimal.Decimal, *uuid.UUID) {
	if in.StudentCreditID == nil || s.finance == nil {
		return decimal.Zero, nil
	}
	credit, err := s.finance.GetStudentCredit(ctx, *in.StudentCreditID)
	if err != nil || credit == nil {
		return decimal.Zero, nil
	}
	if !credit.IsActive || credit.StudentID != in.StudentID {
		return decimal.Zero, nil
	}
	toApply := credit.Balance
	if toApply.GreaterThan(finalPrice) {
		toApply = finalPrice
	}
	if !toApply.IsPositive() {
		return decimal.Zero, nil
	}
	id := credit.ID
	return toApply, &id
}

// MarkCompleted transitions an enrollment from ongoing to completed.
//
// Transition matrix:
//   - ongoing   -> completed: allowed, fires enrollment.completed
//   - completed -> completed: idempotent no-op (no event re-fired)
//   - dropped   -> completed: rejected (validation error)
//
// Payment status is intentionally left untouched — completion is an academic
// status independent of payment.
func (s *Service) MarkCompleted(ctx context.Context, enrollmentID uuid.UUID) error {
	e, err := s.repo.GetEnrollmentByID(ctx, enrollmentID)
	if err != nil {
		return err
	}
	if e.CompletionStatus == CompletionCompleted {
		return nil
	}
	if e.CompletionStatus == CompletionDropped {
		return apperrors.Validationf("cannot complete a dropped enrollment")
	}
	if err := s.repo.UpdateEnrollmentCompletion(ctx, enrollmentID, CompletionCompleted); err != nil {
		return err
	}
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.EnrollmentCompleted,
		Payload: events.EnrollmentCompletedPayload{
			EnrollmentID: enrollmentID,
			StudentID:    e.StudentID,
			BatchID:      e.CourseBatchID,
		},
	})
	return nil
}

// Drop transitions an enrollment to dropped.
//
// Transition matrix:
//   - ongoing   -> dropped: allowed, fires enrollment.dropped
//   - completed -> dropped: allowed (admin override per certificate spec
//     rule 12), fires enrollment.dropped, logged as warning
//   - dropped   -> dropped: idempotent no-op (no event re-fired)
func (s *Service) Drop(ctx context.Context, enrollmentID uuid.UUID) error {
	e, err := s.repo.GetEnrollmentByID(ctx, enrollmentID)
	if err != nil {
		return err
	}
	if e.CompletionStatus == CompletionDropped {
		return nil
	}
	if e.CompletionStatus == CompletionCompleted {
		s.log.Warn("dropping already-completed enrollment (admin override)",
			zap.String("enrollment_id", enrollmentID.String()))
	}
	if err := s.repo.UpdateEnrollmentCompletion(ctx, enrollmentID, CompletionDropped); err != nil {
		return err
	}
	_ = s.bus.Publish(ctx, events.Event{
		Type: events.EnrollmentDropped,
		Payload: events.EnrollmentDroppedPayload{
			EnrollmentID: enrollmentID,
			StudentID:    e.StudentID,
			BatchID:      e.CourseBatchID,
		},
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

// CreateVoucherInput carries voucher creation parameters.
type CreateVoucherInput struct {
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

// CreateVoucher validates input and persists a new voucher with sane defaults
// (is_active=true, used_count=0).
func (s *Service) CreateVoucher(ctx context.Context, in CreateVoucherInput) (*Voucher, error) {
	if in.Code == "" {
		return nil, apperrors.Validationf("voucher code required")
	}
	if in.DiscountType == DiscountPercentage {
		if in.DiscountValue.LessThan(decimal.Zero) || in.DiscountValue.GreaterThan(decimal.NewFromInt(100)) {
			return nil, apperrors.Validationf("percentage discount must be in [0,100]")
		}
	}
	if in.ValidUntil != nil && in.ValidUntil.Before(in.ValidFrom) {
		return nil, apperrors.Validationf("valid_until before valid_from")
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
		UsedCount:     0,
		IsActive:      true,
		CreatedBy:     in.CreatedBy,
	}
	if err := s.repo.CreateVoucher(ctx, v); err != nil {
		return nil, err
	}
	return v, nil
}

// AssignVoucher links a voucher to a student. Assignment is one-time;
// subsequent attempts are rejected.
func (s *Service) AssignVoucher(ctx context.Context, voucherID, studentID uuid.UUID) error {
	v, err := s.repo.GetVoucherByID(ctx, voucherID)
	if err != nil {
		return err
	}
	if v.AssignedTo != nil {
		return apperrors.Validationf("voucher already assigned")
	}
	return s.repo.AssignVoucher(ctx, voucherID, studentID)
}

// DeactivateVoucher disables a voucher (is_active=false).
func (s *Service) DeactivateVoucher(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeactivateVoucher(ctx, id)
}

// GetEnrollment fetches enrollment by ID.
func (s *Service) GetEnrollment(ctx context.Context, id uuid.UUID) (*Enrollment, error) {
	return s.repo.GetEnrollmentByID(ctx, id)
}

// ListByStudent returns all enrollments for a student.
func (s *Service) ListByStudent(ctx context.Context, studentID uuid.UUID) ([]*Enrollment, error) {
	return s.repo.ListEnrollmentsByStudent(ctx, studentID)
}
