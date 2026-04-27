package profit_split

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// ApprovalStatus represents the approval state of extra revenue.
type ApprovalStatus string

const (
	ApprovalPending  ApprovalStatus = "pending"
	ApprovalApproved ApprovalStatus = "approved"
	ApprovalRejected ApprovalStatus = "rejected"
)

// CostType represents how a cost is calculated.
type CostType string

const (
	CostFixed             CostType = "fixed"
	CostPercentageRevenue CostType = "percentage_of_revenue"
)

// CostRefType is the origin classification of a cost item.
type CostRefType string

const (
	RefManual        CostRefType = "manual"
	RefFacilitatorFee CostRefType = "facilitator_fee"
	RefPartnerSplit  CostRefType = "partner_split"
	RefTemplate      CostRefType = "template"
	RefOther         CostRefType = "other"
)

// PeriodType identifies the aggregation window for bonuses.
type PeriodType string

const PeriodMonthly PeriodType = "monthly"

// PeriodBonusStatus tracks finalization of a period bonus.
type PeriodBonusStatus string

const (
	BonusDraft     PeriodBonusStatus = "draft"
	BonusFinalized PeriodBonusStatus = "finalized"
)

// GlobalSettings is the singleton row defining default split percentages.
type GlobalSettings struct {
	ID               uuid.UUID       `json:"id"`
	VernonEduPct     decimal.Decimal `json:"vernonedu_pct"`
	CourseCreatorPct decimal.Decimal `json:"course_creator_pct"`
	DeptLeaderPct    decimal.Decimal `json:"dept_leader_pct"`
	UpdatedBy        uuid.UUID       `json:"updated_by"`
	UpdatedAt        time.Time       `json:"updated_at"`
}

// CourseOverride is a CEO-defined per-course split override.
type CourseOverride struct {
	ID               uuid.UUID       `json:"id"`
	CourseID         uuid.UUID       `json:"course_id"`
	VernonEduPct     decimal.Decimal `json:"vernonedu_pct"`
	CourseCreatorPct decimal.Decimal `json:"course_creator_pct"`
	DeptLeaderPct    decimal.Decimal `json:"dept_leader_pct"`
	OverriddenBy     uuid.UUID       `json:"overridden_by"`
	OverriddenAt     time.Time       `json:"overridden_at"`
	CreatedAt        time.Time       `json:"created_at"`
	UpdatedAt        time.Time       `json:"updated_at"`
}

// ExtraRevenue is additional revenue added by finance and approved by CEO.
type ExtraRevenue struct {
	ID             uuid.UUID      `json:"id"`
	CourseBatchID  uuid.UUID      `json:"course_batch_id"`
	Label          string         `json:"label"`
	Amount         decimal.Decimal `json:"amount"`
	AddedBy        uuid.UUID      `json:"added_by"`
	ApprovalStatus ApprovalStatus `json:"approval_status"`
	ApprovedBy     *uuid.UUID     `json:"approved_by,omitempty"`
	ApprovedAt     *time.Time     `json:"approved_at,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
}

// BatchCostLineItem is a cost entry for a course batch.
type BatchCostLineItem struct {
	ID             uuid.UUID       `json:"id"`
	CourseBatchID  uuid.UUID       `json:"course_batch_id"`
	TemplateRef    *uuid.UUID      `json:"template_ref,omitempty"`
	Label          string          `json:"label"`
	Amount         decimal.Decimal `json:"amount"`
	CostType       CostType        `json:"cost_type"`
	IsRemoved      bool            `json:"is_removed"`
	ReferenceType  CostRefType     `json:"reference_type"`
	ReferenceID    *uuid.UUID      `json:"reference_id,omitempty"`
	CreatedBy      uuid.UUID       `json:"created_by"`
	CreatedAt      time.Time       `json:"created_at"`
	UpdatedAt      time.Time       `json:"updated_at"`
}

// BatchSplitRecord holds the calculated profit split for a closed batch.
type BatchSplitRecord struct {
	ID                   uuid.UUID       `json:"id"`
	CourseBatchID        uuid.UUID       `json:"course_batch_id"`
	GrossRevenue         decimal.Decimal `json:"gross_revenue"`
	TotalCosts           decimal.Decimal `json:"total_costs"`
	NetProfit            decimal.Decimal `json:"net_profit"`
	VernonEduPct         decimal.Decimal `json:"vernonedu_pct"`
	CourseCreatorPct     decimal.Decimal `json:"course_creator_pct"`
	DeptLeaderPct        decimal.Decimal `json:"dept_leader_pct"`
	VernonEduAmount      decimal.Decimal `json:"vernonedu_amount"`
	CourseCreatorAmount  decimal.Decimal `json:"course_creator_amount"`
	DeptLeaderAmount     decimal.Decimal `json:"dept_leader_amount"`
	CalculatedAt         time.Time       `json:"calculated_at"`
	CalculatedBy         *uuid.UUID      `json:"calculated_by,omitempty"`
}

// PeriodBonus is a monthly aggregation of split amounts.
type PeriodBonus struct {
	ID                   uuid.UUID         `json:"id"`
	Period               string            `json:"period"`
	PeriodType           PeriodType        `json:"period_type"`
	VernonEduAmount      decimal.Decimal   `json:"vernonedu_amount"`
	CourseCreatorAmount  decimal.Decimal   `json:"course_creator_amount"`
	DeptLeaderAmount     decimal.Decimal   `json:"dept_leader_amount"`
	BatchRefs            []uuid.UUID       `json:"batch_refs"`
	CalculatedAt         time.Time         `json:"calculated_at"`
	CalculatedBy         uuid.UUID         `json:"calculated_by"`
	Status               PeriodBonusStatus `json:"status"`
	CreatedAt            time.Time         `json:"created_at"`
	UpdatedAt            time.Time         `json:"updated_at"`
}
