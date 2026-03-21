package list_invoices

import (
	"context"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type InvoiceReadModel struct {
	ID            uuid.UUID  `json:"id"`
	InvoiceNumber string     `json:"invoice_number"`
	StudentName   string     `json:"student_name"`
	ClientName    string     `json:"client_name"`
	BatchName     string     `json:"batch_name"`
	PaymentMethod string     `json:"payment_method"`
	Amount        float64    `json:"amount"`
	PaidAmount    *float64   `json:"paid_amount,omitempty"`
	DueDate       string     `json:"due_date"`
	Status        string     `json:"status"`
	Source        string     `json:"source"`
	CreatedAt     string     `json:"created_at"`
}

type ListResult struct {
	Data   []*InvoiceReadModel `json:"data"`
	Total  int                 `json:"total"`
	Offset int                 `json:"offset"`
	Limit  int                 `json:"limit"`
}

type Handler struct {
	readRepo accounting.InvoiceReadRepository
}

func NewHandler(readRepo accounting.InvoiceReadRepository) *Handler {
	return &Handler{readRepo: readRepo}
}

func (h *Handler) Handle(ctx context.Context, query interface{}) (interface{}, error) {
	q, ok := query.(*ListInvoicesQuery)
	if !ok {
		return nil, ErrInvalidQuery
	}

	filters := accounting.InvoiceFilters{
		Offset:        q.Offset,
		Limit:         q.Limit,
		Status:        q.Status,
		BatchID:       q.BatchID,
		StudentID:     q.StudentID,
		PaymentMethod: q.PaymentMethod,
		DateFrom:      q.DateFrom,
		DateTo:        q.DateTo,
		Month:         q.Month,
		Year:          q.Year,
	}
	if filters.Limit == 0 {
		filters.Limit = 20
	}

	invoices, total, err := h.readRepo.ListEnriched(ctx, filters)
	if err != nil {
		log.Error().Err(err).Msg("failed to list invoices")
		return nil, err
	}

	readModels := make([]*InvoiceReadModel, len(invoices))
	for i, inv := range invoices {
		dueDate := ""
		if inv.DueDate != nil {
			dueDate = inv.DueDate.Format("2006-01-02")
		}
		readModels[i] = &InvoiceReadModel{
			ID:            inv.ID,
			InvoiceNumber: inv.InvoiceNumber,
			StudentName:   inv.StudentName,
			ClientName:    inv.ClientName,
			BatchName:     inv.BatchName,
			PaymentMethod: inv.PaymentMethod,
			Amount:        inv.Amount,
			PaidAmount:    inv.PaidAmount,
			DueDate:       dueDate,
			Status:        inv.Status,
			Source:        inv.Source,
			CreatedAt:     inv.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		}
	}

	return &ListResult{
		Data:   readModels,
		Total:  total,
		Offset: q.Offset,
		Limit:  q.Limit,
	}, nil
}
