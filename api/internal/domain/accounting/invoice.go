package accounting

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

const (
	SourceAuto   = "auto"
	SourceManual = "manual"

	InvoiceStatusDraft     = "draft"
	InvoiceStatusSent      = "sent"
	InvoiceStatusPaid      = "paid"
	InvoiceStatusOverdue   = "overdue"
	InvoiceStatusCancelled = "cancelled"
)

var (
	ErrInvoiceNotFound      = errors.New("invoice not found")
	ErrInvoiceAlreadyPaid   = errors.New("invoice already paid")
	ErrInvoiceAlreadyCancelled = errors.New("invoice already cancelled")
	ErrInvoiceNotSendable   = errors.New("invoice cannot be sent in current state")
)

type Invoice struct {
	ID            uuid.UUID
	InvoiceNumber string
	StudentID     *uuid.UUID
	EnrollmentID  *uuid.UUID
	CourseBatchID *uuid.UUID
	StudentName   string
	BatchName     string
	ClientName    string
	PaymentMethod string
	Amount        float64
	PaidAmount    *float64
	DueDate       *time.Time
	PaidDate      *time.Time
	Status        string // draft, sent, paid, overdue, cancelled
	Notes         string
	Source        string // auto, manual
	PaymentProof  *string
	BranchID      *uuid.UUID
	SessionID     *uuid.UUID
	SentAt        *time.Time
	CancelledAt   *time.Time
	CancelReason  string
	PaidBy        *uuid.UUID
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type NewInvoiceParams struct {
	StudentID     *uuid.UUID
	EnrollmentID  *uuid.UUID
	CourseBatchID *uuid.UUID
	StudentName   string
	BatchName     string
	ClientName    string
	PaymentMethod string
	Amount        float64
	DueDate       *time.Time
	Notes         string
	Source        string
	BranchID      *uuid.UUID
	SessionID     *uuid.UUID
	InvoiceNumber string
}

func NewInvoice(params NewInvoiceParams) (*Invoice, error) {
	if params.Amount <= 0 {
		return nil, errors.New("amount must be greater than zero")
	}
	if params.PaymentMethod == "" {
		return nil, errors.New("payment method is required")
	}
	source := params.Source
	if source == "" {
		source = SourceManual
	}

	now := time.Now()
	return &Invoice{
		ID:            uuid.New(),
		InvoiceNumber: params.InvoiceNumber,
		StudentID:     params.StudentID,
		EnrollmentID:  params.EnrollmentID,
		CourseBatchID: params.CourseBatchID,
		StudentName:   params.StudentName,
		BatchName:     params.BatchName,
		ClientName:    params.ClientName,
		PaymentMethod: params.PaymentMethod,
		Amount:        params.Amount,
		DueDate:       params.DueDate,
		Status:        InvoiceStatusDraft,
		Notes:         params.Notes,
		Source:        source,
		BranchID:      params.BranchID,
		SessionID:     params.SessionID,
		CreatedAt:     now,
		UpdatedAt:     now,
	}, nil
}

// GenerateInvoiceNumber produces a formatted invoice number: INV-YYYY-<seq padded to 4 digits>
func GenerateInvoiceNumber(seq int) string {
	year := time.Now().Year()
	return fmt.Sprintf("INV-%d-%04d", year, seq)
}

// MarkPaid marks the invoice as paid and records payment details.
func (inv *Invoice) MarkPaid(paidAt time.Time, paidAmount float64, paidBy uuid.UUID, paymentProof string) error {
	if inv.Status == InvoiceStatusCancelled {
		return ErrInvoiceAlreadyCancelled
	}
	if inv.Status == InvoiceStatusPaid {
		return ErrInvoiceAlreadyPaid
	}
	now := time.Now()
	inv.Status = InvoiceStatusPaid
	inv.PaidDate = &paidAt
	inv.PaidAmount = &paidAmount
	inv.PaidBy = &paidBy
	if paymentProof != "" {
		inv.PaymentProof = &paymentProof
	}
	inv.UpdatedAt = now
	return nil
}

// Cancel cancels the invoice with a reason.
func (inv *Invoice) Cancel(reason string) error {
	if inv.Status == InvoiceStatusPaid {
		return ErrInvoiceAlreadyPaid
	}
	if inv.Status == InvoiceStatusCancelled {
		return ErrInvoiceAlreadyCancelled
	}
	now := time.Now()
	inv.Status = InvoiceStatusCancelled
	inv.CancelledAt = &now
	inv.CancelReason = reason
	inv.UpdatedAt = now
	return nil
}

// Send marks the invoice as sent.
func (inv *Invoice) Send() error {
	if inv.Status == InvoiceStatusCancelled {
		return ErrInvoiceAlreadyCancelled
	}
	if inv.Status == InvoiceStatusPaid {
		return ErrInvoiceAlreadyPaid
	}
	now := time.Now()
	inv.Status = InvoiceStatusSent
	inv.SentAt = &now
	inv.UpdatedAt = now
	return nil
}

// Domain events

type InvoiceCreatedEvent struct {
	InvoiceID     uuid.UUID `json:"invoice_id"`
	InvoiceNumber string    `json:"invoice_number"`
	StudentID     *uuid.UUID `json:"student_id,omitempty"`
	EnrollmentID  *uuid.UUID `json:"enrollment_id,omitempty"`
	CourseBatchID *uuid.UUID `json:"course_batch_id,omitempty"`
	Amount        float64   `json:"amount"`
	Source        string    `json:"source"`
	Timestamp     int64     `json:"timestamp"`
}

func (e *InvoiceCreatedEvent) EventName() string      { return "InvoiceCreated" }
func (e *InvoiceCreatedEvent) EventData() interface{} { return e }

type InvoicePaidEvent struct {
	InvoiceID    uuid.UUID `json:"invoice_id"`
	PaidAt       int64     `json:"paid_at"`
	PaidAmount   float64   `json:"paid_amount"`
	PaidBy       uuid.UUID `json:"paid_by"`
	AccountCode  string    `json:"account_code"`
	Timestamp    int64     `json:"timestamp"`
}

func (e *InvoicePaidEvent) EventName() string      { return "InvoicePaid" }
func (e *InvoicePaidEvent) EventData() interface{} { return e }

type InvoiceCancelledEvent struct {
	InvoiceID uuid.UUID `json:"invoice_id"`
	Reason    string    `json:"reason"`
	Timestamp int64     `json:"timestamp"`
}

func (e *InvoiceCancelledEvent) EventName() string      { return "InvoiceCancelled" }
func (e *InvoiceCancelledEvent) EventData() interface{} { return e }

type InvoiceSentEvent struct {
	InvoiceID uuid.UUID `json:"invoice_id"`
	Timestamp int64     `json:"timestamp"`
}

func (e *InvoiceSentEvent) EventName() string      { return "InvoiceSent" }
func (e *InvoiceSentEvent) EventData() interface{} { return e }

type InvoiceOverdueEvent struct {
	InvoiceID    uuid.UUID  `json:"invoice_id"`
	EnrollmentID *uuid.UUID `json:"enrollment_id"`
	StudentID    *uuid.UUID `json:"student_id"`
	BatchID      *uuid.UUID `json:"batch_id"`
	Timestamp    int64      `json:"timestamp"`
}

func (e *InvoiceOverdueEvent) EventName() string      { return "InvoiceOverdue" }
func (e *InvoiceOverdueEvent) EventData() interface{} { return e }

// Repository interfaces

type InvoiceFilters struct {
	Offset        int
	Limit         int
	Status        string
	BatchID       *uuid.UUID
	StudentID     *uuid.UUID
	PaymentMethod string
	DateFrom      *time.Time
	DateTo        *time.Time
	Month         int
	Year          int
}

type InvoiceStats struct {
	TotalCount          int     `json:"total_count"`
	TotalAmount         float64 `json:"total_amount"`
	PaidCount           int     `json:"paid_count"`
	PaidAmount          float64 `json:"paid_amount"`
	OutstandingCount    int     `json:"outstanding_count"`
	OutstandingAmount   float64 `json:"outstanding_amount"`
	OverdueCount        int     `json:"overdue_count"`
	OverdueAmount       float64 `json:"overdue_amount"`
}

type InvoiceWriteRepository interface {
	UpdateStatus(ctx context.Context, id uuid.UUID, status string) error
	Save(ctx context.Context, inv *Invoice) error
	MarkPaid(ctx context.Context, id uuid.UUID, paidAt time.Time, paidAmount float64, paidBy uuid.UUID, proof string) error
	Cancel(ctx context.Context, id uuid.UUID, reason string) error
	MarkSent(ctx context.Context, id uuid.UUID) error
	MarkOverdue(ctx context.Context, ids []uuid.UUID) error
}

type InvoiceReadRepository interface {
	List(ctx context.Context, offset, limit, month, year int, status string) ([]*Invoice, int, error)
	GetByID(ctx context.Context, id uuid.UUID) (*Invoice, error)
	ListEnriched(ctx context.Context, filters InvoiceFilters) ([]*Invoice, int, error)
	GetStats(ctx context.Context, branchID *uuid.UUID) (*InvoiceStats, error)
	FindOverdueUnpaid(ctx context.Context, asOf time.Time) ([]*Invoice, error)
}
