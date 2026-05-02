package delete_transaction

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type fakeRepo struct {
	softDeletedID uuid.UUID
	called        bool
}

func (f *fakeRepo) Create(ctx context.Context, t *accounting.Transaction) error { return nil }
func (f *fakeRepo) Update(ctx context.Context, u *accounting.TransactionUpdate) error {
	return nil
}
func (f *fakeRepo) SoftDelete(ctx context.Context, id uuid.UUID) error {
	f.softDeletedID = id
	f.called = true
	return nil
}

func TestHandle_SoftDeletesTransaction(t *testing.T) {
	repo := &fakeRepo{}
	h := NewHandler(repo)
	id := uuid.New()
	if err := h.Handle(context.Background(), &DeleteTransactionCommand{ID: id}); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.called || repo.softDeletedID != id {
		t.Fatalf("expected soft delete with id=%v, got called=%v id=%v", id, repo.called, repo.softDeletedID)
	}
}

func TestHandle_InvalidCommand(t *testing.T) {
	if err := NewHandler(&fakeRepo{}).Handle(context.Background(), struct{}{}); err != ErrInvalidCommand {
		t.Fatalf("expected ErrInvalidCommand, got %v", err)
	}
}
