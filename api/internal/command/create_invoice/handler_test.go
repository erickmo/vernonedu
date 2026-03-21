package create_invoice_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/command/create_invoice"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// --- Mocks ---

type mockInvoiceWriteRepo struct {
	saved []*accounting.Invoice
	err   error
}

func (m *mockInvoiceWriteRepo) Save(_ context.Context, inv *accounting.Invoice) error {
	if m.err != nil {
		return m.err
	}
	m.saved = append(m.saved, inv)
	return nil
}

func (m *mockInvoiceWriteRepo) UpdateStatus(_ context.Context, _ uuid.UUID, _ string) error {
	return nil
}

func (m *mockInvoiceWriteRepo) MarkPaid(_ context.Context, _ uuid.UUID, _ time.Time, _ float64, _ uuid.UUID, _ string) error {
	return nil
}

func (m *mockInvoiceWriteRepo) Cancel(_ context.Context, _ uuid.UUID, _ string) error {
	return nil
}

func (m *mockInvoiceWriteRepo) MarkSent(_ context.Context, _ uuid.UUID) error {
	return nil
}

func (m *mockInvoiceWriteRepo) MarkOverdue(_ context.Context, _ []uuid.UUID) error {
	return nil
}

type mockTxWriteRepo struct {
	created []*accounting.Transaction
	err     error
}

func (m *mockTxWriteRepo) Create(_ context.Context, t *accounting.Transaction) error {
	if m.err != nil {
		return m.err
	}
	m.created = append(m.created, t)
	return nil
}

// --- Tests ---

func TestCreateInvoiceHandler_SuccessfulCreation(t *testing.T) {
	invoiceRepo := &mockInvoiceWriteRepo{}
	txRepo := &mockTxWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()

	handler := create_invoice.NewHandler(invoiceRepo, txRepo, bus)

	batchID := uuid.New()
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	cmd := &create_invoice.CreateInvoiceCommand{
		BatchID:       batchID,
		BatchName:     "Test Batch",
		StudentName:   "John Doe",
		Amount:        500000,
		DueDate:       dueDate,
		PaymentMethod: "upfront",
		Notes:         "Test note",
		CreatedBy:     uuid.New(),
	}

	err := handler.Handle(context.Background(), cmd)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(invoiceRepo.saved) != 1 {
		t.Fatalf("expected 1 saved invoice, got %d", len(invoiceRepo.saved))
	}

	saved := invoiceRepo.saved[0]
	if saved.Amount != 500000 {
		t.Errorf("expected amount 500000, got %f", saved.Amount)
	}
	if saved.Status != accounting.InvoiceStatusDraft {
		t.Errorf("expected status draft, got %s", saved.Status)
	}
	if saved.CourseBatchID == nil || *saved.CourseBatchID != batchID {
		t.Errorf("expected batch ID %s", batchID)
	}
}

func TestCreateInvoiceHandler_InvalidCommandType(t *testing.T) {
	handler := create_invoice.NewHandler(&mockInvoiceWriteRepo{}, &mockTxWriteRepo{}, eventbus.NewInMemoryEventBus())

	type wrongCmd struct{}
	err := handler.Handle(context.Background(), &wrongCmd{})
	if err == nil {
		t.Fatal("expected error for invalid command type, got nil")
	}
	if !errors.Is(err, create_invoice.ErrInvalidCommand) {
		t.Errorf("expected ErrInvalidCommand, got %v", err)
	}
}

func TestCreateInvoiceHandler_RepoError(t *testing.T) {
	repoErr := errors.New("db error")
	invoiceRepo := &mockInvoiceWriteRepo{err: repoErr}
	txRepo := &mockTxWriteRepo{}
	bus := eventbus.NewInMemoryEventBus()
	handler := create_invoice.NewHandler(invoiceRepo, txRepo, bus)

	batchID := uuid.New()
	dueDate := time.Now().Add(7 * 24 * time.Hour)
	cmd := &create_invoice.CreateInvoiceCommand{
		BatchID:       batchID,
		Amount:        100000,
		DueDate:       dueDate,
		PaymentMethod: "upfront",
		CreatedBy:     uuid.New(),
	}

	err := handler.Handle(context.Background(), cmd)
	if err == nil {
		t.Fatal("expected error from repo, got nil")
	}
}
