package franchise

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrFranchiseeNotFound    = errors.New("franchisee not found")
	ErrAgreementNotFound     = errors.New("franchise agreement not found")
	ErrRoyaltyRecordNotFound = errors.New("royalty payment record not found")
	ErrOtherRevenueNotFound  = errors.New("other revenue not found")
)

type Franchisee struct {
	ID                 uuid.UUID
	Name               string
	BranchName         string
	Location           string
	Contact            string
	Status             string
	CreatedBy          *uuid.UUID
	CreatedAt          time.Time
	UpdatedAt          time.Time
	AgreementStartDate string
	AgreementEndDate   string
}

type FranchiseAgreement struct {
	ID                uuid.UUID
	FranchiseeID      uuid.UUID
	BuyInFee          float64
	MonthlyRoyalty    float64
	RevenueRoyaltyPct float64
	StartDate         string
	EndDate           string
	Status            string
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type RoyaltyPaymentRecord struct {
	ID                   uuid.UUID
	FranchiseAgreementID uuid.UUID
	Period              string
	GrossRevenue        float64
	MonthlyRoyalty      float64
	RevenueRoyalty      float64
	TotalRoyalty        float64
	Status              string
	PaidAt              *time.Time
	RecordedBy          *uuid.UUID
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

type BranchOtherRevenue struct {
	ID           uuid.UUID
	FranchiseeID uuid.UUID
	Label        string
	Amount       float64
	RevenueDate  string
	AddedBy      *uuid.UUID
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

type WriteRepository interface {
	SaveFranchisee(ctx context.Context, f *Franchisee) error
	UpdateFranchisee(ctx context.Context, f *Franchisee) error
	SaveAgreement(ctx context.Context, a *FranchiseAgreement) error
	UpdateAgreement(ctx context.Context, a *FranchiseAgreement) error
	SaveRoyaltyPayment(ctx context.Context, r *RoyaltyPaymentRecord) error
	MarkRoyaltyPaid(ctx context.Context, id uuid.UUID, paidAt time.Time) error
	SaveOtherRevenue(ctx context.Context, r *BranchOtherRevenue) error
	UpdateOtherRevenue(ctx context.Context, r *BranchOtherRevenue) error
	DeleteOtherRevenue(ctx context.Context, id uuid.UUID) error
}

type ReadRepository interface {
	GetFranchiseeByID(ctx context.Context, id uuid.UUID) (*Franchisee, error)
	ListFranchisees(ctx context.Context, offset, limit int, status, search string) ([]*Franchisee, int, error)
	GetAgreementByFranchiseeID(ctx context.Context, franchiseeID uuid.UUID) (*FranchiseAgreement, error)
	GetAgreementByID(ctx context.Context, id uuid.UUID) (*FranchiseAgreement, error)
	ListRoyaltyPayments(ctx context.Context, franchiseeID uuid.UUID, period string) ([]*RoyaltyPaymentRecord, error)
	GetRoyaltyPaymentByID(ctx context.Context, id uuid.UUID) (*RoyaltyPaymentRecord, error)
	ListOtherRevenues(ctx context.Context, franchiseeID uuid.UUID, period string) ([]*BranchOtherRevenue, error)
	GetOtherRevenueByID(ctx context.Context, id uuid.UUID) (*BranchOtherRevenue, error)
}
