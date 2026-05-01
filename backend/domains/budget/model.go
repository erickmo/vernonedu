package budget

import (
	"time"

	"github.com/google/uuid"
)

// CourseBudgetTemplateItem is a preset budget line at course level.
type CourseBudgetTemplateItem struct {
	ID            uuid.UUID  `json:"id"`
	CourseID      uuid.UUID  `json:"course_id"`
	Label         string     `json:"label"`
	Category      *string    `json:"category"`
	PresetAmount  float64    `json:"preset_amount"`
	Overridable   bool       `json:"overridable"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

// BatchBudgetItem is an inherited or custom budget line at batch level.
type BatchBudgetItem struct {
	ID             uuid.UUID  `json:"id"`
	CourseBatchID  uuid.UUID  `json:"course_batch_id"`
	TemplateRefID  *uuid.UUID `json:"template_ref_id"`
	Label          string     `json:"label"`
	Category       *string    `json:"category"`
	PlannedAmount  float64    `json:"planned_amount"`
	Overridable    bool       `json:"overridable"`
	ClassID        *uuid.UUID `json:"class_id"`
	CreatedBy      uuid.UUID  `json:"created_by"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}

// BudgetRealization is actual spend recorded against a batch budget item.
type BudgetRealization struct {
	ID                 uuid.UUID  `json:"id"`
	BatchBudgetItemID  uuid.UUID  `json:"batch_budget_item_id"`
	ClassID            *uuid.UUID `json:"class_id"`
	ActualAmount       float64    `json:"actual_amount"`
	Description        string     `json:"description"`
	SpentAt            time.Time  `json:"spent_at"`
	ProofURL           *string    `json:"proof_url"`
	RecordedBy         uuid.UUID  `json:"recorded_by"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

// BudgetItemSummary aggregates planned vs actual for one batch item.
type BudgetItemSummary struct {
	Item     *BatchBudgetItem `json:"item"`
	Actual   float64          `json:"actual"`
	Variance float64          `json:"variance"`
}

// BatchBudgetSummary aggregates the full picture for a batch.
type BatchBudgetSummary struct {
	Items         []*BudgetItemSummary `json:"items"`
	TotalPlanned  float64              `json:"total_planned"`
	TotalActual   float64              `json:"total_actual"`
	TotalVariance float64              `json:"total_variance"`
}
