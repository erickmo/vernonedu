package voucher

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// DiscountType enumerates supported voucher discount modes.
type DiscountType string

const (
	DiscountFixed      DiscountType = "fixed_amount"
	DiscountPercentage DiscountType = "percentage"
	DiscountFinalPrice DiscountType = "fixed_final_price"
)

// Voucher represents a promotional discount code.
type Voucher struct {
	ID            uuid.UUID       `json:"id"`
	Code          string          `json:"code"`
	DiscountType  DiscountType    `json:"discount_type"`
	DiscountValue decimal.Decimal `json:"discount_value"`
	AssignedTo    *uuid.UUID      `json:"assigned_to,omitempty"`
	CourseID      *uuid.UUID      `json:"course_id,omitempty"`
	CourseBatchID *uuid.UUID      `json:"course_batch_id,omitempty"`
	ValidFrom     time.Time       `json:"valid_from"`
	ValidUntil    *time.Time      `json:"valid_until,omitempty"`
	MaxUses       *int            `json:"max_uses,omitempty"`
	UsedCount     int             `json:"used_count"`
	IsActive      bool            `json:"is_active"`
	CreatedBy     uuid.UUID       `json:"created_by"`
	CreatedAt     time.Time       `json:"created_at"`
	UpdatedAt     time.Time       `json:"updated_at"`
}

// VoucherUsage records a single redemption of a voucher against an enrollment.
type VoucherUsage struct {
	ID            uuid.UUID       `json:"id"`
	VoucherID     uuid.UUID       `json:"voucher_id"`
	EnrollmentID  uuid.UUID       `json:"enrollment_id"`
	OriginalPrice decimal.Decimal `json:"original_price"`
	FinalPrice    decimal.Decimal `json:"final_price"`
	UsedAt        time.Time       `json:"used_at"`
	CreatedBy     uuid.UUID       `json:"created_by"`
}

// ListFilter holds optional query filters for listing vouchers.
type ListFilter struct {
	IsActive *bool
	Code     string
}
