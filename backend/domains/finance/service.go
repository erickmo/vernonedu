package finance

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
	"github.com/vernonedu/vernonedu2/backend/internal/events"
	apperrors "github.com/vernonedu/vernonedu2/backend/internal/errors"
	"go.uber.org/zap"
)

// Service holds finance business logic.
type Service struct {
	repo Repository
	bus  events.Bus
	log  *zap.Logger
}

// NewService constructs finance Service.
func NewService(repo Repository, bus events.Bus, log *zap.Logger) *Service {
	return &Service{repo: repo, bus: bus, log: log}
}

// InitiatePayment creates a Payment record for an enrollment.
func (s *Service) InitiatePayment(ctx context.Context, enrollmentID uuid.UUID, total decimal.Decimal, payType PaymentType) (*Payment, error) {
	p := &Payment{
		ID:           uuid.New(),
		EnrollmentID: enrollmentID,
		PaymentType:  payType,
		TotalAmount:  total,
		PaidAmount:   decimal.Zero,
		Status:       PaymentPending,
	}
	if err := s.repo.CreatePayment(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

// AddPaymentTerm creates a payment installment term.
func (s *Service) AddPaymentTerm(ctx context.Context, paymentID uuid.UUID, termNumber int, dueDate time.Time, amount decimal.Decimal) (*PaymentTerm, error) {
	t := &PaymentTerm{
		ID:         uuid.New(),
		PaymentID:  paymentID,
		TermNumber: termNumber,
		DueDate:    dueDate,
		Amount:     amount,
		Status:     TermUnpaid,
	}
	if err := s.repo.CreatePaymentTerm(ctx, t); err != nil {
		return nil, err
	}
	return t, nil
}

// ConfirmTransaction marks a transaction confirmed and updates term/payment status.
func (s *Service) ConfirmTransaction(ctx context.Context, txID uuid.UUID, confirmedBy uuid.UUID) error {
	tx, err := s.repo.GetTransactionByID(ctx, txID)
	if err != nil {
		return err
	}
	if tx.Status == TxConfirmed {
		return apperrors.Validationf("transaction already confirmed")
	}

	if err := s.repo.UpdateTransactionStatus(ctx, txID, TxConfirmed, &confirmedBy); err != nil {
		return err
	}

	term, err := s.repo.GetPaymentTermByID(ctx, tx.PaymentTermID)
	if err != nil {
		return err
	}
	if err := s.repo.UpdateTermStatus(ctx, term.ID, TermPaid); err != nil {
		return err
	}

	payment, err := s.repo.GetPaymentByID(ctx, term.PaymentID)
	if err != nil {
		return err
	}

	newPaid := payment.PaidAmount.Add(tx.Amount)
	newStatus := PaymentPartial
	if newPaid.GreaterThanOrEqual(payment.TotalAmount) {
		newStatus = PaymentPaid
	}

	if err := s.repo.UpdatePaymentStatus(ctx, payment.ID, newStatus, newPaid); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.PaymentConfirmed,
		Payload: PaymentConfirmedPayload{PaymentID: payment.ID, EnrollmentID: payment.EnrollmentID, Amount: tx.Amount},
	})

	return nil
}

// MarkOverdueTerms scans unpaid terms past due date and marks them overdue.
func (s *Service) MarkOverdueTerms(ctx context.Context) error {
	terms, err := s.repo.ListOverdueTerms(ctx, time.Now())
	if err != nil {
		return err
	}

	for _, t := range terms {
		if err := s.repo.UpdateTermStatus(ctx, t.ID, TermOverdue); err != nil {
			s.log.Error("failed to mark term overdue", zap.String("term_id", t.ID.String()), zap.Error(err))
			continue
		}

		_ = s.bus.Publish(ctx, events.Event{
			Type:    events.PaymentTermOverdue,
			Payload: PaymentTermOverduePayload{TermID: t.ID, PaymentID: t.PaymentID, DueDate: t.DueDate},
		})
	}
	return nil
}

// MarkOverdueInvoices scans sent invoices past due date and marks them overdue.
func (s *Service) MarkOverdueInvoices(ctx context.Context) error {
	invoices, err := s.repo.ListOverdueInvoices(ctx, time.Now())
	if err != nil {
		return err
	}

	for _, inv := range invoices {
		if err := s.repo.UpdateInvoiceStatus(ctx, inv.ID, InvoiceOverdue); err != nil {
			s.log.Error("failed to mark invoice overdue", zap.String("invoice_id", inv.ID.String()), zap.Error(err))
			continue
		}

		_ = s.bus.Publish(ctx, events.Event{
			Type:    events.InvoiceOverdue,
			Payload: InvoiceOverduePayload{InvoiceID: inv.ID},
		})
	}
	return nil
}

// CreateInvoice creates an invoice with line items.
func (s *Service) CreateInvoice(ctx context.Context, inv *Invoice, lineItems []InvoiceLineItem) (*Invoice, error) {
	inv.ID = uuid.New()
	inv.InvoiceNumber = fmt.Sprintf("INV-%d-%s", time.Now().Unix(), inv.ID.String()[:8])
	inv.Status = InvoiceDraft

	if err := s.repo.CreateInvoice(ctx, inv); err != nil {
		return nil, err
	}

	for i := range lineItems {
		lineItems[i].ID = uuid.New()
		lineItems[i].InvoiceID = inv.ID
		lineItems[i].SortOrder = i
		if err := s.repo.CreateInvoiceLineItem(ctx, &lineItems[i]); err != nil {
			return nil, err
		}
	}

	return inv, nil
}

// GetPaymentByID fetches payment by ID.
func (s *Service) GetPaymentByID(ctx context.Context, id uuid.UUID) (*Payment, error) {
	return s.repo.GetPaymentByID(ctx, id)
}

// ListPaymentTerms returns all terms for a payment.
func (s *Service) ListPaymentTerms(ctx context.Context, paymentID uuid.UUID) ([]*PaymentTerm, error) {
	return s.repo.ListPaymentTerms(ctx, paymentID)
}

// GetInvoiceByID fetches invoice by ID.
func (s *Service) GetInvoiceByID(ctx context.Context, id uuid.UUID) (*Invoice, error) {
	return s.repo.GetInvoiceByID(ctx, id)
}

// SendInvoice transitions invoice to sent status.
func (s *Service) SendInvoice(ctx context.Context, invoiceID uuid.UUID) error {
	inv, err := s.repo.GetInvoiceByID(ctx, invoiceID)
	if err != nil {
		return err
	}
	if inv.Status != InvoiceDraft {
		return apperrors.Validationf("only draft invoices can be sent")
	}

	if err := s.repo.UpdateInvoiceStatus(ctx, invoiceID, InvoiceSent); err != nil {
		return err
	}

	_ = s.bus.Publish(ctx, events.Event{
		Type:    events.InvoiceSent,
		Payload: InvoiceSentPayload{InvoiceID: invoiceID},
	})
	return nil
}
