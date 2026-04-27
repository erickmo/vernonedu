package enrollment

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type EnrollmentFormat string

const (
	FormatRegular         EnrollmentFormat = "regular"
	FormatPrivate         EnrollmentFormat = "private"
	FormatInhouseTraining EnrollmentFormat = "inhouse_training"
	FormatInschoolProgram EnrollmentFormat = "inschool_program"
)

type EnrollmentMode string

const (
	ModeOnline  EnrollmentMode = "online"
	ModeOffline EnrollmentMode = "offline"
)

type PaymentStatus string

const (
	PaymentPending  PaymentStatus = "pending"
	PaymentPartial  PaymentStatus = "partial"
	PaymentPaid     PaymentStatus = "paid"
	PaymentOverdue  PaymentStatus = "overdue"
)

type CompletionStatus string

const (
	CompletionOngoing   CompletionStatus = "ongoing"
	CompletionCompleted CompletionStatus = "completed"
	CompletionDropped   CompletionStatus = "dropped"
)

type Payer string

const (
	PayerPartner Payer = "partner"
	PayerStudent Payer = "student"
)

type DiscountType string

const (
	DiscountFixed      DiscountType = "fixed_amount"
	DiscountPercentage DiscountType = "percentage"
	DiscountFinalPrice DiscountType = "fixed_final_price"
)

type Enrollment struct {
	ID               uuid.UUID        `json:"id"`
	StudentID        uuid.UUID        `json:"student_id"`
	CourseBatchID    uuid.UUID        `json:"course_batch_id"`
	Format           EnrollmentFormat `json:"format"`
	Mode             EnrollmentMode   `json:"mode"`
	Payer            string           `json:"payer"`
	PartnerID        *uuid.UUID       `json:"partner_id,omitempty"`
	FranchiseeID     *uuid.UUID       `json:"franchisee_id,omitempty"`
	Price            decimal.Decimal  `json:"price"`
	FinalPrice       decimal.Decimal  `json:"final_price"`
	VoucherID        *uuid.UUID       `json:"voucher_id,omitempty"`
	CreditApplied    decimal.Decimal  `json:"credit_applied"`
	StudentCreditID  *uuid.UUID       `json:"student_credit_id,omitempty"`
	PaymentStatus    PaymentStatus    `json:"payment_status"`
	CompletionStatus CompletionStatus `json:"completion_status"`
	Source           string           `json:"source"`
	CreatedAt        time.Time        `json:"created_at"`
	UpdatedAt        time.Time        `json:"updated_at"`
}

type Voucher struct {
	ID             uuid.UUID        `json:"id"`
	Code           string           `json:"code"`
	DiscountType   DiscountType     `json:"discount_type"`
	DiscountValue  decimal.Decimal  `json:"discount_value"`
	AssignedTo     *uuid.UUID       `json:"assigned_to,omitempty"`
	CourseID       *uuid.UUID       `json:"course_id,omitempty"`
	CourseBatchID  *uuid.UUID       `json:"course_batch_id,omitempty"`
	ValidFrom      time.Time        `json:"valid_from"`
	ValidUntil     *time.Time       `json:"valid_until,omitempty"`
	MaxUses        *int             `json:"max_uses,omitempty"`
	UsedCount      int              `json:"used_count"`
	IsActive       bool             `json:"is_active"`
	CreatedBy      uuid.UUID        `json:"created_by"`
	CreatedAt      time.Time        `json:"created_at"`
	UpdatedAt      time.Time        `json:"updated_at"`
}

type VoucherUsage struct {
	ID            uuid.UUID       `json:"id"`
	VoucherID     uuid.UUID       `json:"voucher_id"`
	EnrollmentID  uuid.UUID       `json:"enrollment_id"`
	OriginalPrice decimal.Decimal `json:"original_price"`
	FinalPrice    decimal.Decimal `json:"final_price"`
	UsedAt        time.Time       `json:"used_at"`
	CreatedBy     uuid.UUID       `json:"created_by"`
}
