package franchise

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// FranchiseeStatus represents lifecycle state of a franchisee.
type FranchiseeStatus string

const (
	FranchiseeActive     FranchiseeStatus = "active"
	FranchiseeInactive   FranchiseeStatus = "inactive"
	FranchiseeTerminated FranchiseeStatus = "terminated"
)

// AgreementStatus represents lifecycle state of a franchise agreement.
type AgreementStatus string

const (
	AgreementActive     AgreementStatus = "active"
	AgreementInactive   AgreementStatus = "inactive"
	AgreementTerminated AgreementStatus = "terminated"
)

// RoyaltyStatus represents payment state of a royalty record.
type RoyaltyStatus string

const (
	RoyaltyUnpaid  RoyaltyStatus = "unpaid"
	RoyaltyOverdue RoyaltyStatus = "overdue"
	RoyaltyPaid    RoyaltyStatus = "paid"
)

// Franchisee represents an investor/location owner in the franchise model.
// VernonEdu retains 100% operational management.
type Franchisee struct {
	ID         uuid.UUID        `json:"id"`
	Name       string           `json:"name"`
	BranchName string           `json:"branch_name"`
	Location   string           `json:"location"`
	Contact    string           `json:"contact"`
	Status     FranchiseeStatus `json:"status"`
	CreatedBy  uuid.UUID        `json:"created_by"`
	UserID     *uuid.UUID       `json:"user_id,omitempty"`
	CreatedAt  time.Time        `json:"created_at"`
	UpdatedAt  time.Time        `json:"updated_at"`
}

// FranchiseAgreement holds the financial terms between VernonEdu and a franchisee.
type FranchiseAgreement struct {
	ID                uuid.UUID       `json:"id"`
	FranchiseeID      uuid.UUID       `json:"franchisee_id"`
	BuyInFee          decimal.Decimal `json:"buy_in_fee"`
	MonthlyRoyalty    decimal.Decimal `json:"monthly_royalty"`
	RevenueRoyaltyPct decimal.Decimal `json:"revenue_royalty_pct"`
	StartDate         time.Time       `json:"start_date"`
	EndDate           *time.Time      `json:"end_date,omitempty"`
	Status            AgreementStatus `json:"status"`
	CreatedAt         time.Time       `json:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at"`
}

// BranchOtherRevenue records non-enrollment revenue for a branch.
type BranchOtherRevenue struct {
	ID           uuid.UUID       `json:"id"`
	FranchiseeID uuid.UUID       `json:"franchisee_id"`
	Label        string          `json:"label"`
	Amount       decimal.Decimal `json:"amount"`
	RevenueDate  time.Time       `json:"revenue_date"`
	AddedBy      uuid.UUID       `json:"added_by"`
	CreatedAt    time.Time       `json:"created_at"`
	UpdatedAt    time.Time       `json:"updated_at"`
}

// RoyaltyPaymentRecord holds computed royalty for a franchisee per period.
type RoyaltyPaymentRecord struct {
	ID                  uuid.UUID       `json:"id"`
	FranchiseAgreementID uuid.UUID      `json:"franchise_agreement_id"`
	Period              string          `json:"period"` // YYYY-MM
	GrossRevenue        decimal.Decimal `json:"gross_revenue"`
	MonthlyRoyalty      decimal.Decimal `json:"monthly_royalty"`
	RevenueRoyalty      decimal.Decimal `json:"revenue_royalty"`
	TotalRoyalty        decimal.Decimal `json:"total_royalty"`
	Status              RoyaltyStatus   `json:"status"`
	CreatedAt           time.Time       `json:"created_at"`
	PaidAt              *time.Time      `json:"paid_at,omitempty"`
	RecordedBy          uuid.UUID       `json:"recorded_by"`
}
