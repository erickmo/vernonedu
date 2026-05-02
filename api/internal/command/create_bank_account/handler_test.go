package create_bank_account

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/vernonedu/entrepreneurship-api/internal/domain/accounting"
)

type fakeWriteRepo struct {
	created *accounting.BankAccount
	err     error
}

func (f *fakeWriteRepo) Create(ctx context.Context, b *accounting.BankAccount) error {
	if f.err != nil {
		return f.err
	}
	f.created = b
	return nil
}
func (f *fakeWriteRepo) Update(ctx context.Context, b *accounting.BankAccount) error { return nil }
func (f *fakeWriteRepo) SetActive(ctx context.Context, id uuid.UUID, a bool) error   { return nil }

func TestHandle_Success(t *testing.T) {
	repo := &fakeWriteRepo{}
	h := NewHandler(repo)
	cmd := &CreateBankAccountCommand{
		BranchID:     uuid.New(),
		Name:         "BCA Jakarta",
		BalanceCents: 1500000,
	}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("expected bank account to be persisted")
	}
	if repo.created.Currency != accounting.CurrencyIDR {
		t.Fatalf("expected default IDR currency, got %s", repo.created.Currency)
	}
	if !repo.created.IsActive {
		t.Fatal("expected new bank account to be active")
	}
}

func TestHandle_ValidationError(t *testing.T) {
	repo := &fakeWriteRepo{}
	h := NewHandler(repo)
	// missing branch
	cmd := &CreateBankAccountCommand{Name: "x"}
	err := h.Handle(context.Background(), cmd)
	if err == nil {
		t.Fatal("expected validation error")
	}
	if repo.created != nil {
		t.Fatal("repo should not be called when validation fails")
	}
}

func TestHandle_InvalidCommand(t *testing.T) {
	h := NewHandler(&fakeWriteRepo{})
	type bogus struct{}
	if err := h.Handle(context.Background(), &bogus{}); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("expected ErrInvalidCommand, got %v", err)
	}
}
