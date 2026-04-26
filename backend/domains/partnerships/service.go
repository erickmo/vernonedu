package partnerships

import (
	"context"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds partnerships business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs partnerships Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// CreatePartner creates a new partner.
func (s *Service) CreatePartner(ctx context.Context, p *Partner) error {
	p.ID = uuid.New()
	p.Status = PartnerLead
	return s.repo.CreatePartner(ctx, p)
}

// GetPartner fetches partner by ID.
func (s *Service) GetPartner(ctx context.Context, id uuid.UUID) (*Partner, error) {
	return s.repo.GetPartnerByID(ctx, id)
}

// ListPartners returns partners filtered by optional status.
func (s *Service) ListPartners(ctx context.Context, status *PartnerStatus) ([]*Partner, error) {
	return s.repo.ListPartners(ctx, status)
}

// ActivatePartner transitions partner to active.
func (s *Service) ActivatePartner(ctx context.Context, id uuid.UUID) error {
	return s.repo.UpdatePartnerStatus(ctx, id, PartnerActive)
}

// CreateAgreement creates a partnership agreement.
func (s *Service) CreateAgreement(ctx context.Context, a *PartnershipAgreement) error {
	a.ID = uuid.New()
	a.Status = AgreementDraft
	return s.repo.CreateAgreement(ctx, a)
}

// ActivateAgreement transitions agreement to active.
func (s *Service) ActivateAgreement(ctx context.Context, id uuid.UUID) error {
	a, err := s.repo.GetAgreementByID(ctx, id)
	if err != nil {
		return err
	}
	if a.Status != AgreementDraft {
		return apperrors.Validationf("only draft agreements can be activated")
	}
	return s.repo.UpdateAgreementStatus(ctx, id, AgreementActive)
}

// TerminateAgreement terminates an active agreement.
func (s *Service) TerminateAgreement(ctx context.Context, id uuid.UUID, reason string) error {
	a, err := s.repo.GetAgreementByID(ctx, id)
	if err != nil {
		return err
	}
	if a.Status != AgreementActive {
		return apperrors.Validationf("only active agreements can be terminated")
	}
	a.TerminationReason = &reason
	if err := s.repo.UpdateAgreementStatus(ctx, id, AgreementTerminated); err != nil {
		return err
	}
	return nil
}

// CreateFranchisee creates a franchisee.
func (s *Service) CreateFranchisee(ctx context.Context, f *Franchisee) error {
	f.ID = uuid.New()
	f.Status = FranchiseeActive
	return s.repo.CreateFranchisee(ctx, f)
}

// ListFranchisees returns all active franchisees.
func (s *Service) ListFranchisees(ctx context.Context) ([]*Franchisee, error) {
	return s.repo.ListFranchisees(ctx)
}

// CalculateRoyalty computes royalty amounts for a period.
func (s *Service) CalculateRoyalty(ctx context.Context, franchiseeID uuid.UUID, period string, grossRevenue decimal.Decimal, recordedBy uuid.UUID) (*RoyaltyPaymentRecord, error) {
	agreement, err := s.repo.GetFranchiseAgreementByFranchisee(ctx, franchiseeID)
	if err != nil {
		return nil, err
	}

	revenueRoyalty := grossRevenue.Mul(agreement.RevenueRoyaltyPct).Div(decimal.NewFromInt(100))
	totalRoyalty := agreement.MonthlyRoyalty.Add(revenueRoyalty)

	rec := &RoyaltyPaymentRecord{
		ID:                   uuid.New(),
		FranchiseAgreementID: agreement.ID,
		Period:               period,
		GrossRevenue:         grossRevenue,
		MonthlyRoyalty:       agreement.MonthlyRoyalty,
		RevenueRoyalty:       revenueRoyalty,
		TotalRoyalty:         totalRoyalty,
		Status:               RoyaltyUnpaid,
		RecordedBy:           recordedBy,
	}

	if err := s.repo.CreateRoyaltyRecord(ctx, rec); err != nil {
		return nil, err
	}
	return rec, nil
}

// MarkRoyaltyPaid marks a royalty record as paid.
func (s *Service) MarkRoyaltyPaid(ctx context.Context, id uuid.UUID) error {
	return s.repo.UpdateRoyaltyStatus(ctx, id, RoyaltyPaid)
}
