package create_payable_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	create_payable "github.com/vernonedu/entrepreneurship-api/internal/command/create_payable"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/payable"
	"github.com/vernonedu/entrepreneurship-api/pkg/eventbus"
)

// ─── Fakes ───────────────────────────────────────────────────────────────────

type fakePayableWriteRepo struct {
	saved   *payable.Payable
	saveErr error
}

func (f *fakePayableWriteRepo) Save(_ context.Context, p *payable.Payable) error {
	f.saved = p
	return f.saveErr
}

func (f *fakePayableWriteRepo) UpdateStatus(_ context.Context, _ uuid.UUID, _ string, _ *time.Time, _ string) error {
	return nil
}

type fakeEventBus struct{ published int }

func (f *fakeEventBus) Publish(_ context.Context, _ eventbus.DomainEvent) error {
	f.published++
	return nil
}
func (f *fakeEventBus) Subscribe(_ context.Context, _ string, _ eventbus.MessageHandler) error {
	return nil
}
func (f *fakeEventBus) Close() error { return nil }

// ─── Tests ────────────────────────────────────────────────────────────────────

func TestCreatePayableHandler_Success(t *testing.T) {
	repo := &fakePayableWriteRepo{}
	bus := &fakeEventBus{}
	h := create_payable.NewHandler(repo, bus)

	cmd := &create_payable.CreatePayableCommand{
		Type:          payable.TypeFacilitator,
		RecipientID:   uuid.New(),
		RecipientName: "Budi Santoso",
		Amount:        500000,
		Notes:         "session fee",
	}

	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if repo.saved == nil {
		t.Fatal("expected payable to be saved")
	}
	if repo.saved.Type != payable.TypeFacilitator {
		t.Errorf("expected type %s, got %s", payable.TypeFacilitator, repo.saved.Type)
	}
	if repo.saved.Amount != 500000 {
		t.Errorf("expected amount 500000, got %d", repo.saved.Amount)
	}
	if repo.saved.Status != payable.StatusPending {
		t.Errorf("expected status pending, got %s", repo.saved.Status)
	}
	if bus.published != 1 {
		t.Errorf("expected 1 event published, got %d", bus.published)
	}
}

func TestCreatePayableHandler_InvalidCommand(t *testing.T) {
	h := create_payable.NewHandler(&fakePayableWriteRepo{}, &fakeEventBus{})
	if err := h.Handle(context.Background(), nil); err == nil {
		t.Fatal("expected error for nil command")
	}
}

func TestCreatePayableHandler_InvalidType(t *testing.T) {
	h := create_payable.NewHandler(&fakePayableWriteRepo{}, &fakeEventBus{})
	cmd := &create_payable.CreatePayableCommand{
		Type:          "invalid_type",
		RecipientID:   uuid.New(),
		RecipientName: "Budi",
		Amount:        100000,
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error for invalid type")
	}
}

func TestCreatePayableHandler_EmptyRecipientName(t *testing.T) {
	h := create_payable.NewHandler(&fakePayableWriteRepo{}, &fakeEventBus{})
	cmd := &create_payable.CreatePayableCommand{
		Type:          payable.TypeFacilitator,
		RecipientID:   uuid.New(),
		RecipientName: "",
		Amount:        100000,
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error for empty recipient name")
	}
}

func TestCreatePayableHandler_RepoError(t *testing.T) {
	repo := &fakePayableWriteRepo{saveErr: errors.New("db error")}
	h := create_payable.NewHandler(repo, &fakeEventBus{})
	cmd := &create_payable.CreatePayableCommand{
		Type:          payable.TypeFacilitator,
		RecipientID:   uuid.New(),
		RecipientName: "Budi",
		Amount:        100000,
	}
	if err := h.Handle(context.Background(), cmd); err == nil {
		t.Fatal("expected error when repo fails")
	}
}

func TestCreatePayableHandler_WithBatchID(t *testing.T) {
	repo := &fakePayableWriteRepo{}
	h := create_payable.NewHandler(repo, &fakeEventBus{})
	batchID := uuid.New()
	cmd := &create_payable.CreatePayableCommand{
		Type:          payable.TypeCommissionOpLeader,
		RecipientID:   uuid.New(),
		RecipientName: "Rina Leader",
		BatchID:       &batchID,
		Amount:        750000,
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if repo.saved.BatchID == nil || *repo.saved.BatchID != batchID {
		t.Error("expected batch ID to be set correctly")
	}
}
