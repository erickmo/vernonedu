package get_invoice

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

var ErrInvalidQuery = errors.New("invalid get invoice query type")

type InvoiceDetailReadModel struct {
	ID            uuid.UUID  `json:"id"`
	InvoiceNumber string     `json:"invoice_number"`
	StudentID     *uuid.UUID `json:"student_id,omitempty"`
	EnrollmentID  *uuid.UUID `json:"enrollment_id,omitempty"`
	CourseBatchID *uuid.UUID `json:"course_batch_id,omitempty"`
	StudentName   string     `json:"student_name"`
	BatchName     string     `json:"batch_name"`
	ClientName    string     `json:"client_name"`
	PaymentMethod string     `json:"payment_method"`
	Amount        float64    `json:"amount"`
	PaidAmount    *float64   `json:"paid_amount,omitempty"`
	DueDate       string     `json:"due_date"`
	PaidDate      string     `json:"paid_date,omitempty"`
	Status        string     `json:"status"`
	Notes         string     `json:"notes"`
	Source        string     `json:"source"`
	PaymentProof  *string    `json:"payment_proof,omitempty"`
	BranchID      *uuid.UUID `json:"branch_id,omitempty"`
	SessionID     *uuid.UUID `json:"session_id,omitempty"`
	SentAt        string     `json:"sent_at,omitempty"`
	CancelledAt   string     `json:"cancelled_at,omitempty"`
	CancelReason  string     `json:"cancel_reason,omitempty"`
	PaidBy        *uuid.UUID `json:"paid_by,omitempty"`
	CreatedAt     string     `json:"created_at"`
	UpdatedAt     string     `json:"updated_at"`
}

type Handler struct {
	readRepo accounting.InvoiceReadRepository
}

func NewHandler(readRepo accounting.InvoiceReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*GetInvoiceQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	inv, err := h.readRepo.GetByID(ctx, q.InvoiceID)
	if err != nil {
		log.Error().Err(err).Str("invoice_id", q.InvoiceID.String()).Msg("failed to get invoice")
		return nil, err
	}

	rm := toReadModel(inv)
	return rm, nil
}

func toReadModel(inv *accounting.Invoice) *InvoiceDetailReadModel {
	rm := &InvoiceDetailReadModel{
		ID:            inv.ID,
		InvoiceNumber: inv.InvoiceNumber,
		StudentID:     inv.StudentID,
		EnrollmentID:  inv.EnrollmentID,
		CourseBatchID: inv.CourseBatchID,
		StudentName:   inv.StudentName,
		BatchName:     inv.BatchName,
		ClientName:    inv.ClientName,
		PaymentMethod: inv.PaymentMethod,
		Amount:        inv.Amount,
		PaidAmount:    inv.PaidAmount,
		Status:        inv.Status,
		Notes:         inv.Notes,
		Source:        inv.Source,
		PaymentProof:  inv.PaymentProof,
		BranchID:      inv.BranchID,
		SessionID:     inv.SessionID,
		CancelReason:  inv.CancelReason,
		PaidBy:        inv.PaidBy,
		CreatedAt:     inv.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		UpdatedAt:     inv.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}
	if inv.DueDate != nil {
		rm.DueDate = inv.DueDate.Format("2006-01-02")
	}
	if inv.PaidDate != nil {
		rm.PaidDate = inv.PaidDate.Format("2006-01-02T15:04:05Z07:00")
	}
	if inv.SentAt != nil {
		rm.SentAt = inv.SentAt.Format("2006-01-02T15:04:05Z07:00")
	}
	if inv.CancelledAt != nil {
		rm.CancelledAt = inv.CancelledAt.Format("2006-01-02T15:04:05Z07:00")
	}
	return rm
}
