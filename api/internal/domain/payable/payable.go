package payable

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrPayableNotFound = errors.New("payable not found")
	ErrInvalidType     = errors.New("invalid payable type")
)

const (
	TypeFacilitator             = "facilitator"
	TypeCommissionOpLeader      = "commission_op_leader"
	TypeCommissionDeptLeader    = "commission_dept_leader"
	TypeCommissionCourseCreator = "commission_course_creator"
	TypeMarketingPartner        = "marketing_partner"
	TypeOther                   = "other"

	StatusPending   = "pending"
	StatusApproved  = "approved"
	StatusPaid      = "paid"
	StatusCancelled = "cancelled"

	SourceAuto   = "auto"
	SourceManual = "manual"

	// Journal account codes
	AccountKas                  = "1101"
	AccountHutangFasilitator    = "2100"
	AccountHutangCourseCreator  = "2201"
	AccountHutangDeptLeader     = "2202"
	AccountHutangOpLeader       = "2203"
	AccountHutangMarketing      = "2204"
	AccountBiayaFasilitator     = "5001"
	AccountKomisiCourseCreator  = "5002"
	AccountKomisiDeptLeader     = "5003"
	AccountKomisiOpLeader       = "5004"
	AccountBiayaMarketing       = "5005"
)

type Payable struct {
	ID                    uuid.UUID
	Type                  string
	RecipientID           uuid.UUID
	RecipientName         string
	BatchID               *uuid.UUID
	Amount                int64
	CalculationBasis      string
	CalculationPercentage float64
	Status                string
	Source                string
	PaidAt                *time.Time
	PaymentProof          string
	BranchID              *uuid.UUID
	Notes                 string
	CreatedAt             time.Time
	UpdatedAt             time.Time
}

func NewPayable(
	payableType string,
	recipientID uuid.UUID,
	recipientName string,
	batchID *uuid.UUID,
	amount int64,
	source string,
	branchID *uuid.UUID,
	notes string,
) (*Payable, error) {
	if recipientName == "" {
		return nil, errors.New("recipient name is required")
	}
	if amount <= 0 {
		return nil, errors.New("amount must be greater than zero")
	}
	validTypes := map[string]bool{
		TypeFacilitator: true, TypeCommissionOpLeader: true,
		TypeCommissionDeptLeader: true, TypeCommissionCourseCreator: true,
		TypeMarketingPartner: true, TypeOther: true,
	}
	if !validTypes[payableType] {
		return nil, ErrInvalidType
	}
	now := time.Now()
	return &Payable{
		ID:            uuid.New(),
		Type:          payableType,
		RecipientID:   recipientID,
		RecipientName: recipientName,
		BatchID:       batchID,
		Amount:        amount,
		Status:        StatusPending,
		Source:        source,
		BranchID:      branchID,
		Notes:         notes,
		CreatedAt:     now,
		UpdatedAt:     now,
	}, nil
}

// HutangAccount returns the hutang (liability) account code for this payable type.
func HutangAccount(payableType string) string {
	switch payableType {
	case TypeFacilitator:
		return AccountHutangFasilitator
	case TypeCommissionCourseCreator:
		return AccountHutangCourseCreator
	case TypeCommissionDeptLeader:
		return AccountHutangDeptLeader
	case TypeCommissionOpLeader:
		return AccountHutangOpLeader
	case TypeMarketingPartner:
		return AccountHutangMarketing
	default:
		return AccountHutangFasilitator
	}
}

// ExpenseAccount returns the expense (debit) account code for this payable type.
func ExpenseAccount(payableType string) string {
	switch payableType {
	case TypeFacilitator:
		return AccountBiayaFasilitator
	case TypeCommissionCourseCreator:
		return AccountKomisiCourseCreator
	case TypeCommissionDeptLeader:
		return AccountKomisiDeptLeader
	case TypeCommissionOpLeader:
		return AccountKomisiOpLeader
	case TypeMarketingPartner:
		return AccountBiayaMarketing
	default:
		return AccountBiayaFasilitator
	}
}

type PayableStats struct {
	TotalPending   int
	TotalApproved  int
	TotalPaid      int
	TotalCancelled int
	AmountPending  int64
	AmountApproved int64
}

type WriteRepository interface {
	Save(ctx context.Context, p *Payable) error
	UpdateStatus(ctx context.Context, id uuid.UUID, status string, paidAt *time.Time, paymentProof string) error
}

type ReadRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*Payable, error)
	List(ctx context.Context, payableType, status, batchID, recipientID, dateFrom, dateTo string, offset, limit int) ([]*Payable, int, error)
	Stats(ctx context.Context) (*PayableStats, error)
}
