package delete_bank_account

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type fakeRepo struct {
	gotID     uuid.UUID
	gotActive bool
	called    bool
}

func (f *fakeRepo) Create(ctx context.Context, b *accounting.BankAccount) error { return nil }
func (f *fakeRepo) Update(ctx context.Context, b *accounting.BankAccount) error { return nil }
func (f *fakeRepo) SetActive(ctx context.Context, id uuid.UUID, a bool) error {
	f.gotID = id
	f.gotActive = a
	f.called = true
	return nil
}

func TestHandle_Deactivates(t *testing.T) {
	repo := &fakeRepo{}
	h := NewHandler(repo)
	id := uuid.New()
	if err := h.Handle(context.Background(), &DeleteBankAccountCommand{ID: id}); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !repo.called {
		t.Fatal("repo should be called")
	}
	if repo.gotID != id {
		t.Fatalf("got id %v want %v", repo.gotID, id)
	}
	if repo.gotActive {
		t.Fatal("expected SetActive(false)")
	}
}

func TestHandle_InvalidCommand(t *testing.T) {
	h := NewHandler(&fakeRepo{})
	type bogus struct{}
	if err := h.Handle(context.Background(), &bogus{}); err != ErrInvalidCommand {
		t.Fatalf("expected ErrInvalidCommand, got %v", err)
	}
}
