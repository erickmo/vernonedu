package partnerships

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type PartnerType string

const (
	PartnerUniversity         PartnerType = "university"
	PartnerVendor             PartnerType = "vendor"
	PartnerSponsor            PartnerType = "sponsor"
	PartnerFranchiseCandidate PartnerType = "franchise_candidate"
	PartnerCommunity          PartnerType = "community"
	PartnerOther              PartnerType = "other"
)

type PartnerStatus string

const (
	PartnerLead     PartnerStatus = "lead"
	PartnerActive   PartnerStatus = "active"
	PartnerInactive PartnerStatus = "inactive"
)

type AgreementStatus string

const (
	AgreementDraft      AgreementStatus = "draft"
	AgreementActive     AgreementStatus = "active"
	AgreementExpired    AgreementStatus = "expired"
	AgreementTerminated AgreementStatus = "terminated"
)

type FranchiseeStatus string

const (
	FranchiseeActive     FranchiseeStatus = "active"
	FranchiseeInactive   FranchiseeStatus = "inactive"
	FranchiseeTerminated FranchiseeStatus = "terminated"
)

type RoyaltyStatus string

const (
	RoyaltyUnpaid  RoyaltyStatus = "unpaid"
	RoyaltyOverdue RoyaltyStatus = "overdue"
	RoyaltyPaid    RoyaltyStatus = "paid"
)

type Partner struct {
	ID           uuid.UUID     `json:"id"`
	Name         string        `json:"name"`
	Type         PartnerType   `json:"type"`
	Status       PartnerStatus `json:"status"`
	ContactName  *string       `json:"contact_name,omitempty"`
	ContactEmail *string       `json:"contact_email,omitempty"`
	ContactPhone *string       `json:"contact_phone,omitempty"`
	Address      *string       `json:"address,omitempty"`
	Notes        *string       `json:"notes,omitempty"`
	DeletedAt    *time.Time    `json:"deleted_at,omitempty"`
	CreatedAt    time.Time     `json:"created_at"`
	UpdatedAt    time.Time     `json:"updated_at"`
}

type PartnershipAgreement struct {
	ID                uuid.UUID       `json:"id"`
	PartnerID         uuid.UUID       `json:"partner_id"`
	Title             string          `json:"title"`
	Status            AgreementStatus `json:"status"`
	StartDate         time.Time       `json:"start_date"`
	EndDate           *time.Time      `json:"end_date,omitempty"`
	PaymentModel      *string         `json:"payment_model,omitempty"`
	Payer             *string         `json:"payer,omitempty"`
	BulkPrice         *decimal.Decimal `json:"bulk_price,omitempty"`
	SignedAt          *time.Time      `json:"signed_at,omitempty"`
	TerminatedAt      *time.Time      `json:"terminated_at,omitempty"`
	TerminationReason *string         `json:"termination_reason,omitempty"`
	CreatedBy         uuid.UUID       `json:"created_by"`
	CreatedAt         time.Time       `json:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at"`
}

type PartnerDocument struct {
	ID          uuid.UUID `json:"id"`
	AgreementID uuid.UUID `json:"agreement_id"`
	Type        string    `json:"type"`
	Title       string    `json:"title"`
	FileURL     string    `json:"file_url"`
	UploadedBy  uuid.UUID `json:"uploaded_by"`
	UploadedAt  time.Time `json:"uploaded_at"`
}

type Franchisee struct {
	ID         uuid.UUID        `json:"id"`
	Name       string           `json:"name"`
	BranchName string           `json:"branch_name"`
	Location   string           `json:"location"`
	Contact    string           `json:"contact"`
	Status     FranchiseeStatus `json:"status"`
	CreatedBy  uuid.UUID        `json:"created_by"`
	CreatedAt  time.Time        `json:"created_at"`
	UpdatedAt  time.Time        `json:"updated_at"`
	DeletedAt  *time.Time       `json:"deleted_at,omitempty"`
}

type FranchiseAgreement struct {
	ID                uuid.UUID `json:"id"`
	FranchiseeID      uuid.UUID `json:"franchisee_id"`
	BuyInFee          decimal.Decimal `json:"buy_in_fee"`
	MonthlyRoyalty    decimal.Decimal `json:"monthly_royalty"`
	RevenueRoyaltyPct decimal.Decimal `json:"revenue_royalty_pct"`
	StartDate         time.Time       `json:"start_date"`
	EndDate           *time.Time      `json:"end_date,omitempty"`
	Status            string          `json:"status"`
	CreatedAt         time.Time       `json:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at"`
}

type BranchOtherRevenue struct {
	ID           uuid.UUID       `json:"id"`
	FranchiseeID uuid.UUID       `json:"franchisee_id"`
	Label        string          `json:"label"`
	Amount       decimal.Decimal `json:"amount"`
	RevenueDate  time.Time       `json:"revenue_date"`
	AddedBy      uuid.UUID       `json:"added_by"`
	CreatedAt    time.Time       `json:"created_at"`
}

type RoyaltyPaymentRecord struct {
	ID                  uuid.UUID       `json:"id"`
	FranchiseAgreementID uuid.UUID      `json:"franchise_agreement_id"`
	Period              string          `json:"period"`
	GrossRevenue        decimal.Decimal `json:"gross_revenue"`
	MonthlyRoyalty      decimal.Decimal `json:"monthly_royalty"`
	RevenueRoyalty      decimal.Decimal `json:"revenue_royalty"`
	TotalRoyalty        decimal.Decimal `json:"total_royalty"`
	Status              RoyaltyStatus   `json:"status"`
	PaidAt              *time.Time      `json:"paid_at,omitempty"`
	RecordedBy          uuid.UUID       `json:"recorded_by"`
	CreatedAt           time.Time       `json:"created_at"`
	UpdatedAt           time.Time       `json:"updated_at"`
}
