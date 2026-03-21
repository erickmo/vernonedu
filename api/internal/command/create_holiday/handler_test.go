package create_holiday_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/vernonedu/entrepreneurship-api/internal/command/create_holiday"
	"github.com/vernonedu/entrepreneurship-api/internal/domain/settings"
)

type mockHolidayWriteRepo struct {
	capturedHoliday *settings.Holiday
	returnErr       error
}

func (m *mockHolidayWriteRepo) Save(_ context.Context, h *settings.Holiday) error {
	m.capturedHoliday = h
	return m.returnErr
}

func (m *mockHolidayWriteRepo) Delete(_ context.Context, _ uuid.UUID) error {
	return nil
}

func TestHandler_Handle_Success(t *testing.T) {
	repo := &mockHolidayWriteRepo{}
	h := create_holiday.NewHandler(repo)

	cmd := &create_holiday.CreateHolidayCommand{Date: "2026-08-17", Name: "Hari Kemerdekaan"}
	if err := h.Handle(context.Background(), cmd); err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if repo.capturedHoliday == nil {
		t.Fatal("expected holiday to be saved")
	}
	if repo.capturedHoliday.Name != "Hari Kemerdekaan" {
		t.Errorf("unexpected name: %q", repo.capturedHoliday.Name)
	}
	if repo.capturedHoliday.Date.Month() != 8 || repo.capturedHoliday.Date.Day() != 17 {
		t.Errorf("unexpected date: %v", repo.capturedHoliday.Date)
	}
}

func TestHandler_Handle_InvalidDate(t *testing.T) {
	repo := &mockHolidayWriteRepo{}
	h := create_holiday.NewHandler(repo)

	cmd := &create_holiday.CreateHolidayCommand{Date: "not-a-date", Name: "Test"}
	err := h.Handle(context.Background(), cmd)
	if !errors.Is(err, create_holiday.ErrInvalidDate) {
		t.Errorf("expected ErrInvalidDate, got %v", err)
	}
}

func TestHandler_Handle_InvalidCommand(t *testing.T) {
	repo := &mockHolidayWriteRepo{}
	h := create_holiday.NewHandler(repo)

	err := h.Handle(context.Background(), nil)
	if !errors.Is(err, create_holiday.ErrInvalidCommand) {
		t.Errorf("expected ErrInvalidCommand, got %v", err)
	}
}
