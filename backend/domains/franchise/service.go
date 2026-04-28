package franchise

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

const (
	maxRevenueRoyaltyPct = 100
	minRevenueRoyaltyPct = 0
)

// Service holds franchise business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs franchise Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// CreateFranchisee registers a new franchisee (investor/location owner).
func (s *Service) CreateFranchisee(ctx context.Context, f *Franchisee) (*Franchisee, error) {
	f.ID = uuid.New()
	f.Status = FranchiseeActive
	if err := s.repo.CreateFranchisee(ctx, f); err != nil {
		return nil, err
	}
	return f, nil
}

// GetFranchiseeByID fetches a franchisee by ID.
func (s *Service) GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error) {
	return s.repo.GetFranchiseeByID(ctx, id)
}

// ListFranchisees returns all franchisees.
func (s *Service) ListFranchisees(ctx context.Context) ([]*Franchisee, error) {
	return s.repo.ListFranchisees(ctx)
}

// GetMyFranchisee returns the franchisee record linked to the calling user.
func (s *Service) GetMyFranchisee(ctx context.Context, userID uuid.UUID) (*Franchisee, error) {
	return s.repo.GetFranchiseeByUserID(ctx, userID)
}

// CreateAgreement creates a franchise agreement for a franchisee.
// revenue_royalty_pct must be between 0 and 100.
func (s *Service) CreateAgreement(ctx context.Context, a *FranchiseAgreement) (*FranchiseAgreement, error) {
	if a.RevenueRoyaltyPct.LessThan(decimal.NewFromInt(minRevenueRoyaltyPct)) ||
		a.RevenueRoyaltyPct.GreaterThan(decimal.NewFromInt(maxRevenueRoyaltyPct)) {
		return nil, apperrors.Validationf("revenue_royalty_pct must be between 0 and 100")
	}
	a.ID = uuid.New()
	a.Status = AgreementActive
	if err := s.repo.CreateAgreement(ctx, a); err != nil {
		return nil, err
	}
	return a, nil
}

// GetAgreementByFranchiseeID returns the active agreement for a franchisee.
func (s *Service) GetAgreementByFranchiseeID(ctx context.Context, franchiseeID uuid.UUID) (*FranchiseAgreement, error) {
	return s.repo.GetAgreementByFranchiseeID(ctx, franchiseeID)
}

// AddBranchOtherRevenue records non-enrollment revenue for a branch.
func (s *Service) AddBranchOtherRevenue(ctx context.Context, rev *BranchOtherRevenue) (*BranchOtherRevenue, error) {
	rev.ID = uuid.New()
	if err := s.repo.CreateBranchOtherRevenue(ctx, rev); err != nil {
		return nil, err
	}
	return rev, nil
}

// CreateRoyaltyRecord computes and persists a royalty record for a period.
// Gross revenue = enrollment fees + branch other revenues.
// Revenue royalty = gross_revenue × revenue_royalty_pct / 100.
// Total royalty = monthly_royalty + revenue_royalty.
func (s *Service) CreateRoyaltyRecord(ctx context.Context, franchiseeID uuid.UUID, period string, recordedBy uuid.UUID) (*RoyaltyPaymentRecord, error) {
	agreement, err := s.repo.GetAgreementByFranchiseeID(ctx, franchiseeID)
	if err != nil {
		return nil, fmt.Errorf("no active agreement for franchisee: %w", err)
	}

	gross, err := s.computeGrossRevenue(ctx, franchiseeID, period)
	if err != nil {
		return nil, err
	}

	revenueRoyalty := gross.Mul(agreement.RevenueRoyaltyPct).Div(decimal.NewFromInt(100))
	totalRoyalty := agreement.MonthlyRoyalty.Add(revenueRoyalty)

	rec := &RoyaltyPaymentRecord{
		ID:                   uuid.New(),
		FranchiseAgreementID: agreement.ID,
		Period:               period,
		GrossRevenue:         gross,
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

// computeGrossRevenue sums enrollment revenue + other revenue for the period.
func (s *Service) computeGrossRevenue(ctx context.Context, franchiseeID uuid.UUID, period string) (decimal.Decimal, error) {
	enrollStr, err := s.repo.GetEnrollmentRevenue(ctx, franchiseeID, period)
	if err != nil {
		return decimal.Zero, err
	}
	otherStr, err := s.repo.GetOtherRevenue(ctx, franchiseeID, period)
	if err != nil {
		return decimal.Zero, err
	}

	enroll, err := decimal.NewFromString(enrollStr)
	if err != nil {
		return decimal.Zero, fmt.Errorf("franchise.computeGrossRevenue parse enroll: %w", err)
	}
	other, err := decimal.NewFromString(otherStr)
	if err != nil {
		return decimal.Zero, fmt.Errorf("franchise.computeGrossRevenue parse other: %w", err)
	}
	return enroll.Add(other), nil
}

// GetRoyaltyRecord returns a royalty record by franchisee and period.
func (s *Service) GetRoyaltyRecord(ctx context.Context, franchiseeID uuid.UUID, period string) (*RoyaltyPaymentRecord, error) {
	return s.repo.GetRoyaltyRecord(ctx, franchiseeID, period)
}

// MarkRoyaltyPaid marks a royalty payment record as paid.
func (s *Service) MarkRoyaltyPaid(ctx context.Context, id uuid.UUID) error {
	return s.repo.MarkRoyaltyPaid(ctx, id)
}

// MarkOverdueRoyalties marks unpaid royalty records as overdue
// if their period end date + 14 days has passed.
func (s *Service) MarkOverdueRoyalties(ctx context.Context) error {
	return s.repo.MarkOverdueRoyalties(ctx)
}

// ListRoyaltyRecords returns all royalty records for a franchisee ordered by period desc.
func (s *Service) ListRoyaltyRecords(ctx context.Context, franchiseeID uuid.UUID) ([]*RoyaltyPaymentRecord, error) {
	return s.repo.ListRoyaltyByFranchisee(ctx, franchiseeID)
}
