package delete_holiday_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/command/delete_holiday"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

type mockHolidayWriteRepo struct {
	deletedID uuid.UUID
	returnErr error
}

func (m *mockHolidayWriteRepo) Save(_ context.Context, _ *settings.Holiday) error { return nil }
func (m *mockHolidayWriteRepo) Delete(_ context.Context, id uuid.UUID) error {
	m.deletedID = id
	return m.returnErr
}

func TestHandler_Handle_Success(t *testing.T) {
	repo := &mockHolidayWriteRepo{}
	h := delete_holiday.NewHandler(repo)

	id := uuid.New()
	cmd := &delete_holiday.DeleteHolidayCommand{ID: id}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if repo.deletedID != id {
		t.Errorf("expected deleted id %v, got %v", id, repo.deletedID)
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockHolidayWriteRepo{}
	h := delete_holiday.NewHandler(repo)

	err := h.Handle(context.Background(), nil)
	if !errors.Is(err, delete_holiday.ErrInvalidCommand) {
		t.Errorf("expected ErrInvalidCommand, got %v", err)
	}
}
