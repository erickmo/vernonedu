package finance

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type PaymentType string

const (
	PaymentFull        PaymentType = "full"
	PaymentInstallment PaymentType = "installment"
)

type PaymentStatus string

const (
	PaymentPending  PaymentStatus = "pending"
	PaymentPartial  PaymentStatus = "partial"
	PaymentPaid     PaymentStatus = "paid"
	PaymentOverdue  PaymentStatus = "overdue"
)

type TermStatus string

const (
	TermUnpaid  TermStatus = "unpaid"
	TermPaid    TermStatus = "paid"
	TermOverdue TermStatus = "overdue"
)

type TransactionMethod string

const (
	MethodGateway      TransactionMethod = "gateway"
	MethodBankTransfer TransactionMethod = "bank_transfer"
)

type TransactionStatus string

const (
	TxPending   TransactionStatus = "pending"
	TxConfirmed TransactionStatus = "confirmed"
	TxFailed    TransactionStatus = "failed"
	TxCancelled TransactionStatus = "cancelled"
)

type InvoiceStatus string

const (
	InvoiceDraft     InvoiceStatus = "draft"
	InvoiceSent      InvoiceStatus = "sent"
	InvoicePaid      InvoiceStatus = "paid"
	InvoiceOverdue   InvoiceStatus = "overdue"
	InvoiceCancelled InvoiceStatus = "cancelled"
)

type Payment struct {
	ID           uuid.UUID       `json:"id"`
	EnrollmentID uuid.UUID       `json:"enrollment_id"`
	PaymentType  PaymentType     `json:"payment_type"`
	TotalAmount  decimal.Decimal `json:"total_amount"`
	PaidAmount   decimal.Decimal `json:"paid_amount"`
	Status       PaymentStatus   `json:"status"`
	CreatedAt    time.Time       `json:"created_at"`
	UpdatedAt    time.Time       `json:"updated_at"`
}

type PaymentTerm struct {
	ID         uuid.UUID       `json:"id"`
	PaymentID  uuid.UUID       `json:"payment_id"`
	TermNumber int             `json:"term_number"`
	DueDate    time.Time       `json:"due_date"`
	Amount     decimal.Decimal `json:"amount"`
	Status     TermStatus      `json:"status"`
	CreatedAt  time.Time       `json:"created_at"`
	UpdatedAt  time.Time       `json:"updated_at"`
}

type PaymentTransaction struct {
	ID             uuid.UUID         `json:"id"`
	PaymentTermID  uuid.UUID         `json:"payment_term_id"`
	Method         TransactionMethod `json:"method"`
	Amount         decimal.Decimal   `json:"amount"`
	Status         TransactionStatus `json:"status"`
	GatewayRef     *string           `json:"gateway_ref,omitempty"`
	ProofURL       *string           `json:"proof_url,omitempty"`
	ConfirmedBy    *uuid.UUID        `json:"confirmed_by,omitempty"`
	ConfirmedAt    *time.Time        `json:"confirmed_at,omitempty"`
	CreatedAt      time.Time         `json:"created_at"`
	UpdatedAt      time.Time         `json:"updated_at"`
}

type Invoice struct {
	ID             uuid.UUID     `json:"id"`
	InvoiceNumber  string        `json:"invoice_number"`
	EnrollmentID   uuid.UUID     `json:"enrollment_id"`
	PaymentID      uuid.UUID     `json:"payment_id"`
	BilledTo       string        `json:"billed_to"`
	PartnerID      *uuid.UUID    `json:"partner_id,omitempty"`
	StudentID      *uuid.UUID    `json:"student_id,omitempty"`
	Status         InvoiceStatus `json:"status"`
	IssuedDate     time.Time     `json:"issued_date"`
	DueDate        *time.Time    `json:"due_date,omitempty"`
	Subtotal       decimal.Decimal `json:"subtotal"`
	DiscountAmount decimal.Decimal `json:"discount_amount"`
	TotalAmount    decimal.Decimal `json:"total_amount"`
	Notes          *string       `json:"notes,omitempty"`
	CreatedBy      uuid.UUID     `json:"created_by"`
	PaymentProvider *string      `json:"payment_provider,omitempty"`
	ProviderRef    *string       `json:"provider_ref,omitempty"`
	PaidAt         *time.Time    `json:"paid_at,omitempty"`
	CreatedAt      time.Time     `json:"created_at"`
	UpdatedAt      time.Time     `json:"updated_at"`
}

type InvoiceLineItem struct {
	ID        uuid.UUID       `json:"id"`
	InvoiceID uuid.UUID       `json:"invoice_id"`
	Label     string          `json:"label"`
	Amount    decimal.Decimal `json:"amount"`
	SortOrder int             `json:"sort_order"`
	CreatedAt time.Time       `json:"created_at"`
}

type BudgetTemplateItem struct {
	ID            uuid.UUID       `json:"id"`
	CourseID      uuid.UUID       `json:"course_id"`
	Label         string          `json:"label"`
	Category      *string         `json:"category,omitempty"`
	PresetAmount  decimal.Decimal `json:"preset_amount"`
	Overridable   bool            `json:"overridable"`
	CreatedAt     time.Time       `json:"created_at"`
	UpdatedAt     time.Time       `json:"updated_at"`
}

type BatchBudgetItem struct {
	ID             uuid.UUID       `json:"id"`
	CourseBatchID  uuid.UUID       `json:"course_batch_id"`
	TemplateRefID  *uuid.UUID      `json:"template_ref_id,omitempty"`
	Label          string          `json:"label"`
	Category       *string         `json:"category,omitempty"`
	PlannedAmount  decimal.Decimal `json:"planned_amount"`
	Overridable    bool            `json:"overridable"`
	ClassID        *uuid.UUID      `json:"class_id,omitempty"`
	CreatedBy      uuid.UUID       `json:"created_by"`
	CreatedAt      time.Time       `json:"created_at"`
	UpdatedAt      time.Time       `json:"updated_at"`
}

type BudgetRealization struct {
	ID                uuid.UUID       `json:"id"`
	BatchBudgetItemID uuid.UUID       `json:"batch_budget_item_id"`
	ClassID           *uuid.UUID      `json:"class_id,omitempty"`
	ActualAmount      decimal.Decimal `json:"actual_amount"`
	Description       string          `json:"description"`
	SpentAt           time.Time       `json:"spent_at"`
	ProofURL          *string         `json:"proof_url,omitempty"`
	RecordedBy        uuid.UUID       `json:"recorded_by"`
	CreatedAt         time.Time       `json:"created_at"`
	UpdatedAt         time.Time       `json:"updated_at"`
}
